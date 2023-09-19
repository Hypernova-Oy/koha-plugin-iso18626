package Koha::Plugin::ISO18626::DAO::Util;

use Modern::Perl;

use Koha::Plugin::ISO18626::Exceptions;

sub import {
    my ($selfClassName, @methods) = @_;
    my $targetClassName = caller;

    for (my $i=0 ; $i<@methods ; $i++) {
        my ($parameterAttributeName, $parameterAttributeClassName, $parameterValidatorFunctionName) = @{$methods[$i]};

        if      ($parameterAttributeName && $parameterAttributeClassName && $parameterValidatorFunctionName){
            metaprogram_setterGetterForClassAttributeWithValidator($targetClassName, $parameterAttributeName, $parameterAttributeClassName);
        } elsif ($parameterAttributeName && $parameterAttributeClassName && not($parameterValidatorFunctionName)) {
            metaprogram_setterGetterForClassAttribute($targetClassName, $parameterAttributeName, $parameterAttributeClassName);
        } elsif ($parameterAttributeName && not($parameterAttributeClassName) && $parameterValidatorFunctionName) {
            metaprogram_setterGetterForScalarAttributeWithValidator($targetClassName, $parameterAttributeName, $parameterValidatorFunctionName);
        } elsif ($parameterAttributeName && not($parameterAttributeClassName) && not($parameterValidatorFunctionName)) {
            metaprogram_setterGetterForScalarAttribute($targetClassName, $parameterAttributeName);
        }
    }
}

=head2 metaprogram_setterGetterForClassAttribute
@PARAM1 String, the class name of the target to create a method for
@PARAM2 String, The name of the attribute to create the setterGetter
@PARAM3 String, The name of the class of the expected parameter to the setterGetter
=cut
sub metaprogram_setterGetterForClassAttribute {
    my ($targetClassName, $parameterAttributeName, $parameterAttributeClassName) = @_;

    no strict 'refs';
    my $fullyQualifiedMethodName = "${targetClassName}::${parameterAttributeName}";
    *{ $fullyQualifiedMethodName } = sub {
        if ($_[1]) {
            if (ref($_[1]) eq $parameterAttributeClassName) {
                $_[0]->{$parameterAttributeName} = $_[1];
            } else {
                Koha::Exception::ISO18626::Schema::WrongType->throw(error => "Given parameter '".$_[1]."' to setter '$parameterAttributeName' is not of the expected class '$parameterAttributeClassName'!", self => $_[0]);
            }
            return $_[0];
        }
        $_[0]->{$parameterAttributeName} = $parameterAttributeClassName->new() unless ($_[0]->{$parameterAttributeName});
        return $_[0]->{$parameterAttributeName};
    };
}

sub metaprogram_setterGetterForScalarAttribute {
    my ($targetClassName, $parameterAttributeName) = @_;

    no strict 'refs';
    my $fullyQualifiedMethodName = "${targetClassName}::${parameterAttributeName}";
        *{ $fullyQualifiedMethodName } = sub {
        if ($_[1]) {
            $_[0]->{$parameterAttributeName} = $_[1];
            return $_[0];
        }
        return $_[0]->{$parameterAttributeName};
    };
}

sub metaprogram_setterGetterForScalarAttributeWithValidator {
    my ($targetClassName, $parameterAttributeName, $validatorFunction) = @_;

    no strict 'refs';
    my $fullyQualifiedMethodName = "${targetClassName}::${parameterAttributeName}";
        *{ $fullyQualifiedMethodName } = sub {
        if ($_[1]) {
            $_[0]->{$parameterAttributeName} = $_[1];
            $_[0]->$validatorFunction;
            return $_[0];
        }
        return $_[0]->{$parameterAttributeName};
    };
}

1;
