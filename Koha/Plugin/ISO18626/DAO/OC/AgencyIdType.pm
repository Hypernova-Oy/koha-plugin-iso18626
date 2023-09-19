package Koha::Plugin::ISO18626::DAO::OC::AgencyIdType;

use Modern::Perl;

use Koha::Exceptions;

our %METHODS;
use Koha::Plugin::ISO18626::DAO::Meta (
    uri => {validator => '_validateAgainstURI'},
    value => {validator => '_validateAgainstURI'},
);

my $openCodeLists = {
    "http://illtransactions.org/ISO18626/OpenCodeList/AgencyIdTypeList-V2.0" => {
        DNUCNI => 'Danish National Union Catalogue Non-ISIL Identifier - 20211217',
        ICOLC => 'https:// icolc .net/ consortia - 20211217',
        ISIL => 'ISO 15511 - 20211217',
    }
};

sub new {
    my ($class, $params) = @_;

    my $self = bless($params // {}, $class);

    return $self;
}

sub _validateAgainstURI {
    return $_[0] unless ($_[0]->{uri} && $_[0]->{value});
    Koha::Exceptions::BadParameter->throw(error => "AgencyIdType URI='".$_[0]->{uri}."' is unknown! TODO: Fetch external OpenCode lists.", self => $_[0]) unless ($openCodeLists->{$_[0]->{uri}});
    Koha::Exceptions::BadParameter->throw(error => "AgencyIdType Value='".$_[0]->{value}."' is not found in OpenCode list URI='".$_[0]->{uri}."'!", self => $_[0]) unless ($openCodeLists->{$_[0]->{uri}}->{$_[0]->{value}});
    return $_[0];
}

=head serializeXML
Prepare the XML Document for serialization

@PARAM1 XML::LibXML::Element
@RETURN @PARAM1
=cut
sub serializeXML {
    require XML::LibXML;
    my ($self, $e) = @_;

    my $agencyIdType = XML::LibXML::Element->new('agencyIdType');
    $e->appendChild($agencyIdType);

    my $uri = XML::LibXML::Element->new('uri');
    $agencyIdType->appendChild($uri);
    $uri->appendText($self->uri);

    my $value = XML::LibXML::Element->new('value');
    $agencyIdType->appendChild($value);
    $value->appendText($self->value);

#    $agencyIdType->setAttribute('schema', $self->uri);
#    $agencyIdType->appendText($self->value);

    return $e;
}

1;