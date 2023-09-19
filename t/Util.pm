package t::Util;

use Modern::Perl;
use Exporter qw(import);

use Test::More;

use Try::Tiny;

my $now = DateTime->now(
            time_zone => C4::Context->tz,
);

=head now
my $date15daysago = now(subtract => {days => 15})
my $now = now()
=cut
sub now {
    my ($op, $value) = @_;
    if ($op) {
        $now->clone->subtract(%$value) if $op eq "subtract";
    }
    return $now;
}

=head2 tc
Wrap a subtest's subroutine in a try/catch, and report death as a failing test
=cut
sub tc {
    my $func = shift;
    return sub {
    try {
        $func->();
    } catch {
        is_deeply($_, undef, "Subtest died of an exception!");
    }
    }
}

our @EXPORT_OK = qw(now tc);  # symbols to export on request
