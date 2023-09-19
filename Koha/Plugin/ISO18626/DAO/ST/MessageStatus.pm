package Koha::Plugin::ISO18626::DAO::ST::MessageStatus;

=head MessageStatus

This package introduces a class attribute to be used when MessageStatus is needed in the data elements.

=cut

use Modern::Perl;

use Koha::Exceptions;

our $ALLOWED_VALUES = qr/^(?:OK|ERROR)$/i;

sub messageStatus {
    if ($_[1]) {
        $_[0]->{messageStatus} = $_[1];
        $_[0]->_validateMessageStatus;
        return $_[0];
    }
    return $_[0]->{messageStatus};
}

sub _validateMessageStatus {
    Koha::Exceptions::BadParameter->throw(error => "MessageStatus='".$_[0]->{messageStatus}."' is not 'OK' or 'ERROR'!", self => $_[0]) unless ($_[0]->{messageStatus} =~ $ALLOWED_VALUES);
}

sub serializeXML_MessageStatus {
    require XML::LibXML;
    my ($self, $e) = @_;

    Koha::Plugin::ISO18626::XMLSerializer::appendNodeToWithText('MessageStatus', $e, $self->messageStatus);

    return $e;
}
1;