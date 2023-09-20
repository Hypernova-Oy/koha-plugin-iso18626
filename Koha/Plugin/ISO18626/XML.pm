package Koha::Plugin::ISO18626::XML;

use Koha::Plugin::ISO18626::XML::Deserializer;

use Koha::Plugin::ISO18626::DAO::Request;
use Koha::Plugin::ISO18626::DAO::RequestConfirmation;

our $DEFAULT_SCHEMA_VERSION = '2021-2'; #ISO 18626:2021 (June 2022 update) http://illtransactions.org/schemas/ISO-18626-2021-2.xsd

sub defaultSchemaVersion {
    return $DEFAULT_SCHEMA_VERSION;
}

sub deserializeMessage {
    my ($xmlText, $schemaVersion) = @_;
    $schemaVersion = Koha::Plugin::ISO18626::XML::defaultSchemaVersion() unless $schemaVersion;

    my $r = Koha::Plugin::ISO18626::XML::Deserializer->new(string => $xmlText);

    $r->_preparePointer;

    $r->nextElementOrTextOrEndAt('ISO18626Message');
    if      ($r->localName eq 'request') {
        return Koha::Plugin::ISO18626::DAO::Meta::deserializeXML(Koha::Plugin::ISO18626::DAO::Request->new, 'request', $r);
    } elsif ($r->localName eq 'requestConfirmation') {
        return Koha::Plugin::ISO18626::DAO::RequestConfirmation->new->deserializeXML($r);
    }
    Koha::Exception::ISO18626::Schema::XML->throw(error => "Unable to determine the ISO18626Message type (request, supplyingAgencyMessage, ...)");
}

sub serializeMessage {
    my ($r, $schemaVersion) = @_;
    $schemaVersion = Koha::Plugin::ISO18626::XML::defaultSchemaVersion() unless $schemaVersion;

    my $doc = XML::LibXML::Document->new('1.0','UTF-8');
    my $root = $doc->createElement('ISO18626Message');
    $doc->setDocumentElement($root);

    $r->serializeXML($root);

    print $doc->toString(1);

    return $doc;
}

sub validateXML {
    my ($doc, $schemaVersion) = @_;

    my $xmlSchema = XML::LibXML::Schema->new(location => _getSchemaFile($schemaVersion), no_network => 1);

    eval {
        $xmlSchema->validate( $doc );
    };
    print $@ if ($@);
}

sub appendNodeToWithText {
    my ($nodeName, $parentElement, $text) = @_;
    my $e = XML::LibXML::Element->new($nodeName);
    $parentElement->appendChild($e);
    $e->appendText($text) if $text;
    return $e;
}

sub _getSchemaFile {
    my ($schemaVersion) = @_;
    $schemaVersion = $DEFAULT_SCHEMA_VERSION unless $schemaVersion;

    my $schemaFilePath = __FILE__."/../schema/ISO-18626-$schemaVersion.xsd";
    my $schemaFilePathReal = Cwd::realpath($schemaFilePath);
    unless (-e $schemaFilePathReal) { #This returns undef if file doesn't exist. #TODO: Accessing downloadable files on disk is an antipattern. Store them in DB or other cloud-native object store.
        Koha::Exceptions::FileNotFound->throw("ISO18626 schema file '$schemaFilePath' not found for the requested schema version '$schemaVersion'");
    }
    return $schemaFilePathReal;
}

1;