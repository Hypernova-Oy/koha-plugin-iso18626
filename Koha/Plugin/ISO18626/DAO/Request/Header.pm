package Koha::Plugin::ISO18626::DAO::Request::Header;

use Modern::Perl;

our %METHODS;
use Koha::Plugin::ISO18626::DAO::Meta (
    supplyingAgencyId => {class => 'Koha::Plugin::ISO18626::DAO::CT::SupplyingAgencyId'},
);

use Koha::Plugin::ISO18626::DAO::CT::SupplyingAgencyId;

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

    return $e;
}

sub deserializeXML {
    my ($self, $r) = @_;

    unless ($r->localName eq 'header') {
        Koha::Exception::ISO18626::Schema::XML->throw(error => "Deserializing a Header, but the entry Node is not <header>", context => $self);
    }

    while (my $e = $r->nextElementOrEndAt('header')) {
        if (my $m = $METHODS{$e->localName}) {
            $self->${$e->localName}($m->{class}->new->deserializeXML($e));
        }
    }
    return $self;
}
1;