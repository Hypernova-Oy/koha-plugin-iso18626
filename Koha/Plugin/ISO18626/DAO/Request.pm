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

sub storeDBIx {
    require Koha::Schema::Result::Illrequest;
    require Koha::Database;
    my ($self) = @_;
    my $schema = Koha::Database->schema();
    my $rs = $schema->resultset('Koha::Schema::Result::Illrequest')->create({
        borrowernumber => 1,
        biblio_id => 2,
        deleted_biblio_id => undef,
        due_date => '2023-05-05',
        branchcode => 'CPL',
        status => '...',
        status_alias => '...', #FK to authorised_values
        placed => '2023-04-31',
        replied => '2023-05-01',
        updated => '2023-05-05T12:33:22',
        completed => '2023-06-06',
        medium => 'BK',
        accessurl => 'http:/example.com/download?book',
        cost => 50,
        price_paid => 40,
        notesopac => 'ehlo',
        notesstaff => 'helloworld',
        orderid => 55,
        backend => 'iso18626',
    });
}

1;