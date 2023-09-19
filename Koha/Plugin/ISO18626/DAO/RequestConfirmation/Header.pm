package Koha::Plugin::ISO18626::DAO::RequestConfirmation::Header;

use Modern::Perl;

use Koha::Plugin::ISO18626::DAO::Util (
    ['supplyingAgencyId', 'Koha::Plugin::ISO18626::DAO::CT::SupplyingAgencyId'],
);

use Koha::Plugin::ISO18626::DAO::CT::SupplyingAgencyId;

use base qw(Koha::Plugin::ISO18626::DAO::ST::MessageStatus);

sub new {
    my ($class, $params) = @_;

    my $self = bless($params // {}, $class);

    return $self;
}

=head serializeXML
Prepare the XML Document for serialization

@PARAM1 XML::LibXML::Element
@RETURN @PARAM1
=cut
sub serializeXML {
    require XML::LibXML;
    my ($self, $e) = @_;

    my $header = XML::LibXML::Element->new('header');
    $e->appendChild($header);

    $self->supplyingAgencyId->serializeXML($header);

    $self->serializeXML_MessageStatus($e);

    return $e;
}
1;