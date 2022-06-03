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

my $schema = Koha::Database->schema;
my $builder = t::lib::TestBuilder->new;
$t::db_dependent::Util::builder = $builder;


subtest("Scenario: Simple test REST API calls.", sub {
    $schema->storage->txn_begin;
    plan tests => 4;

    my $plugin = Koha::Plugin::Fi::KohaSuomi::SelfService->new();

    subtest("Make sure the plugin is uninstalled", sub {
        plan tests => 1;

        ok($plugin->uninstall(), "Uninstalled");
    });
    subtest("Install the plugin", sub {
        plan tests => 1;

        ok($plugin->install(), "Installed");
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
    return {};
}

1;
