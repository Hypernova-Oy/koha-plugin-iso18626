package Koha::Plugin::Fi::KohaSuomi::SelfService::Exception::OpeningHours;

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

use Exception::Class (
    'Koha::Plugin::Fi::KohaSuomi::SelfService::Exception::OpeningHours' => {
        isa => 'Koha::Plugin::Fi::KohaSuomi::SelfService::Exception',
        description => "Self-service resource closed at this time. Possibly outside opening hours or otherwise library has set this resource unavailable at this specific time. Try again alter. Attached time fields in ISO8601.",
        fields => ['startTime', 'endTime'],
    },
);

return 1;
