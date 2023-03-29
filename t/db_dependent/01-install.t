#!/usr/bin/env perl

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

BEGIN {
    #$ENV{LOG4PERL_VERBOSITY_CHANGE} = 6;
    #$ENV{MOJO_OPENAPI_DEBUG} = 1;
    #$ENV{MOJO_LOG_LEVEL} = 'debug';
    $ENV{VERBOSE} = 1;
}

use Modern::Perl;
use utf8;

use Test::More tests => 1;
use Test::Deep;
use Test::Mojo;

use t::lib::TestBuilder;
use t::lib::Mocks;
use t::db_dependent::Util qw(build_patron);
use Koha::Plugin::Fi::KohaSuomi::SelfService;

use Koha::Database;
use Koha::Plugins::Handler;

my $schema = Koha::Database->schema;
my $builder = t::lib::TestBuilder->new;
$t::db_dependent::Util::builder = $builder;


subtest("Scenario: Simple plugin lifecycle tests.", sub {
    $schema->storage->txn_begin;
    plan tests => 5;

    my $plugin; #Instantiating a Plugin-instance autoinstalls/upgrades it to Koha

    subtest("Make sure the plugin is uninstalled", sub {
        plan tests => 1;

        #We cannot use
        #  Koha::Plugins::Handler->delete({class => 'Koha::Plugin::Fi::KohaSuomi::SelfService'}); #This actually installs and deletes the plugin.
        #Because it removes all source code files currently being developed

        $plugin = Koha::Plugin::Fi::KohaSuomi::SelfService->new(); #This implicitly calls install()
        $plugin->uninstall(); #So we have to install/upgrade + uninstall the plugin.
        ok(!$plugin->retrieve_data('__INSTALLED__'), "Uninstalled");
    });

    subtest("Install the plugin", sub {
        plan tests => 1;

        $plugin = Koha::Plugin::Fi::KohaSuomi::SelfService->new(); #This implicitly calls install()
        ok($plugin->retrieve_data('__INSTALLED__'), "Installed");
    });

    subtest("Upgrade the plugin", sub {
        plan tests => 1;

        $plugin->store_data({ '__INSTALLED_VERSION__' => '0.0.0' });
        $plugin = Koha::Plugin::Fi::KohaSuomi::SelfService->new(); #This implicitly calls upgrade()
        is($plugin->get_metadata->{version}, $plugin->retrieve_data('__INSTALLED_VERSION__'), "Upgraded");
    });

    subtest("Configure the plugin", sub {
        plan tests => 2;

        $plugin->{cgi} = FakeCGI->new();
        $plugin->{cgi}->{save} = 1;
        $plugin->{cgi}->{openinghours_IPT_1_start} = "11:11";
        $plugin->{cgi}->{openinghours_IPT_1_end} = "21:21";
        $plugin->{cgi}->{openinghours_IPT_2_start} = "12:12";
        $plugin->{cgi}->{openinghours_IPT_2_end} = "22:22";
        $plugin->{cgi}->{openinghours_IPT_3_start} = "13:13";
        $plugin->{cgi}->{openinghours_IPT_3_end} = "23:23";

        ok($plugin->configure(), "Configure loaded");

        like(C4::Context->preference("OpeningHours"), qr/IPT/, "IPT Library present");
    });

    subtest("Load plugin configurer", sub {
        plan tests => 1;

        $plugin->{cgi} = FakeCGI->new();
        SKIP: {
            skip "Mocking CGI is completely out-of-scope of this work. Manually running theses tests still give a bit of confidence regarding data munching for the view.", 1;
            ok($plugin->configure(), "Configure loaded");
        }
    });

    $schema->storage->txn_rollback;
});

package FakeCGI;

sub new {
    return bless({}, "FakeCGI");
}
sub param {
    return $_[0]->{$_[1]};
}
sub cookie {
    return {};
}
sub redirect {
    return "";
}

1;
