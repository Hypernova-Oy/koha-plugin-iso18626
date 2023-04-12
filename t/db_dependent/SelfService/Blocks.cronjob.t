#!perl

BEGIN {
    $ENV{LOG4PERL_VERBOSITY_CHANGE} = 6;
}

use Modern::Perl;
use Test::More tests => 1;

use Koha::Database;

use Koha::Plugin::Fi::KohaSuomi::SelfService;

my $schema  = Koha::Database->new->schema;

subtest("Scenario: Cronjob runs", sub {
    plan tests => 1;
    $schema->storage->txn_begin;

    my $plugin = Koha::Plugin::Fi::KohaSuomi::SelfService->new();
    ok($plugin->cronjob_nightly(), "Cronjob runs without crashing");

    $schema->storage->txn_rollback;
});

done_testing();
