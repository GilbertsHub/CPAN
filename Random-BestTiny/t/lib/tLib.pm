
use strict;

our @INC;

package tLib;

use POSIX ();
use File::Basename;
use File::Spec ();
use Data::Dumper ();

use Test::More;

use vars qw( $cwd0 $dirt0 $name0 $name00 $lib0 );
BEGIN
{
    $cwd0    = POSIX::getcwd();
    $dirt0   = File::Spec->rel2abs(dirname($0));
    $name0   = basename($0);
    ( $name00  = $name0 ) =~ s/\.\w+$//;
    $lib0    = File::Spec->rel2abs(File::Spec->catdir( dirname( $dirt0 ), 'lib' ));
    unshift @INC, $lib0;
}

use vars qw( $i0 $i1 $i2 );
BEGIN
{
    $i0 = "";
    $i1 = "  ";
    $i2 = "    ";
}

use vars qw( @EXPORT $VERSION @ISA );

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( $cwd0 $dirt0 $name0 $name00 $lib0
             $i0 $i1 $i2 );

sub new
{
     my $self = \do { use vars qw( *globx ); local *globx };

     

     bless $self, 'tLib';
}

sub DESTROY
{
    1;
}

# check values for randomness (very crude check)
sub ok_random
{
    my (
        $self,
        $valuesRef,
        $i99,
          ) = @_;

    my %distribution;

    foreach my $value ( @$valuesRef )
    {
        $distribution{$value} = 0 unless exists $distribution{$value};
        $distribution{$value}++;
    }

    my $percent = 0.10;                 #percentage (0.10 is 10%)
    my $limit = int(@$valuesRef * $percent); #no more than 10% accepted

    my @distribution = sort { $a <=> $b } keys %distribution;
    cmp_ok( scalar(@distribution), '>', $limit,
                "$i99 at least $limit distinct values" );

    my @overs;
    for ( my $d = 0; $d < @distribution; $d++ )
    {   #look for individual values that got too many hits
        my $dKey = $distribution[$d];
        if ($distribution{$dKey} >= $limit)
        {   #this one got too many
            push( @overs, $dKey );
        }
    }

    ok( @overs == 0,
                "$i99$i1 distribution check with $limit hit upper limit" ) or
        diag( Data::Dumper->Dump( [ \%distribution, \@overs  ] =>
                                  [ 'distribution',  'overs' ] ) );
    1;
}

1; #end
