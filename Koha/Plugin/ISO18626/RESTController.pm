package Koha::Plugin::ISO18626::RESTController;

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

use Scalar::Util qw( blessed );
use Try::Tiny;

use Koha::Plugin::ISO18626::Log;
use Koha::Plugin::ISO18626::XMLSerializer;

sub iso18626 {
    my $logger = Koha::Logger->get();
    my ($c) = @_;

    try {
        Koha::Plugin::ISO18626::XMLSerializer::

        return $c->render(status => 200, format => 'xml', text => '<ehlo/>');

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

1;





































=head2 borrower_ss_blocks -feature


sub ss_block_delete {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    my $payload;
    try {
        my $borrower_ss_block_id = $c->validation->param('borrower_ss_block_id');

        #If we didn't get any exceptions, we succeeded
        $payload = {};
        $payload->{deleted_count} = Koha::Plugin::ISO18626::BlockManager::deleteBlock($borrower_ss_block_id);
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
        $payload->{deleted_count} = Koha::Plugin::ISO18626::BlockManager::deleteBorrowersBlocks($borrowernumber);
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
        my $block = Koha::Plugin::ISO18626::BlockManager::getBlock($borrower_ss_block_id);
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
        my $block = Koha::Plugin::ISO18626::BlockManager::hasBlock($borrowernumber, $branchcode);
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
        my $blocks = Koha::Plugin::ISO18626::BlockManager::listBlocks($borrowernumber, DateTime->now(time_zone => C4::Context->tz()));
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
        $block = Koha::Plugin::ISO18626::BlockManager::createBlock($block);
        Koha::Plugin::ISO18626::BlockManager::storeBlock($block);
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
        $block = Koha::Plugin::ISO18626::BlockManager::storeBlock($block);
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

        Koha::Plugin::ISO18626::CheckSelfServicePermission($patron, $branchcode, 'accessMainDoor');
        #If we didn't get any exceptions, we succeeded
        $payload = {permission => Mojo::JSON->true};
        return $c->render(status => 200, openapi => $payload);

    } catch {
        if (not(blessed($_) && $_->can('rethrow'))) {
            $logger->error($_);
            return $c->render( status => 500, openapi => { error => "$_" } );
        }
        elsif (blessed($_) && $_->isa('Koha::Exceptions::Patron')) {
            return $c->render( status => 404, openapi => { error => "$_" } );
        }
        elsif (blessed($_) && $_->isa('Koha::Exceptions::Library::NotFound')) {
            return $c->render( status => 404, openapi => { error => "$_" } );
        }
        elsif ($_->isa('Koha::Exception::SelfService::OpeningHours')) {
            $payload = {
                permission => Mojo::JSON->false,
                error => ref($_),
                startTime => $_->startTime,
                endTime => $_->endTime,
            };
            return $c->render( status => 200, openapi => $payload );
        }
        elsif ($_->isa('Koha::Exception::SelfService::PermissionRevoked')) {
            $payload = {
                permission     => Mojo::JSON->false,
                error          => ref($_),
            };
            $payload->{expirationdate} = $_->{expirationdate} if $_->{expirationdate};
            return $c->render( status => 200, openapi => $payload );
        }
        elsif ($_->isa('Koha::Exception::SelfService::FeatureUnavailable')) {
            $logger->error($_);
            return $c->render( status => 501, openapi => { error => "$_" } );
        }
        elsif ($_->isa('Koha::Exception::SelfService')) {
            $payload = {
                permission => Mojo::JSON->false,
                error => ref($_),
            };
            return $c->render( status => 200, openapi => $payload );
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
        my $err = Koha::Plugin::ISO18626::OpeningHours::validate($openinghours);

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
            my $err = Koha::Plugin::ISO18626::OpeningHours::validate($openinghours);

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

sub get_PINCheck {
    my $logger = Koha::Logger->get();
    my $c = shift->openapi->valid_input or return;

    my $payload;
    try {
        my $cardnumber = $c->validation->param('body')->{cardnumber};
        my $sth = C4::Context->dbh()->prepare("SELECT password FROM borrowers WHERE userid = ? OR cardnumber = ?");
        $sth->execute($cardnumber, $cardnumber);
        my ($storedPasswordHash) = $sth->fetchrow();

        unless ($storedPasswordHash) {
            $payload = {error => "No user for cardnumber '$cardnumber'"};
            return $c->render(status => 404, openapi => $payload);
        }

        if (C4::Auth::checkpw_hash($c->validation->param('body')->{password}, $storedPasswordHash)) {
            $payload = {permission => Mojo::JSON->true};
        }
        else {
            $payload = {
                permission => Mojo::JSON->false,
                error => "Wrong password."
            };
        }
        return $c->render(status => 200, openapi => $payload);
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
