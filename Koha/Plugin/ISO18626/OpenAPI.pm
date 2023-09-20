package Koha::Plugin::ISO18626::OpenAPI;

# Copyright 2023 Hypernova Oy
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

use Koha::Plugin::ISO18626::URLLib;

use JSON::Validator::Schema::OpenAPIv2;

# Pending: https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=33503
sub api_spec {
    my ($plugin) = @_;
    return JSON::Validator::Schema::OpenAPIv2->new;

    my $schema2 = JSON::Validator::Schema::OpenAPIv2->new;
    $schema2->resolve($plugin->mbf_dir() . "/openapi.yaml");
    return $schema2->bundle->data; #Bundle merges the external/internal/local references in the plugin schema path.
}

sub api_namespace {
    my ($plugin) = @_;

    return 'iso18626';
}

#from https://github.com/NatLibFi/koha-plugin-rest-di/blob/main/Koha/Plugin/Fi/KohaSuomi/DI.pm
sub api_routes {
    my ($plugin) = @_;

    my $spec_dir = $plugin->mbf_dir();

    my $schema = JSON::Validator::Schema::OpenAPIv2->new;
    my $spec = $schema->resolve($spec_dir . '/openapi.yaml');

    # The installer automatically changes the references to absolute (bug33503), but not during development.
    # To have this work more easily during development, we still check for dynamic $refs
    # Remove this comment when the Bug 33505 compatibility is no longer needed.
    return Koha::Plugin::ISO18626::URLLib::convert_refs_to_absolute($spec->data->{'paths'}, '' . $spec_dir . '/');
}

1;
