package Koha::Plugin::ISO18626::OpeningHours;

#Because this data structure has dynamic keys, OpenAPI2.0 cannot validate it.
#Spot-check some branches configuration
sub validate {
    my ($oh) = @_; #oh => openinghours-object
    my @err;

    my $i = 0;
    if (ref $oh eq 'HASH') {
        while (my ($k, $v) = each(%$oh)) {
            if ($k eq "") {
                push(@err, "Undefined branchcode!");
            }
            unless (ref $oh->{$k} eq 'ARRAY') {
                push(@err, "Branchcode '$k' weekdays are not an array?");
                next;
            }
            for my $wday (0,1,2,3,4,5,6) {
                unless (ref $oh->{$k}->[$wday] eq 'ARRAY') {
                    push(@err, "Branchcode '$k' weekday '$wday' is not an array?");
                }
                else {
                    unless ($oh->{$k}->[$wday]->[0] =~ /^\d\d:\d\d$/) {
                        push(@err, "Branchcode '$k' weekday '$wday' start time '".$oh->{$k}->[$wday]->[0]."' is not a time?");
                    }
                    unless ($oh->{$k}->[$wday]->[1] =~ /^\d\d:\d\d$/) {
                        push(@err, "Branchcode '$k' weekday '$wday' end time '".$oh->{$k}->[$wday]->[1]."' is not a time?");
                    }
                }
            }
            if ($i++ >= 2) {
                last;
            }
        }
    }
    else {
        push(@err, "Given OpeningHours-object '$oh' is not a HASH?");
    }
    return \@err if scalar(@err) > 0;
    return undef;
}

1;
