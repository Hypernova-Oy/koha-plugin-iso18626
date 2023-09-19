BEGIN {
    $ENV{KOHA_PLUGIN_DEV_MODE} = 1;
}

use Modern::Perl;
use Test::More tests => 3;
use DateTime;
use Try::Tiny;
use Scalar::Util qw(blessed);
use Koha::Logger;

use Koha::Plugin::ISO18626;
use Koha::Plugin::ISO18626::XML;
use Koha::Plugin::ISO18626::DAO::Request;
use Koha::Plugin::ISO18626::DAO::RequestConfirmation;

use t::Util qw(now tc);


my $schema  = Koha::Database->new->schema;
$schema->storage->txn_begin;

subtest 'Deserializing ISO18626 XML messages' => tc(sub {
    my $r = Koha::Plugin::ISO18626::DAO::Request->new();
    $r->header->supplyingAgencyId->agencyIdValue("Fi-NL")->agencyIdType(
        Koha::Plugin::ISO18626::DAO::OC::AgencyIdType->new->value("ISIL")->uri("http://illtransactions.org/ISO18626/OpenCodeList/AgencyIdTypeList-V2.0")
    );
    $r->bibliographicInfo->supplierUniqueRecordId(1337);

    my $xmlDoc = Koha::Plugin::ISO18626::XML::generateMessage($r);

    my $m = Koha::Plugin::ISO18626::XML::deserializeMessage($xmlDoc->toString(1));
    is($m->header->supplyingAgencyId->agencyIdType->uri, "http://illtransactions.org/ISO18626/OpenCodeList/AgencyIdTypeList-V2.0", "AgencyIdType->uri");
    is($m->header->supplyingAgencyId->agencyIdType->value, 'ISIL', "AgencyIdType->value");
    is($m->header->supplyingAgencyId->agencyIdValue, 'Fi-NL', "AgencyIdValue");
});
=head
subtest 'Opening hours happy path' => tc(sub {
    my $r = Koha::Plugin::ISO18626::DAO::Request->new();
    $r->header->supplyingAgencyId->agencyIdValue("Fi-NL")->agencyIdType(
        Koha::Plugin::ISO18626::DAO::OC::AgencyIdType->new->value("ISIL")->uri("http://illtransactions.org/ISO18626/OpenCodeList/AgencyIdTypeList-V2.0")
    );
    $r->bibliographicInfo->supplierUniqueRecordId(1337);

    my $xmlDoc = Koha::Plugin::ISO18626::XML::generateMessage($r);

    Koha::Plugin::ISO18626::XML::validateXML($xmlDoc);

    my $requestConfirmation = Koha::Plugin::ISO18626::DAO::RequestConfirmation->new();
    $requestConfirmation->header->messageStatus('OK')->supplyingAgencyId->agencyIdValue("Fi-NL")->agencyIdType(
        Koha::Plugin::ISO18626::DAO::OC::AgencyIdType->new->value("ISIL")->uri("http://illtransactions.org/ISO18626/OpenCodeList/AgencyIdTypeList-V2.0")
    );

    $xmlDoc = Koha::Plugin::ISO18626::XML::generateMessage($requestConfirmation);

    Koha::Plugin::ISO18626::XML::validateXML($xmlDoc); 
});

$schema->storage->txn_rollback;
