package Koha::Plugin::ISO18626::DAO::Request::BibliographicInfo;

use Modern::Perl;

use Koha::Plugin::ISO18626::DAO::Util (
    ['supplierUniqueRecordId'],
);

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

    my $bibliographicInfo = XML::LibXML::Element->new('bibliographicInfo');
    $e->appendChild($bibliographicInfo);

    my $supplierUniqueRecordId = XML::LibXML::Element->new('supplierUniqueRecordId');
    $bibliographicInfo->appendChild($supplierUniqueRecordId);
    $supplierUniqueRecordId->appendText($self->supplierUniqueRecordId);

    return $e;
}
1;