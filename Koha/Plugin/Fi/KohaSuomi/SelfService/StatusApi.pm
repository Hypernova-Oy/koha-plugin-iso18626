package Koha::Plugin::Fi::KohaSuomi::SelfService::StatusApi;

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
use utf8;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

use C4::Members;

use Scalar::Util qw( blessed );
use Try::Tiny;

use Koha::Plugin::Fi::KohaSuomi::SelfService::OpeningHours;
use Koha::Plugin::Fi::KohaSuomi::SelfService;
use Koha::Plugin::Fi::KohaSuomi::SelfService::BlockManager;
use Koha::Plugin::Fi::KohaSuomi::SelfService::Log;

use Koha::Exceptions::Patron;
use Koha::Exceptions::Library::NotFound;

=head2 borrower_ss_blocks -feature
=cut

sub ss_block_delete {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    my $payload;
    try {
        my $borrower_ss_block_id = $c->validation->param('borrower_ss_block_id');

        #If we didn't get any exceptions, we succeeded
        $payload = {};
        $payload->{deleted_count} = Koha::Plugin::Fi::KohaSuomi::SelfService::BlockManager::deleteBlock($borrower_ss_block_id);
        $payload->{deleted_count} = 0 if $payload->{deleted_count} == 0E0;

        return $c->render(status => 200, openapi => $payload);

    } catch {
        $logger->warn(toString($_)) if $logger->is_warn();
        if ( $_->isa('DBIx::Class::Exception') ) {
            return $c->render(
                status  => 500,
                openapi => { error => $_->{msg} }
            );
        }
        else {
            $logger->error($_);
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

sub ss_blocks_delete {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    my $payload;
    try {
        my $borrowernumber = $c->validation->param('borrowernumber');

        #If we didn't get any exceptions, we succeeded
        $payload = {};
        $payload->{deleted_count} = Koha::Plugin::Fi::KohaSuomi::SelfService::BlockManager::deleteBorrowersBlocks($borrowernumber);
        $payload->{deleted_count} = 0 if $payload->{deleted_count} == 0E0;

        return $c->render(status => 200, openapi => $payload);

    } catch {
        $logger->warn(toString($_)) if $logger->is_warn();
        if ( $_->isa('DBIx::Class::Exception') ) {
            return $c->render(
                status  => 500,
                openapi => { error => $_->{msg} }
            );
        }
        else {
            $logger->error($_);
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

sub ss_block_get {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    my $payload;
    try {
        my $borrowernumber       = $c->param('borrowernumber');
        my $borrower_ss_block_id = $c->validation->param('borrower_ss_block_id');

        #If we didn't get any exceptions, we succeeded
        my $block = Koha::Plugin::Fi::KohaSuomi::SelfService::BlockManager::getBlock($borrower_ss_block_id);
        return $c->render(status => 200, openapi => $block->swaggerize()) if $block;
        return $c->render(status => 404, openapi => {error => "No such self-service block"}) unless $block;

    } catch {
        $logger->warn(toString($_)) if $logger->is_warn();
        if ( $_->isa('DBIx::Class::Exception') ) {
            return $c->render(
                status  => 500,
                openapi => { error => $_->{msg} }
            );
        }
        else {
            $logger->error($_);
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

sub ss_block_has {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    my $payload;
    try {
        my $borrowernumber = $c->param('borrowernumber');
        my $branchcode = $c->validation->param('branchcode') || $c->stash('koha.user')->branchcode;

        #If we didn't get any exceptions, we succeeded
        my $block = Koha::Plugin::Fi::KohaSuomi::SelfService::BlockManager::hasBlock($borrowernumber, $branchcode);
        return $c->render(status => 200, openapi => $block->swaggerize()) if $block;
        return $c->render(status => 204, openapi => {}) unless $block;

    } catch {
        $logger->warn(toString($_)) if $logger->is_warn();
        if ( $_->isa('DBIx::Class::Exception') ) {
            return $c->render(
                status  => 500,
                openapi => { error => $_->{msg} }
            );
        }
        else {
            $logger->error($_);
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

sub ss_blocks_list {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    try {
        my $borrowernumber = $c->validation->param('borrowernumber');

        #If we didn't get any exceptions, we succeeded
        my $blocks = Koha::Plugin::Fi::KohaSuomi::SelfService::BlockManager::listBlocks($borrowernumber, DateTime->now(time_zone => C4::Context->tz()));
        if ($blocks && @$blocks) {
            @$blocks = map {$_->swaggerize()} @$blocks;
            return $c->render(status => 200, openapi => $blocks);
        }
        return $c->render( status => 404, openapi => { error => "No self-service blocks" } );

    } catch {
        $logger->warn(toString($_)) if $logger->is_warn();
        if ( $_->isa('DBIx::Class::Exception') ) {
            return $c->render(
                status  => 500,
                openapi => { error => $_->{msg} }
            );
        }
        else {
            $logger->error($_);
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

sub ss_blocks_post {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    try {
        my $borrowernumber       = $c->validation->param('borrowernumber');
        my $block = $c->validation->param('borrower_ss_block');
        $block->{borrowernumber} = $borrowernumber if $borrowernumber;
        $block->{created_by} = $c->stash('koha.user')->borrowernumber;

        #If we didn't get any exceptions, we succeeded
        $block = Koha::Plugin::Fi::KohaSuomi::SelfService::BlockManager::createBlock($block);
        Koha::Plugin::Fi::KohaSuomi::SelfService::BlockManager::storeBlock($block);
        return $c->render(status => 200, openapi => $block->swaggerize());

    } catch {
        $logger->warn(toString($_)) if $logger->is_warn();
        if ( $_->isa('DBIx::Class::Exception') ) {
            return $c->render(
                status  => 500,
                openapi => { error => $_->{msg} }
            );
        }
        elsif (blessed($_) && $_->isa('Koha::Exceptions::Patron')) {
            return $c->render( status => 404, openapi => { error => "$_" } );
        }
        elsif (blessed($_) && $_->isa('Koha::Exceptions::Library::NotFound')) {
            return $c->render( status => 404, openapi => { error => "$_" } );
        }
        else {
            $logger->error($_);
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

sub ss_blocks_put {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    try {
        my $borrowernumber       = $c->validation->param('borrowernumber');
        my $borrower_ss_block_id = $c->validation->param('borrower_ss_block_id');
        my $block = $c->validation->param('borrower_ss_block');
        $block->{borrowernumber} = $borrowernumber if $borrowernumber;
        $block->{borrower_ss_block_id} = $borrower_ss_block_id if $borrower_ss_block_id;

        #If we didn't get any exceptions, we succeeded
        $block = Koha::Plugin::Fi::KohaSuomi::SelfService::BlockManager::storeBlock($block);
        return $c->render(status => 200, openapi => $block);

    } catch {
        $logger->warn(toString($_)) if $logger->is_warn();
        if ( $_->isa('DBIx::Class::Exception') ) {
            return $c->render(
                status  => 500,
                openapi => { error => $_->{msg} }
            );
        }
        if (blessed($_) && $_->isa('Koha::Exceptions::Patron')) {
            return $c->render( status => 404, openapi => { error => "$_" } );
        }
        elsif (blessed($_) && $_->isa('Koha::Exceptions::Library::NotFound')) {
            return $c->render( status => 404, openapi => { error => "$_" } );
        }
        else {
            $logger->error($_);
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

########################################################################################################################

sub status {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    my $username = $c->validation->param('uname');
    my $password = $c->validation->param('passwd');
    my ($borrower, $error);
    return try {

        my ($status, $cardnumber, $userid) = C4::Auth::checkpw_internal(
                $username,
                $password
        );
        Koha::Exceptions::Password::Invalid->throw(
            error => 'Wrong username or password'
        ) unless $status;

        my $kp = GetMember(userid=>$userid);
        my $flags = C4::Members::patronflags( $kp );
        my $fines_amount = $flags->{CHARGES}->{amount};
        $fines_amount = ($fines_amount and $fines_amount > 0) ? $fines_amount : 0;
        my $fee_limit = C4::Context->preference('noissuescharge') || 5;
        my $fine_blocked = $fines_amount > $fee_limit;
        my $card_lost = $kp->{lost} || $kp->{gonenoaddress} || $flags->{LOST};
        my $basic_privileges_ok = !$borrower->is_debarred && !$borrower->is_expired && !$fine_blocked;

        for (qw(EXPIRED CHARGES CREDITS GNA LOST DBARRED NOTES)) {
                ($flags->{$_}) or next;
                if ($flags->{$_}->{noissues}) {
                        $basic_privileges_ok = 0;
                }
        }

        my $payload = {
            borrowernumber => 0+$borrower->borrowernumber,
            cardnumber     => $borrower->cardnumber || '',
            surname        => $borrower->surname || '',
            firstname      => $borrower->firstname || '',
            homebranch     => $borrower->branchcode || '',
            age            => $borrower->get_age || '',
            fines          => $fines_amount+0,
            language       => 'fin' || '',
            charge_privileges_denied    => _bool(!$basic_privileges_ok),
            renewal_privileges_denied   => _bool(!$basic_privileges_ok),
            recall_privileges_denied    => _bool(!$basic_privileges_ok),
            hold_privileges_denied      => _bool(!$basic_privileges_ok),
            card_reported_lost          => _bool($card_lost),
            too_many_items_charged      => _bool(0),
            too_many_items_overdue      => _bool(0),
            too_many_renewals           => _bool(0),
            too_many_claims_of_items_returned => _bool(0),
            too_many_items_lost         => _bool(0),
            excessive_outstanding_fines => _bool($fine_blocked),
            recall_overdue              => _bool(0),
            too_many_items_billed       => _bool(0),
        };
        return $c->render( status => 200, openapi => $payload );
    } catch {
        if (blessed($_)){
            if ($_->isa('Koha::Exceptions::Password::Invalid')) {
                return $c->render( status => 400, openapi => { error => $_->error } );
            }
            elsif ( $_->isa('DBIx::Class::Exception') ) {
                return $c->render(
                    status  => 500,
                    openapi => { error => $_->{msg} }
                );
            }
            else {
                $logger->error($_);
                return $c->render(
                    status  => 500,
                    openapi => { error => "Something went wrong, check the logs." }
                );
            }
        }
        else {
            $logger->error($_);
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

sub get_self_service_status {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    my $payload;
    try {
        #This is the Koha-way :(
        my $patron = Koha::Patrons->find({cardnumber => $c->validation->param('cardnumber')});
        $patron = Koha::Patrons->find({userid => $c->validation->param('cardnumber')}) unless $patron;
        Koha::Exceptions::Patron->throw(error => "No Patron with the given cardnumber '".$c->validation->param('cardnumber')."' found.") unless $patron;

        my $branchcode = $c->validation->param('branchcode') || $c->stash('koha.user')->branchcode;
        my $library = Koha::Libraries->find({branchcode => $branchcode});
        Koha::Exceptions::Library::NotFound->throw(error => "No Library with branchcode '$branchcode' found.") unless $library;

        Koha::Plugin::Fi::KohaSuomi::SelfService::CheckSelfServicePermission($patron, $branchcode, 'accessMainDoor');
        #If we didn't get any exceptions, we succeeded
        $payload = {permission => Mojo::JSON->true};
        return $c->render(status => 200, openapi => $payload);

    } catch {
        if (not(blessed($_) && $_->can('rethrow'))) {
            return $c->render( status => 500, openapi => { error => "$_" } );
        }
        elsif (blessed($_) && $_->isa('Koha::Exceptions::Patron')) {
            return $c->render( status => 404, openapi => { error => "$_" } );
        }
        elsif (blessed($_) && $_->isa('Koha::Exceptions::Library::NotFound')) {
            return $c->render( status => 404, openapi => { error => "$_" } );
        }
        elsif ($_->isa('Koha::Plugin::Fi::KohaSuomi::SelfService::Exception::OpeningHours')) {
            $payload = {
                permission => Mojo::JSON->false,
                error => ref($_),
                startTime => $_->startTime,
                endTime => $_->endTime,
            };
            return $c->render( status => 200, openapi => $payload );
        }
        elsif ($_->isa('Koha::Plugin::Fi::KohaSuomi::SelfService::Exception::PermissionRevoked')) {
            $payload = {
                permission     => Mojo::JSON->false,
                error          => ref($_),
            };
            $payload->{expirationdate} = $_->{expirationdate} if $_->{expirationdate};
            return $c->render( status => 200, openapi => $payload );
        }
        elsif ($_->isa('Koha::Plugin::Fi::KohaSuomi::SelfService::Exception')) {
            $payload = {
                permission => Mojo::JSON->false,
                error => ref($_),
            };
            return $c->render( status => 200, openapi => $payload );
        }
        elsif ($_->isa('Koha::Plugin::Fi::KohaSuomi::SelfService::Exception::FeatureUnavailable')) {
            return $c->render( status => 501, openapi => { error => "$_" } );
        }
        else {
            $logger->error($_);
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

sub list_openingHours {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    my $payload;
    try {
        my $openinghours = YAML::XS::Load( C4::Context->preference('OpeningHours') );
        my $err = Koha::Plugin::Fi::KohaSuomi::SelfService::OpeningHours::validate($openinghours);

        if ($err) {
            my $error = join("\n", @$err);
            $logger->error("Validating the OpeningHours-syspref failed. Use the plugin's configuration tool to fix errors.\n".$error);
            $openinghours->{error} = $error;
            $payload = $openinghours;
            return $c->render(status => 501, openapi => $payload);
        }
        else {
            $payload = $openinghours;
            return $c->render(status => 200, openapi => $payload);
        }
    } catch {
        if (not(blessed($_) && $_->can('rethrow'))) {
            $logger->error($_);
            return $c->render( status => 500, openapi => { error => "$_" } );
        }
        else {
            $logger->error($_);
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

sub get_openingHours {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    my $payload;
    try {
        if ($c->stash('koha.user') && $c->stash('koha.user')->branchcode) {
            my $branchcode = $c->stash('koha.user')->branchcode;
            my $openinghours = YAML::XS::Load( C4::Context->preference('OpeningHours') );
            my $err = Koha::Plugin::Fi::KohaSuomi::SelfService::OpeningHours::validate($openinghours);

            if ($err) {
                my $error = join("\n", @$err);
                $logger->error("Validating the OpeningHours-syspref failed. Use the plugin's configuration tool to fix errors.\n".$error);
                $openinghours->{error} = $error;
                $payload = $openinghours;
                return $c->render(status => 501, openapi => $payload);
            }
            else {
                $payload = $openinghours->{$branchcode};
                if ($payload) {
                    return $c->render(status => 200, openapi => $payload);
                }
                else {
                    return $c->render(status => 404, openapi => {error => "No opening hours defined for branch '$branchcode'"});
                }
            }
        }
        else {
            $payload = {error => "API user must be authenticated to get the Library whose opening hours are needed."};
            return $c->render(status => 401, openapi => $payload);
        }
    } catch {
        if (not(blessed($_) && $_->can('rethrow'))) {
            $logger->error($_);
            return $c->render( status => 500, openapi => { error => "$_" } );
        }
        else {
            $logger->error($_);
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

sub _bool {
    return $_[0] ? Mojo::JSON->true : Mojo::JSON->false;
}

1;
