package Koha::Plugin::Fi::KohaSuomi::SelfService::Install;

# Copyright 2019 KohaSuomi
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


use Modern::Perl;

use Class::Inspector;
use Data::Dumper;
use File::Basename;
use File::Find;
use File::Slurp;
use YAML::XS;

use C4::Context;
use Koha::Logger;
use Koha::DateUtils;

use Koha::Libraries;
use Koha::Library;
use Koha::Patron::Attributes;
use Koha::Patron::Attribute::Types;

use Koha::Plugin::Fi::KohaSuomi::SelfService;
use Koha::Plugin::Fi::KohaSuomi::SelfService::OpeningHours;

sub install {
    my ( $self, $args ) = @_;
    my $logger = Koha::Logger->get();

    eval {
        my $dbh = C4::Context->dbh;
        # Create tables
        my $table = $self->get_qualified_table_name('borrower_ss_blocks');

        my $borrower_ss_blocks = $dbh->do(qq{

--
-- Table structure for table `$table`
--

CREATE TABLE IF NOT EXISTS `$table` ( -- borrower self-service branch-specific blocks. Prevent access to specific self-service libraries, but not to all of them
  `borrower_ss_block_id` int(12) NOT NULL auto_increment,
  `borrowernumber` int(11) NOT NULL,    -- The user that is blocked, if the borrower-row is deleted, this block becomes useless as well
  `branchcode` varchar(10) NOT NULL,    -- FK to branches. Where the block is in effect. Referential integrity enforced on software, because cannot delete the branch and preserve the old value ON DELETE/UPDATE.
  `expirationdate` datetime NOT NULL,   -- When the personal branch-specific block is automatically lifted by the cronjob self_service_block_expiration.pl
  `notes` text,                         -- Non-formal user created notes about the block.
  `created_by` int(11) NOT NULL,        -- The librarian that created the block, referential integrity enforced with Perl, because the librarian can quit, but all the blocks he/she made must remain.
  `created_on` datetime NOT NULL DEFAULT NOW(), -- When was this block created
  PRIMARY KEY  (`borrower_ss_block_id`),
  KEY `expirationdate` (`expirationdate`),
  KEY `created_by` (`created_by`),
  FOREIGN KEY (`borrowernumber`) REFERENCES `borrowers` (`borrowernumber`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`branchcode`) REFERENCES `branches` (`branchcode`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        });

        # Create borrower attributes
        my $sstc;
        unless ($sstc = Koha::Patron::Attribute::Types->find({ code => 'SST&C'})) {
            $sstc = Koha::Patron::Attribute::Type->new({
                code => 'SST&C',
                description => 'Self-service terms and conditions accepted',
                opac_display => 1,
                authorised_value_category => 'YES_NO'
            })->store;
        }

        my $ssban;
        unless ($ssban = Koha::Patron::Attribute::Types->find({ code => 'SSBAN'})) {
            $ssban = Koha::Patron::Attribute::Type->new({
                code => 'SSBAN',
                description => 'Self-service usage revoked',
                opac_display => 1,
                authorised_value_category => 'YES_NO'
            })->store;
        }

        # Create permissions
        $dbh->do(q{
            INSERT IGNORE INTO permissions (module_bit, code, description) VALUES
            ( 4,    'get_self_service_status',   'Allow listing all self-service blocks for a Patron.'),
            ( 4,    'ss_blocks_list',            'Allow listing all self-service blocks for a Patron.'),
            ( 4,    'ss_blocks_get',             'Allow fetching the data of a single self-service block for a Patron.'),
            ( 4,    'ss_blocks_create',          'Allow creating a single self-service block for a Patron.'),
            ( 4,    'ss_blocks_edit',            'Allow editing the data of a single self-service block for a Patron.'),
            ( 4,    'ss_blocks_delete',          'Allow deleting a single self-service block for a Patron.');
        });
        my $warnings = $dbh->selectall_arrayref('SHOW WARNINGS');
        $logger->error("Warnings adding permissions to Koha:\n".Data::Dumper::Dumper($warnings)) if ($warnings && ref($warnings) eq 'ARRAY' && scalar(@$warnings) > 0);

        # Create system preferences
        Koha::Caches->get_instance('syspref')->flush_all();
        my $SSRules = <<YAML;
---
TaC: 1
Permission: 1
CardExpired: 1
CardLost: 1
Debarred: 1
MaxFines: 1
OpeningHours: 1
MinimumAge: 0
BorrowerCategories: PT S ST
BranchBlock: 1
YAML

        $SSRules = C4::Context->set_preference('SSRules', $SSRules, 'Self-service access rules, age limit + whitelisted borrower categories', 'Textarea', '70|10')
            unless C4::Context->preference('SSRules');

        my $OpeningHours                = defined C4::Context->preference('OpeningHours') ? 1 :
            C4::Context->set_preference( 'OpeningHours', "---\n\n", 'Define opening hours YAML', 'Textarea', '70|10' );
        my $EncryptionConfiguration     = defined C4::Context->preference('EncryptionConfiguration') ? 1 :
            C4::Context->set_preference( 'EncryptionConfiguration', '', 'Generic configuration for encryption', 'Textarea' );
        my $SSBlockCleanOlderThanThis   = defined C4::Context->preference('SSBlockCleanOlderThanThis') ? 1 :
            C4::Context->set_preference( 'SSBlockCleanOlderThanThis', '3650', 'Clean expired self-service branch-specific access blocks older than this many days. You must enable access rule "BranchBlock" in syspref "SSRules" for this to have effect.', 'Integer' );
        my $SSBlockDefaultDuration      = defined C4::Context->preference('SSBlockDefaultDuration') ? 1 :
            C4::Context->set_preference( 'SSBlockDefaultDuration', '60', 'Self-service branch-specific access block default duration. You must enable access rule "BranchBlock" in syspref "SSRules" for this to have effect.', 'Free' );


        #This is copypaste from Koha::Plugins->InstallPlugins(). It is important to be called here
        #so we can execute plugin lifecycle tests, because Koha::Plugins::InstallPlugins is hacked to
        #generate method definitions in DB only in bulk, and they are not generated during single plugin
        #install.
        foreach my $method ( @{ Class::Inspector->methods( $self->{class}, 'public' ) } ) {
            Koha::Plugins::Method->new(
                {
                    plugin_class  => $self->{class},
                    plugin_method => $method,
                }
            )->store();
        }

        bug33503hotfix($self) unless $ENV{KOHA_PLUGIN_DEV_MODE};
    };
    if ($@) {
        $logger->fatal("Installing koha-plugin-self-service failed: $@");
        die $@;
    }
    return 1;
}

sub configure {
    my ($self, $args) = @_;
    my $logger = Koha::Logger->get();
    $logger->trace('Entering configure()');
    my $cgi = $self->{'cgi'};

    eval {
        if ( $cgi && $cgi->param('save') ) {
            $logger->trace('Saving changes');
            #openinghours handling
            my $openinghours = {};
            my @branches = Koha::Libraries->search()->as_list;
            for my $branch (@branches) {
                for my $wday (0,1,2,3,4,5,6) {
                    $openinghours->{$branch->branchcode} = [] unless $openinghours->{$branch->branchcode};
                    $openinghours->{$branch->branchcode}->[$wday] = [] unless $openinghours->{$branch->branchcode}->[$wday];
                    $openinghours->{$branch->branchcode}->[$wday]->[0] = $cgi->param("openinghours_".$branch->branchcode."_".$wday."_start") || '00:00';
                    $openinghours->{$branch->branchcode}->[$wday]->[1] = $cgi->param("openinghours_".$branch->branchcode."_".$wday."_end") || '00:00';
                }
            }
            C4::Context->set_preference('OpeningHours', YAML::XS::Dump($openinghours));

            C4::Context->set_preference('SSRules', $cgi->param('SSRules'));
            C4::Context->set_preference('EncryptionConfiguration', $cgi->param('EncryptionConfiguration'));
            C4::Context->set_preference('SSBlockCleanOlderThanThis', $cgi->param('SSBlockCleanOlderThanThis'));
            C4::Context->set_preference('SSBlockDefaultDuration', $cgi->param('SSBlockDefaultDuration'));

            $logger->trace('Saved changes');
            $self->go_home();
        }
        else {
            $logger->trace('Showing configurer UI');
            #prepare the openinghours editor
            my @branches = Koha::Libraries->search()->as_list;
            my $openinghours = C4::Context->preference('OpeningHours');
            my $openinghours_loop = {};
            my $openinghours_loop_error;
            if ($openinghours) {
                eval {
                    $openinghours = YAML::XS::Load( $openinghours );
                };
                if ($@) {
                    $openinghours_loop_error = $@;
                    $openinghours = {};
                }
            } else {
                $openinghours = {};
            }
            for my $branch (@branches) {
                #remove branches that might no longer exists from the configuration
                $openinghours_loop->{$branch->branchcode} = $openinghours->{$branch->branchcode} || {};
            }
            unless ($openinghours_loop_error) {
                $openinghours_loop_error = Koha::Plugin::Fi::KohaSuomi::SelfService::OpeningHours::validate($openinghours);
            }


            my $sstac = Koha::Patron::Attribute::Types->find({code => 'SST&C'});
            my $sstac_status = 'OK';
            $sstac_status = 'Missing' unless $sstac;
            my $ssban = Koha::Patron::Attribute::Types->find({code => 'SSBAN'});
            my $ssban_status = 'OK';
            $ssban_status = 'Missing' unless $ssban;

            ## Grab the values we already have for our settings, if any exist
            my $template = $self->get_template({ file => 'configure.tt' });
            $template->param(
                SSRules => C4::Context->preference( 'SSRules' ),
                OpeningHours => C4::Context->preference( 'OpeningHours' ),
                EncryptionConfiguration => C4::Context->preference( 'EncryptionConfiguration' ),
                SSBlockCleanOlderThanThis => C4::Context->preference( 'SSBlockCleanOlderThanThis' ),
                SSBlockDefaultDuration => C4::Context->preference( 'SSBlockDefaultDuration' ),
                bor_attr_sstac_status => $sstac_status,
                bor_attr_ssban_status => $ssban_status,
                pref_RESTBasicAuth_status => C4::Context->preference('RESTBasicAuth'),

                openinghours_loop => $openinghours_loop,
                openinghours_loop_error => $openinghours_loop_error,

                plugin_version => $Koha::Plugin::Fi::KohaSuomi::SelfService::VERSION,
            );

            $logger->trace('Rendering UI');
            $self->output_html( $template->output() );
        }
    };
    if ($@) {
        $logger->error("Configuring koha-plugin-self-service failed: $@");
        die $@;
    }
    return 1;
}

sub upgrade {
    my ( $self, $args ) = @_;

    my $dt = Koha::DateUtils::dt_from_string();
    $self->store_data( { last_upgraded => $dt->ymd('-') . ' ' . $dt->hms(':') } );

    bug33503hotfix($self) unless $ENV{KOHA_PLUGIN_DEV_MODE};

    return 1;
}

sub uninstall {
    my ( $self, $args ) = @_;
    my $logger = Koha::Logger->get();

    eval {
        C4::Context->dbh->do(q{DELETE FROM systempreferences WHERE variable = 'SSRules';});
        C4::Context->dbh->do(q{DELETE FROM systempreferences WHERE variable = 'OpeningHours';});
        C4::Context->dbh->do(q{DELETE FROM systempreferences WHERE variable = 'EncryptionConfiguration';});
        C4::Context->dbh->do(q{DELETE FROM systempreferences WHERE variable = 'SSBlockCleanOlderThanThis';});
        C4::Context->dbh->do(q{DELETE FROM systempreferences WHERE variable = 'SSBlockDefaultDuration';});

        # Delete borrower attributes
        my $sstc = Koha::Patron::Attributes->find({ code => 'SST&C' });
        $sstc->delete if defined $sstc;
        my $ssban = Koha::Patron::Attributes->find({ code => 'SSBAN' });
        $ssban->delete if defined $ssban;

        # Delete permissions
        C4::Context->dbh->do(q{DELETE FROM permissions WHERE code = 'get_self_service_status';});
        C4::Context->dbh->do(q{DELETE FROM permissions WHERE code = 'ss_blocks_list';});
        C4::Context->dbh->do(q{DELETE FROM permissions WHERE code = 'ss_blocks_get';});
        C4::Context->dbh->do(q{DELETE FROM permissions WHERE code = 'ss_blocks_create';});
        C4::Context->dbh->do(q{DELETE FROM permissions WHERE code = 'ss_blocks_edit';});
        C4::Context->dbh->do(q{DELETE FROM permissions WHERE code = 'ss_blocks_delete';});

        my $table = $self->get_qualified_table_name('borrower_ss_blocks');
        C4::Context->dbh->do("DROP TABLE IF EXISTS $table;");

        #This is copypaste from Koha::Plugins::Handler->delete(). It is important to be called here
        #so we can execute plugin lifecycle tests, because Koha::Plugins::Handler->delete removes all
        #plugin source code files.
        C4::Context->dbh->do( "DELETE FROM plugin_data WHERE plugin_class = ?", undef, ($self->{class}) );
        Koha::Plugins::Methods->search({ plugin_class => $self->{class} })->delete();
    };
    if ($@) {
        $logger->fatal("Uninstalling koha-plugin-self-service failed: $@");
        die $@;
    }
    return 1;
}

sub bug33503hotfix {
    my ($plugin) = @_;
    my $absolute_base_dir_path = $plugin->mbf_dir();

    bug33503_rewrite_openapi_file_refs($absolute_base_dir_path.'/openapi.json') if -e $absolute_base_dir_path.'/openapi.json';
    bug33503_rewrite_openapi_file_refs($absolute_base_dir_path.'/openapi.yaml') if -e $absolute_base_dir_path.'/openapi.yaml';
    require File::Find;
    File::Find::find(sub {
        bug33503_rewrite_openapi_file_refs($File::Find::name) if $File::Find::name =~ m(.json|.yaml);
    }, $absolute_base_dir_path.'/openapi') if -e $absolute_base_dir_path.'/openapi';
}

sub bug33503_rewrite_openapi_file_refs {
    my ($absolute_file_path) = @_;
    my $absolute_base_dir_path = File::Basename::dirname($absolute_file_path);

    my $contents = File::Slurp::read_file($absolute_file_path) or die $!;
    my $c = YAML::XS::Load($contents) or die $!;
    Koha::Plugin::Fi::KohaSuomi::SelfService::URLLib::convert_refs_to_absolute($c, $absolute_base_dir_path.'/');
    $contents = YAML::XS::Dump($c) or die $!;
    File::Slurp::write_file($absolute_file_path, $contents) or die $!;
}

1;
