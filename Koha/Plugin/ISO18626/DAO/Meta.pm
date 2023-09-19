package Koha::Plugin::ISO18626::DAO::Meta;

use Modern::Perl;

use Koha::Plugin::ISO18626::Exceptions;

sub import {
    my ($selfClassName, %methods) = @_;
    my $targetClassName = caller;

    while (my ($parameterAttributeName, $config) = each(%methods)) {
        metaprogram_setterGetter($targetClassName, $parameterAttributeName, $config->{class}, $config->{validator});
    }

    no strict 'refs';
    %{"${targetClassName}::METHODS"} = %methods;
}

sub metaprogram_setterGetter {
    my ($targetClassName, $parameterAttributeName, $parameterAttributeClassName, $parameterValidatorFunction) = @_;
    my $fullyQualifiedMethodName = "${targetClassName}::${parameterAttributeName}";

    my $code =
        "*{$fullyQualifiedMethodName} = sub {\n".
        "    if (\$_[1]) {\n";

    if ($parameterAttributeClassName) {
        $code .=
        "        if (ref(\$_[1]) eq '$parameterAttributeClassName') {\n".
        "            \$_[0]->{$parameterAttributeName} = \$_[1];\n".
        "        } else {\n".
        "            Koha::Exception::ISO18626::Schema::WrongType->throw(error => \"Given parameter '\$_[1]' to setter '$parameterAttributeName' is not of the expected class '$parameterAttributeClassName'!\", self => \$_[0]);\n".
        "        }\n";
    }
    else {
        $code .=
        "        \$_[0]->{$parameterAttributeName} = \$_[1];\n".
        ($parameterValidatorFunction ? 
        "        \$_[0]->$parameterValidatorFunction;\n" : "");
    }
    $code .=
        "        return \$_[0];\n".
        "    }\n".
        ($parameterAttributeClassName ?
        "    \$_[0]->{$parameterAttributeName} = $parameterAttributeClassName->new() unless (\$_[0]->{$parameterAttributeName});\n" : "" ).

        "    return \$_[0]->{$parameterAttributeName};\n".
        "};\n";
    #print "$code";
    eval $code or die;
}

sub deserializeXML {
    no strict 'refs';
    my ($dao, $expectedElementName, $r) = @_;
    my $METHODS = \%{ref($dao).'::METHODS'};

    unless ($r->localName eq $expectedElementName) {
        Koha::Exception::ISO18626::Schema::XML->throw(error => "Deserializing a ISO18626Message XML, but the entry Node is not <$expectedElementName>", context => $dao);
    }

    while (my $e = $r->nextElementOrTextOrEndAt($expectedElementName)) {
        if (my $m = $METHODS->{$e->localName}) {
            my $accessor = $e->localName;
            if ($m->{class}) {
                my $className = $m->{class};
                $dao->$accessor(deserializeXML($className->new, $accessor, $e));
            } else {
                $e->nextTextOrDie;
                $dao->$accessor($e->value);
            }
        }
    }
    return $dao;
}

1;
