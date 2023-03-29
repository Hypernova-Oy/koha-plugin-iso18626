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
use t::db_dependent::opening_hours_context;
use Mojo::Cookie::Request;

use Koha::Database;

use Koha::Plugin::Fi::KohaSuomi::SelfService;

my $schema = Koha::Database->schema;
my $builder = t::lib::TestBuilder->new;
$t::db_dependent::Util::builder = $builder;

$schema->storage->txn_begin;
my $plugin =  Koha::Plugin::Fi::KohaSuomi::SelfService->new(); #Make sure the plugin is installed

my $t = Test::Mojo->new('Koha::REST::V1');
t::lib::Mocks::mock_preference( 'RESTBasicAuth', 1 );

subtest("Scenario: Simple test REST API calls.", sub {

    plan tests => 12;

    my ($patron, $host, $patronPassword) = build_patron({
        permissions => [],
        branchcode => 'IPT',
    });
    my ($librarian, $librarian_host) = build_patron({
        permissions => [
            { module => 4, subpermission => 'get_self_service_status' },
        ]
    });

    subtest("Set opening hours", sub {
        plan tests => 1;

        my $hours = t::db_dependent::opening_hours_context::createContext;
        C4::Context->set_preference("OpeningHours",$hours);
        ok(1, $hours);
    });
    subtest("Given a system preference 'SSRules'", sub {
        plan tests => 1;

        C4::Context->set_preference("SSRules",
            "---\n".
            "TaC: 1\n".
            "Permission: 1\n".
            "BorrowerCategories: PT S\n".
            "MinimumAge: 15\n".
            "MaxFines: 1\n".
            "CardExpired: 1\n".
            "CardLost: 1\n".
            "Debarred: 1\n".
            "OpeningHours: 1\n".
            "BranchBlock: 1\n".
            "\n");
        Koha::Caches->get_instance()->clear_from_cache('SSRules');
        ok(1, "Step ok");
    });

    subtest "GET /selfservice/pincheck" => sub {
        plan tests => 13;

        $t->get_ok($host.'/api/v1/contrib/kohasuomi/selfservice/pincheck' => json => {cardnumber => $patron->userid, password => $patronPassword})
        ->status_is('403')
        ->json_like('/error', qr/Missing required permission/, 'Missing required permission');

        $t->get_ok($librarian_host.'/api/v1/contrib/kohasuomi/selfservice/pincheck' => json => {cardnumber => $patron->userid, password => $patronPassword})
        ->status_is('200')
        ->json_like('/permission', qr/1/, "Permission denied");

        $t->get_ok($librarian_host.'/api/v1/contrib/kohasuomi/selfservice/pincheck' => json => {cardnumber => $patron->userid, password => '1234'})
        ->status_is('200')
        ->json_like('/permission', qr/0/, "Permission denied")
        ->json_like('/error', qr/Wrong password/);

        $t->get_ok($librarian_host.'/api/v1/contrib/kohasuomi/selfservice/pincheck' => json => {cardnumber => 'this-not-exists', password => $patronPassword})
        ->status_is('404')
        ->json_like('/error', qr/cardnumber/, "No such cardnumber");
    };

    subtest "GET /borrowers/ssstatus, terms and conditions not accepted." => sub {
        plan tests => 7;

        $t->get_ok($host.'/api/v1/contrib/kohasuomi/borrowers/ssstatus')
        ->status_is('403')
        ->json_like('/error', qr/Missing required permission/, 'List: No permission');

        # GET Request with formdata body. Test::Mojo clobbers formdata to query params no matter what. So we cheat it a bit here.
        $t->ua->on(start => sub { my ($ua, $tx) = @_; $tx->req->method('GET') });
        $t->post_ok($librarian_host.'/api/v1/contrib/kohasuomi/borrowers/ssstatus' => form => {cardnumber => $patron->userid(), branchcode => 'IPT'})
        ->status_is('200')
        ->json_like('/permission', qr/0/, "Permission denied")
        ->json_like('/error', qr/Koha::Plugin::Fi::KohaSuomi::SelfService::Exception::TACNotAccepted/);
    };

    subtest("GET /borrowers/ssstatus, terms and conditions accepted", sub {
        plan tests => 5;

        ok($patron->extended_attributes(
            $patron->extended_attributes->merge_and_replace_with([{ code => 'SST&C', attribute => '1' }])
        ), "Terms and conditions accepted for the end-user");

        # GET Request with formdata body. Test::Mojo clobbers formdata to query params no matter what. So we cheat it a bit here.
        $t->post_ok($librarian_host.'/api/v1/contrib/kohasuomi/borrowers/ssstatus' => form => {cardnumber => $patron->userid(), branchcode => 'IPT'})
        ->status_is('200')
        ->json_like('/permission', qr/0/, "Permission denied")
        ->json_like('/error', qr/Koha::Plugin::Fi::KohaSuomi::SelfService::Exception::BlockedBorrowerCategory/);
    });

    subtest("GET /borrowers/ssstatus, OK, categorycode changed", sub {
        plan tests => 4;

        ok($patron->categorycode('PT')->store(), "Categorycode changed for the end-user");

        # GET Request with formdata body. Test::Mojo clobbers formdata to query params no matter what. So we cheat it a bit here.
        $t->post_ok($librarian_host.'/api/v1/contrib/kohasuomi/borrowers/ssstatus' => form => {cardnumber => $patron->userid(), branchcode => 'IPT'})
        ->status_is('200')
        ->json_like('/permission', qr/1/, "Permission granted");
    });

    subtest("GET /borrowers/ssstatus, library closed", sub {
        plan tests => 6;

        # GET Request with formdata body. Test::Mojo clobbers formdata to query params no matter what. So we cheat it a bit here.
        $t->post_ok($librarian_host.'/api/v1/contrib/kohasuomi/borrowers/ssstatus' => form => {cardnumber => $patron->userid(), branchcode => 'UPL'})
        ->status_is('200')
        ->json_like('/permission', qr/0/, "Permission denied")
        ->json_like('/startTime', qr/07:00/, "startTime")
        ->json_like('/endTime', qr/06:00/, "endTime")
        ->json_like('/error', qr/Koha::Plugin::Fi::KohaSuomi::SelfService::Exception::OpeningHours/);
    });

    subtest("GET /borrowers/ssstatus, bad library", sub {
        plan tests => 3;

        # GET Request with formdata body. Test::Mojo clobbers formdata to query params no matter what. So we cheat it a bit here.
        $t->post_ok($librarian_host.'/api/v1/contrib/kohasuomi/borrowers/ssstatus' => form => {cardnumber => $patron->userid(), branchcode => '555'})
        ->status_is('404')
        ->json_like('/error', qr/No Library.+?555/, "No such library");
    });

    subtest("GET /borrowers/ssstatus, bad card", sub {
        plan tests => 3;

        # GET Request with formdata body. Test::Mojo clobbers formdata to query params no matter what. So we cheat it a bit here.
        $t->post_ok($librarian_host.'/api/v1/contrib/kohasuomi/borrowers/ssstatus' => form => {cardnumber => 'not-exists', branchcode => 'IPT'})
        ->status_is('404')
        ->json_like('/error', qr/No.+?not-exists/, "No such card");
    });

    subtest("GET /selfservice/openinghours", sub {
        plan tests => 6;

        $t->get_ok($host.'/api/v1/contrib/kohasuomi/selfservice/openinghours')
        ->status_is('200')
        ->json_like('/CPL/0/0', qr/^\d\d:\d\d$/, 'CPL->Monday->Start')
        ->json_like('/CPL/0/1', qr/^\d\d:\d\d$/, 'CPL->Monday->End')
        ->json_like('/CPL/6/0', qr/^\d\d:\d\d$/, 'CPL->Sunday->Start')
        ->json_like('/CPL/6/1', qr/^\d\d:\d\d$/, 'CPL->Sunday->End');
    });

    subtest("GET /selfservice/openinghours with errors", sub {
        plan tests => 6;

        my $old_pref = C4::Context->preference('OpeningHours');
        ok(C4::Context->set_preference('OpeningHours', '123 {asd: fff} 543'), "Break the OpeningHours-preference");

        $t->get_ok($host.'/api/v1/contrib/kohasuomi/selfservice/openinghours')
        ->status_is('501')
        ->json_like('/error', qr/^Branchcode/, 'Error description received')
        ->json_like('/123 {asd', qr/fff/, 'Broken openinghours forwarded');

        ok(C4::Context->set_preference('OpeningHours', $old_pref), "Revert the old OpeningHours-preference");
    });

    subtest("GET /selfservice/openinghours/self", sub {
        plan tests => 12;

        $t->get_ok('///api/v1/contrib/kohasuomi/selfservice/openinghours/self')
        ->status_is('401')
        ->json_like('/error', qr/must be authenticated/, 'API user must be authenticated');

        $t->get_ok($librarian_host.'/api/v1/contrib/kohasuomi/selfservice/openinghours/self')
        ->status_is('404')
        ->json_like('/error', qr/No opening hours defined for.+?FPL/, 'No Opening Hours defined for logged in user\'s branch');

        $t->get_ok($host.'/api/v1/contrib/kohasuomi/selfservice/openinghours/self')
        ->status_is('200')
        ->json_like('/0/0', qr/^07:00$/, 'IPT->Monday->Start')
        ->json_like('/0/1', qr/^20:00$/, 'IPT->Monday->End')
        ->json_like('/6/0', qr/^12:00$/, 'IPT->Sunday->Start')
        ->json_like('/6/1', qr/^16:00$/, 'IPT->Sunday->End');
    });
});

$schema->storage->txn_rollback;

sub prepareBasicAuthHeader {
    my ($username, $password) = @_;
    return 'Basic '.MIME::Base64::encode($username.':'.$password, '');
}

1;
