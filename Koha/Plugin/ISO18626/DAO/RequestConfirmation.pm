package Koha::Plugin::ISO18626::DAO::RequestConfirmation;

use Modern::Perl;

use Koha::Plugin::ISO18626::DAO::Util (
    ['header', 'Koha::Plugin::ISO18626::DAO::RequestConfirmation::Header'],
);

use Koha::Plugin::ISO18626::DAO::RequestConfirmation::Header;

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

    my $request = XML::LibXML::Element->new('requestConfirmation');
    $e->appendChild($request);

    $self->header->serializeXML($request);

    return $e;
}
1;