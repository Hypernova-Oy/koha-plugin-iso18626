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
    plan tests => 2;

    my $plugin = Koha::Plugin::Fi::KohaSuomi::SelfService->new();

    subtest("Make sure the plugin is uninstalled", sub {
        plan tests => 1;

        ok($plugin->uninstall(), "Uninstalled");
    });
    subtest("Install the plugin", sub {
        plan tests => 1;

        ok($plugin->install(), "Installed");
    });

    $schema->storage->txn_rollback;
});

1;
