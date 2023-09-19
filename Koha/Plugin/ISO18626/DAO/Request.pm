package Koha::Plugin::ISO18626::DAO::Request;

use Modern::Perl;

our %METHODS;
use Koha::Plugin::ISO18626::DAO::Meta (
    header => {class => 'Koha::Plugin::ISO18626::DAO::Request::Header'},
    bibliographicInfo => {class => 'Koha::Plugin::ISO18626::DAO::Request::BibliographicInfo'},
);

use Koha::Plugin::ISO18626::DAO::Request::BibliographicInfo;
use Koha::Plugin::ISO18626::DAO::Request::Header;

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

    my $request = XML::LibXML::Element->new('request');
    $e->appendChild($request);

    $self->header->serializeXML($request);
    $self->bibliographicInfo->serializeXML($request);

    return $e;
}

1;