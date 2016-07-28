
use strict;

use POSIX ();
use File::Basename;
use File::Spec;
use Data::Dumper ();

use vars qw($cwd0 $dirt0 $name0 $name00 $lib0 );
use vars qw($i0 $i1 $i2);
BEGIN
{
    my $tLibDir =  
       File::Spec->catdir( File::Spec->rel2abs( dirname($0) ), 'lib' );
    unshift @INC, $tLibDir;
    require tLib;
    import  tLib;
}

my $t = tLib->new();

use Test::More tests => 11;

    #
    #  PRELIMINARY TESTS
    #
{
    my $lib = File::Spec->catdir( $cwd0, "lib" );
    my $w = "w";
    my $cmd = qq(perl -c$w "-I$lib" -MRandom::BestTiny -e 1);
    ok( !system($cmd), "$i0 lint Random::BestTiny" ) || BAIL_OUT;

    my $path = File::Spec->catfile( $cwd0, "lib", "Random", "BestTiny.pm" );
    require_ok( $path ) || BAIL_OUT();
}

    #
    #   SIMPLE TEST
{   #
    my $best = Random::BestTiny->new();

    ok($best, "$i0 Random::BestTiny->new()" ) || BAIL_OUT();

    my $q = $best->quality();
    cmp_ok( $q, '==', 0, "$i1 quality is false" );

    my $bits_per_byte = $best->bits_per_byte();
    cmp_ok( $bits_per_byte, '>=', 8, "$i1 got bits-per-byte value" );

    my $bits_per_word = $best->bits_per_word();
    ok( $bits_per_word, 
                "$i1 got bits_per_word $bits_per_word specific to shifts" );
    cmp_ok( $bits_per_word, '>=', $bits_per_byte,
                "$i1 bits_per_word >= bits_per_byte" ) or
         BAIL_OUT( "fundamental calculation trouble all too likely" );
        
  {
    my $length = 32;
    my $randbytes = $best->randbytesz($length);
    cmp_ok( length($randbytes), '==', 
                      $length, "$i1 randbytesz() got $length random bytes block" ) or
                BAIL_OUT();

  }

  {
    my $rand;
    my $rmax = 1;
    my $randz = $best->randz($rmax) || 
                $best->randz($rmax) ||
                $best->randz($rmax);
    ok ( $randz >= 0.0 && $randz < $rmax, "$i1 random number ->randz($rmax)" );

    my @randz;
    for ( my $n = 0; $n <= 10000; $n++ )
    {
        push( @randz, $best->randz($rmax) );
    }

    $t->ok_random( \@randz, $i1 );
  }
}

#end
