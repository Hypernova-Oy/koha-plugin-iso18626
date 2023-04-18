package Koha::Plugin::Fi::KohaSuomi::SelfService::OpenAPI;

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

use JSON::Validator::Schema::OpenAPIv2;

# Pending: https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=33503
sub api_spec {
    my ( $plugin, $args ) = @_;
    return JSON::Validator::Schema::OpenAPIv2->new;

    my $schema2 = JSON::Validator::Schema::OpenAPIv2->new;
    $schema2->resolve($plugin->mbf_dir() . "/openapi.yaml");
    return $schema2->bundle->data; #Bundle merges the external/internal/local references in the plugin schema path.
}

sub api_namespace {
    my ( $plugin ) = @_;

    return 'kohasuomi';
}

#from https://github.com/NatLibFi/koha-plugin-rest-di/blob/main/Koha/Plugin/Fi/KohaSuomi/DI.pm
sub api_routes {
    my ( $plugin, $args ) = @_;

    my $spec_dir = $plugin->mbf_dir();

    my $schema = JSON::Validator::Schema::OpenAPIv2->new;
    my $spec = $schema->resolve($spec_dir . '/openapi.yaml');

    return _convert_refs_to_absolute($spec->data->{'paths'}, 'file://' . $spec_dir . '/');
}

#from https://github.com/NatLibFi/koha-plugin-rest-di/blob/main/Koha/Plugin/Fi/KohaSuomi/DI.pm
sub _convert_refs_to_absolute {
    my ( $hashref, $path_prefix ) = @_;

    foreach my $key (keys %{ $hashref }) {
        if ($key eq '$ref') {
            if ($hashref->{$key} =~ /^(\.\/)?openapi/) {
                $hashref->{$key} = $path_prefix . $hashref->{$key};
            }
        } elsif (ref $hashref->{$key} eq 'HASH' ) {
            $hashref->{$key} = _convert_refs_to_absolute($hashref->{$key}, $path_prefix);
        } elsif (ref($hashref->{$key}) eq 'ARRAY') {
            $hashref->{$key} = _convert_array_refs_to_absolute($hashref->{$key}, $path_prefix);
        }
    }
    return $hashref;
}
#https://github.com/NatLibFi/koha-plugin-rest-di/blob/main/Koha/Plugin/Fi/KohaSuomi/DI.pm
sub _convert_array_refs_to_absolute {
    my ( $arrayref, $path_prefix ) = @_;

    my @res;
    foreach my $item (@{ $arrayref }) {
        if (ref($item) eq 'HASH') {
            $item = _convert_refs_to_absolute($item, $path_prefix);
        } elsif (ref($item) eq 'ARRAY') {
            $item = _convert_array_refs_to_absolute($item, $path_prefix);
        }
        push @res, $item;
    }
    return \@res;
}

1;
