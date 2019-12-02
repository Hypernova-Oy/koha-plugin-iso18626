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

use C4::Context;

use Koha::Patron::Attributes;

sub install {
    my ( $self, $args ) = @_;

    # Create tables
    my $table = $self->get_qualified_table_name('borrower_ss_blocks');

    my $borrower_ss_blocks = C4::Context->dbh->do(qq{

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
  KEY `branchcode` (`branchcode`),
  KEY `expirationdate` (`expirationdate`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `borrower_ss_blocks_ibfk_1` FOREIGN KEY (`borrowernumber`) REFERENCES `borrowers` (`borrowernumber`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

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
    eval {
        C4::Context->dbh->do(q{
INSERT INTO permissions (module_bit, code, description) VALUES
( 4,    'get_self_service_status',   'Allow listing all self-service blocks for a Patron.');
});
    };
    eval {
        C4::Context->dbh->do(q{
INSERT INTO permissions (module_bit, code, description) VALUES
( 4,    'ss_blocks_list',            'Allow listing all self-service blocks for a Patron.');
});
    };
    eval {
        C4::Context->dbh->do(q{
INSERT INTO permissions (module_bit, code, description) VALUES
( 4,    'ss_blocks_get',             'Allow fetching the data of a single self-service block for a Patron.');
});
    };
    eval {
        C4::Context->dbh->do(q{
INSERT INTO permissions (module_bit, code, description) VALUES
( 4,    'ss_blocks_create',          'Allow creating a single self-service block for a Patron.');
});
    };
    eval {
        C4::Context->dbh->do(q{
INSERT INTO permissions (module_bit, code, description) VALUES
( 4,    'ss_blocks_edit',            'Allow editing the data of a single self-service block for a Patron.');
});
    };
    eval {
        C4::Context->dbh->do(q{
INSERT INTO permissions (module_bit, code, description) VALUES
( 4,    'ss_blocks_delete',          'Allow deleting a single self-service block for a Patron.');
});
    };

    # Create system preferences
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

    $SSRules = C4::Context->set_preference('SSRules', $SSRules, 'Self-service access rules, age limit + whitelisted borrower categories', 'Text')
        unless C4::Context->preference('SSRules');

    my $OpeningHours                = defined C4::Context->preference('OpeningHours') ? 1 :
        C4::Context->set_preference( 'OpeningHours', '', 'Define opening hours YAML', 'Textarea', '70|10' );
    my $EncryptionConfiguration     = defined C4::Context->preference('EncryptionConfiguration') ? 1 :
        C4::Context->set_preference( 'EncryptionConfiguration', '', 'Generic configuration for encryption', 'Textarea' );
    my $SSBlockCleanOlderThanThis   = defined C4::Context->preference('SSBlockCleanOlderThanThis') ? 1 :
        C4::Context->set_preference( 'SSBlockCleanOlderThanThis', '3650', 'Clean expired self-service branch-specific access blocks older than this many days. You must enable access rule "BranchBlock" in syspref "SSRules" for this to have effect.', 'Integer' );
    my $SSBlockDefaultDuration      = defined C4::Context->preference('SSBlockDefaultDuration') ? 1 :
        C4::Context->set_preference( 'SSBlockDefaultDuration', '60', 'Self-service branch-specific access block default duration. You must enable access rule "BranchBlock" in syspref "SSRules" for this to have effect.', 'Free' );

    if ( $sstc && $ssban && $borrower_ss_blocks && $SSRules && $OpeningHours &&
         $EncryptionConfiguration && $SSBlockCleanOlderThanThis && $SSBlockDefaultDuration )
    {
        return 1;
    }
    else {
        return 0;
    }
}

sub upgrade {
    my ( $self, $args ) = @_;

    my $dt = dt_from_string();
    $self->store_data( { last_upgraded => $dt->ymd('-') . ' ' . $dt->hms(':') } );

    return 1;
}

sub uninstall {
    my ( $self, $args ) = @_;

    C4::Context->delete_preference( 'SSRules' );
    C4::Context->delete_preference( 'OpeningHours' );
    C4::Context->delete_preference( 'EncryptionConfiguration' );
    C4::Context->delete_preference( 'SSBlockCleanOlderThanThis' );
    C4::Context->delete_preference( 'SSBlockDefaultDuration' );

    # Delete borrower attributes
    my $sstc = Koha::Patron::Attributes->find({ code => 'SST&C' });
       $sstc->delete if defined $sstc;
    my $ssban = Koha::Patron::Attributes->find({ code => 'SSBAN' });
       $ssban->delete if defined $ssban;

    # Delete permissions
    eval {
        C4::Context->dbh->do(q{
DELETE FROM permissions WHERE code = 'get_self_service_status';
});
    };
    eval {
        C4::Context->dbh->do(q{
DELETE FROM permissions WHERE code = 'ss_blocks_list';
});
    };
    eval {
        C4::Context->dbh->do(q{
DELETE FROM permissions WHERE code = 'ss_blocks_get';
});
    };
    eval {
        C4::Context->dbh->do(q{
DELETE FROM permissions WHERE code = 'ss_blocks_create';
});
  };
    eval {
      C4::Context->dbh->do(q{
DELETE FROM permissions WHERE code = 'ss_blocks_edit';
});
    };
    eval {
      C4::Context->dbh->do(q{
DELETE FROM permissions WHERE code = 'ss_blocks_delete';
});
    };
  
    my $table = $self->get_qualified_table_name('borrower_ss_blocks');

    return C4::Context->dbh->do("DROP TABLE $table");
}

1;
