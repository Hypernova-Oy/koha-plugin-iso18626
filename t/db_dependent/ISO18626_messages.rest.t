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
    $ENV{LOG4PERL_VERBOSITY_CHANGE} = 6;
    $ENV{MOJO_OPENAPI_DEBUG} = 1;
    $ENV{MOJO_LOG_LEVEL} = 'debug';
    $ENV{MOJO_INACTIVITY_TIMEOUT} = 3600;
    $ENV{VERBOSE} = 1;
    $ENV{KOHA_PLUGIN_DEV_MODE} = 1;
}

use Modern::Perl;
use utf8;

use Test::More tests => 1;
use Test::Deep;
use Test::Mojo;

use Mojo::Cookie::Request;

use Koha::Database;

use Koha::Plugin::ISO18626;

my $schema = Koha::Database->schema;

$schema->storage->txn_begin;
my $plugin =  Koha::Plugin::ISO18626->new(); #Make sure the plugin is installed

my $t = Test::Mojo->new('Koha::REST::V1');

subtest("Scenario: Simple test REST API calls.", sub {

    plan tests => 1;

    subtest "GET /selfservice/pincheck" => sub {
        plan tests => 2;

        my $xml = <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<ISO18626Message>
  <Request>
    <Header>
      <SupplyingAgencyId>
        <AgencyIdType schema="http://illtransactions.org/ISO18626/OpenCodeList/AgencyIdTypeList-V2.0">ISIL</AgencyIdType>
        <AgencyIdValue>Fi-NL</AgencyIdValue>
      </SupplyingAgencyId>
    </Header>
    <BibliographicInfo>
      <SupplierUniqueRecordId>1337</SupplierUniqueRecordId>
    </BibliographicInfo>
  </Request>
</ISO18626Message>
XML

        $t->post_ok('/api/v1/contrib/iso18626/iso18626' => {Accept => 'application/xml'} => $xml)
        ->status_is('200');
        print $t->tx->res->body;

        $t->get_ok('/api/v1/contrib/iso18626/selfservice/pincheck' => json => {cardnumber => 1234, password => 1234})
        ->status_is('200');
    };
});

$schema->storage->txn_rollback;

1;
