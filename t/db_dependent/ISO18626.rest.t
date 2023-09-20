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

use t::lib::TestBuilder;
use t::lib::Mocks;
use t::db_dependent::Util qw(tc build_patron daoAsXML responseAsDAO);

use Koha::Database;

use Koha::Plugin::ISO18626;

my $schema = Koha::Database->schema;
my $builder = t::lib::TestBuilder->new;
$t::db_dependent::Util::builder = $builder;

$schema->storage->txn_begin;
my $plugin =  Koha::Plugin::ISO18626->new(); #Make sure the plugin is installed

my $t = Test::Mojo->new('Koha::REST::V1');
t::lib::Mocks::mock_preference( 'RESTBasicAuth', 1 );

subtest("Scenario: A Full ISO18626 transaction with no problems.", tc(sub {
    my ($transaction);

    plan tests => 12;

    ok(my $supplyingAgency = {
        supplyingAgencyId => Koha::Plugin::ISO18626::DAO::AgencyId->new()
                                ->agencyIdValue('Fi-NL')
                                ->agencyIdType
                                ->value('ISIL')
                                ->uri("http://illtransactions.org/ISO18626/OpenCodeList/AgencyIdTypeList-V2.0"),
    }, "Given a Supplying Agency to request the ILL from");

    my ($enduserPatron, $enduserCredentials, $patronPassword) = build_patron({
        permissions => [],
        branchcode => 'CPL',
    });
    ok($enduserPatron, "Given an End-User, who is receiving the ILL in the RA");

    my ($libraryPatron, $libraryCredentials) = build_patron({
        permissions => [
            { module => 22, subpermission => 'iso18626' },
        ],
        branchcode => 'IPT',
    });
    ok($libraryPatron, "And a Library User, which represents the SA in the RA.");

    ok(my $supplierUniqueRecordId, "And a SupplierUniqueRecordId, the known itemnumber/barcode of the SA");

    subtest("Request sent" => tc(sub {
        plan tests => 13;

        my $request = Koha::Plugin::ISO18626::DAO::Request->new;
        $request->header->supplyingAgencyId($supplyingAgency->{supplyingAgencyId})
                ->bibliographicInfo->supplierUniqueRecordId($supplierUniqueRecordId);
        ok($request, "Given a ISO18626 Request Message");

        $t->post_ok('/api/v1/contrib/iso18626' => {Accept => 'application/xml'} => daoAsXML($request), "When the Request is sent")
        ->status_is('200', "And accepted");
        my $requestConfirmation = responseAsDAO($t);
        is($requestConfirmation->messageStatus, 'OK', "Then a 'OK' RequestResponse is received");

        $transaction = {
            requestingAgencyRequestId => 11,
            status => 'RequestReceived',
        };
        is($transaction->{status}, 'RequestReceived', "Then an ILL Transaction is started in status 'RequestReceived'");
    }));

    subtest("SupplyingAgencyMessage received" => tc(sub {
        plan tests => 13;

        my $sam = Koha::Plugin::ISO18626::DAO::SupplyingAgencyMessage->new;
        $sam->statusInfo->status('ExpectToSupply');
        ok($sam, "Given a ISO18626 SupplyingAgencyMessage");

        $t->post_ok('/api/v1/contrib/iso18626' => {Accept => 'application/xml'} => daoAsXML($sam), "When the SAMessage is received")
        ->status_is('200', "And accepted");
        my $samConfirmation = responseAsDAO($t);
        is($samConfirmation->messageStatus, 'OK', "Then a 'OK' SAMConfirmation is received");

        $transaction = {
            requestingAgencyRequestId => 11,
            status => 'ExpectToSupply',
        };
        is($transaction->{status}, 'ExpectToSupply', "Then the ILL Transaction has the status 'ExpectToSupply'");
    }));
}));

$schema->storage->txn_rollback;

1;
