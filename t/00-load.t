#!/usr/bin/perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

BEGIN {
    $ENV{KOHA_PLUGIN_DEV_MODE} = 1;
}

use Modern::Perl;

use Test::More;
use File::Spec;
use File::Find;
use English qw( -no_match_vars );

=head1 DESCRIPTION

00-load.t: This script is called by the pre-commit git hook to test modules compile

=cut

use_ok('Koha::Plugin::Fi::KohaSuomi::SelfService');

# Loop through the Koha::Plugin::Fi::KohaSuomi::SelfService modules
my $package_path = 'Koha/Plugin/Fi/KohaSuomi/SelfService';
my $lib = File::Spec->rel2abs('Koha/Plugin/Fi/KohaSuomi/SelfService');
find({
    bydepth => 1,
    no_chdir => 1,
    wanted => sub {
        my $m = $_;
        return unless $m =~ s/[.]pm$//;
warn $package_path;
        $m =~ s{^.*/$package_path/}{$package_path/};
        $m =~ s{/}{::}g;
        use_ok($m) || BAIL_OUT("***** PROBLEMS LOADING FILE '$m'");
    },
}, $lib);

done_testing();

