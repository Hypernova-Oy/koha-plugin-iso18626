package Koha::Plugin::ISO18626::DAO::CT::AgencyId;

use Modern::Perl;

use Koha::Plugin::ISO18626::XML;

our %METHODS;
use Koha::Plugin::ISO18626::DAO::Meta (
    agencyIdType => {class => 'Koha::Plugin::ISO18626::DAO::OC::AgencyIdType'},
    agencyIdValue => {},
);

use Koha::Plugin::ISO18626::DAO::OC::AgencyIdType;

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

    my $supplyingAgencyId = XML::LibXML::Element->new('supplyingAgencyId');
    $e->appendChild($supplyingAgencyId);

    $self->agencyIdType->serializeXML($supplyingAgencyId);

    Koha::Plugin::ISO18626::XML::appendNodeToWithText('agencyIdValue', $supplyingAgencyId, $self->agencyIdValue);

    return $e;
}

sub deserializeXML {
    my ($self, $r) = @_;

    unless ($r->localName eq 'supplyingAgencyId') {
        Koha::Exception::ISO18626::Schema::XML->throw(error => "Deserializing a Request, but the entry Node is not <supplyingAgencyId>", context => $self);
    }

    while (my $e = $r->nextElementOrEndAt('supplyingAgencyId')) {
        if (my $m = $METHODS{$e->localName}) {
            no strict 'refs';
            my $accessor = $e->localName;
            if ($m->{class}) {
                my $className = $m->{class};
                $self->$accessor($className->new->deserializeXML($e));
            } else {
                $r->nextTextOrDie;
                $self->$accessor($e->value);
            }
        }
    }
    return $self;
}
1;