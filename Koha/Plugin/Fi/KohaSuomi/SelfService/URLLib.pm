package Koha::Plugin::Fi::KohaSuomi::SelfService::URLLib;

# Copyright 2022 The National Library of Finland
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

=head2 SYNOPSIS

Compatibility library to deal with Bug 33503 while waiting for it to be merged into Koha-Community

https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=33503

=cut

# https://www.rfc-editor.org/rfc/rfc3986#appendix-B
sub parse_url_rfc3986 {
  $_[0] =~ m!^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?!gsm;
  return {scheme => $2, authority => $4, path => $5, query => $7, fragment => $9};
}

# https://www.rfc-editor.org/rfc/rfc3986#section-5.3
sub compose_url_rfc3986 {
  my ($url) = @_;
  my $result = "";

  if (defined($url->{scheme})) {
    #$result .= $url->{scheme} . ":"; #this is the original RFC pseudocode, producing file:/absolute/path/to/openapi.yaml
    $result .= $url->{scheme} . "://"; #For some reason JSON Pointer implementation requires file:///absolute/path/to/openapi.yaml
  }
  if (defined($url->{authority})) {
         #$result .= "//" . $url->{authority}; #this is the original RFC pseudocode
         $result .= "" . $url->{authority};
  }

  $result .= $url->{path};

  if (defined($url->{query})) {
    $result .= "?" . $url->{query};
  }
  if (defined($url->{fragment})) {
    $result .= "#" . $url->{fragment};
  }

  return $result;
}

sub convert_local_ref_to_absolute {
  my ($absolute_base_dir_path, $ref) = @_;
  my $url = parse_url_rfc3986($ref);
  if ((not(defined($url->{scheme})) || $url->{scheme} eq 'file') &&
      $url->{path} =~ m!^[^/]            #path doesnt begin with /, ie. not an absolute path
                        .+?
                        (?:.json|.yaml)  #path must contain .json or .yaml, so we know it is a file reference
                       !x
    ) {
        $url->{scheme} = 'file';
        $url->{path} = $absolute_base_dir_path.$url->{path};
        return compose_url_rfc3986($url);
    }
    return undef;
}

#from https://github.com/NatLibFi/koha-plugin-rest-di/blob/main/Koha/Plugin/Fi/KohaSuomi/DI.pm
sub convert_refs_to_absolute {
    my ( $hashref, $path_prefix ) = @_;

    foreach my $key (keys %{ $hashref }) {
        if ($key eq '$ref') {
            my $changed = convert_local_ref_to_absolute($path_prefix, $hashref->{$key});
            $hashref->{$key} = $changed if $changed;
        } elsif (ref $hashref->{$key} eq 'HASH' ) {
            $hashref->{$key} = convert_refs_to_absolute($hashref->{$key}, $path_prefix);
        } elsif (ref($hashref->{$key}) eq 'ARRAY') {
            $hashref->{$key} = convert_array_refs_to_absolute($hashref->{$key}, $path_prefix);
        }
    }
    return $hashref;
}

#https://github.com/NatLibFi/koha-plugin-rest-di/blob/main/Koha/Plugin/Fi/KohaSuomi/DI.pm
sub convert_array_refs_to_absolute {
    my ( $arrayref, $path_prefix ) = @_;

    my @res;
    foreach my $item (@{ $arrayref }) {
        if (ref($item) eq 'HASH') {
            $item = convert_refs_to_absolute($item, $path_prefix);
        } elsif (ref($item) eq 'ARRAY') {
            $item = convert_array_refs_to_absolute($item, $path_prefix);
        }
        push @res, $item;
    }
    return \@res;
}

1;
