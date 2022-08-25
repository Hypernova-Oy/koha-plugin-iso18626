package Koha::Plugin::Fi::KohaSuomi::SelfService::Exception;

# Copyright 2022 Hypernova Oy
# Copyright 2016 KohaSuomi
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

use Koha::Exception;

use Exception::Class (
    'Koha::Exception::SelfService' => {
        isa => 'Koha::Exception',
        description => "A generic Self-Service exception type",
    },
    'Koha::Exception::SelfService::BlockedBorrowerCategory' => {
        isa => 'Koha::Exception::SelfService',
        description => "The given borrower has an unauthorized borrower category",
    },
    'Koha::Exception::SelfService::FeatureUnavailable' => {
        isa => 'Koha::Exception::SelfService',
        description => 'Feature requested is not currently available',
    },
    'Koha::Exception::SelfService::OpeningHours' => {
        isa => 'Koha::Exception::SelfService',
        description => "Self-service resource closed at this time. Possibly outside opening hours or otherwise library has set this resource unavailable at this specific time. Try again alter. Attached time fields in ISO8601.",
        fields => ['startTime', 'endTime'],
    },
    'Koha::Exception::SelfService::PermissionRevoked' => {
        isa => 'Koha::Exception::SelfService',
        description => "The given borrower has got his self-service usage permission revoked",
        fields => ['expirationdate'],
    },
    'Koha::Exception::SelfService::TACNotAccepted' => {
        isa => 'Koha::Exception::SelfService',
        description => "Self-Service terms and conditions has not been accepted by the user in the OPAC",
    },
    'Koha::Exception::SelfService::Underage' => {
        isa => 'Koha::Exception::SelfService',
        description => "The given borrower is too young to access the self-service resource",
        fields => ['minimumAge'],
    },
);

return 1;
