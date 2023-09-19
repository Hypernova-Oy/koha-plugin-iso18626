package Koha::Plugin::ISO18626::XML::Deserializer;

use Modern::Perl;

use XML::LibXML::Reader;
use base qw(XML::LibXML::Reader);

my %type_name = (
    &XML_READER_TYPE_ELEMENT                 => 'ELEMENT',
    &XML_READER_TYPE_ATTRIBUTE               => 'ATTRIBUTE',
    &XML_READER_TYPE_TEXT                    => 'TEXT',
    &XML_READER_TYPE_CDATA                   => 'CDATA',
    &XML_READER_TYPE_ENTITY_REFERENCE        => 'ENTITY_REFERENCE',
    &XML_READER_TYPE_ENTITY                  => 'ENTITY',
    &XML_READER_TYPE_PROCESSING_INSTRUCTION  => 'PROCESSING_INSTRUCTION',
    &XML_READER_TYPE_COMMENT                 => 'COMMENT',
    &XML_READER_TYPE_DOCUMENT                => 'DOCUMENT',
    &XML_READER_TYPE_DOCUMENT_TYPE           => 'DOCUMENT_TYPE',
    &XML_READER_TYPE_DOCUMENT_FRAGMENT       => 'DOCUMENT_FRAGMENT',
    &XML_READER_TYPE_NOTATION                => 'NOTATION',
    &XML_READER_TYPE_WHITESPACE              => 'WHITESPACE',
    &XML_READER_TYPE_SIGNIFICANT_WHITESPACE  => 'SIGNIFICANT_WHITESPACE',
    &XML_READER_TYPE_END_ELEMENT             => 'END_ELEMENT',
);

sub nextElementOrTextOrEndAt {
    my ($self, $endAtThisNamedElement) = @_;

    my $rv;
    while($rv = $self->read) {
        $self->_debug;
        if ($self->nodeType == XML_READER_TYPE_ELEMENT || $self->nodeType == XML_READER_TYPE_TEXT) {
            return $self;
        }
        if ($self->nodeType == XML_READER_TYPE_END_ELEMENT && $self->localName eq $endAtThisNamedElement) {
            return undef;
        }
    }

    Koha::Exception::ISO18626::Schema::XML->throw(error => "Unable to find a new element or an end element before the end element '$endAtThisNamedElement'. ".(($rv == 0) ? "Reader ran out of Nodes." : "Reader error."));
}

sub nextTextOrDie {
    my ($self) = @_;

    my $rv;
    while($rv = $self->read) {
        $self->_debug;
        if ($self->nodeType == XML_READER_TYPE_ELEMENT || $self->nodeType == XML_READER_TYPE_END_ELEMENT) {
            Koha::Exception::ISO18626::Schema::XML->throw(error => "Instead of a text node found a '".$type_name{$self->nodeType}."'");
        }
        if ($self->nodeType == XML_READER_TYPE_TEXT) {
            return $self;
        }
    }

    Koha::Exception::ISO18626::Schema::XML->throw(error => "Unable to find a text node. ".(($rv == 0) ? "Reader ran out of Nodes." : "Reader error."));
}

sub _preparePointer {
    $_[0]->nextElementOrTextOrEndAt('ISO18626Message');
    unless ($_[0]->localName eq 'ISO18626Message') {
        Koha::Exception::ISO18626::Schema::XML->throw("First element of the received XML message is not <ISO18626>");
    }
}

my $step = 0;
sub _debug {
    printf(
        " %3u  | %-22s  | %4u  | %s\n",
        $step++,
        $type_name{$_[0]->nodeType},
        $_[0]->depth,
        $_[0]->name
    );
}
1;