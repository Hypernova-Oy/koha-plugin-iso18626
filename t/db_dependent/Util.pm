package t::db_dependent::Util;

use Modern::Perl;

use Exporter;
our @ISA = qw(Exporter);
# Exporting the add and subtract routine
our @EXPORT = qw(build_patron);


#my $builder = t::lib::TestBuilder->new;
#$t::db_dependent::Util::builder = $builder;
our $builder;


sub build_patron {
    my ($params) = @_;

    my $flag = $params->{flags} ? 2 ** $params->{flags} : undef;
    my $patron = $builder->build_object(
        {
            class => 'Koha::Patrons',
            value => {
                gonenoaddress   => 0,
                lost            => 0,
                debarred        => undef,
                debarredcomment => undef,
                dateofbirth     => '2000-01-01',
                branchcode => $params->{branchcode} || 'FPL',
                flags => $flag
            }
        }
    );
    my $password = 'thePassword123';
    $patron->set_password( { password => $password, skip_validation => 1 } );
    $patron->userid('u' . $patron->borrowernumber)->store;
    my $userid = $patron->userid;

    foreach my $permission (@{$params->{permissions}}) {
        my $dbh   = C4::Context->dbh;
        $dbh->do( "
            INSERT INTO user_permissions (borrowernumber,module_bit,code)
            VALUES (?,?,?)", undef,
            $patron->borrowernumber,
            $permission->{module},
            $permission->{subpermission}
        );
    }

    return ($patron, "//$userid:$password@", $password);
}

#Mock the directory Koha looks for plugins to be this Plugin's dev source code dir
sub MockPluginsdir {
    $C4::Context::context->{config}->{config}->{pluginsdir} = Cwd::abs_path(File::Spec->catfile(__FILE__,'..','..','..'));
}

1;
