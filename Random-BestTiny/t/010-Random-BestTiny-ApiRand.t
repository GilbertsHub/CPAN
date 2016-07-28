# Rand API test

use strict;

use POSIX ();
use File::Basename;
use File::Spec;
use Data::Dumper ();

use base qw(Exporter);

use vars qw($cwd0 $dirt0 $name0 $name00 $lib0 );
use vars qw($i0 $i1 $i2);

# BEGIN
{
    my $tLibDir =  
       File::Spec->catdir( File::Spec->rel2abs( dirname($0) ), 'lib' );
    unshift @INC, $tLibDir;
    require  tLib;
    import   tLib;
    1;
}


my $t = tLib->new();


our $testPlan;
BEGIN  { $testPlan = 23; }

use Test::More tests => $testPlan ;

my $module_test = 'Rand';

ok( $lib0 && -d $lib0, "$i0 library dir \"$lib0\" exists" ) || BAIL_OUT();

SKIP:
{
    #
    #  PRELIMINARY TESTS
  { #
    my $lib = File::Spec->catdir( $cwd0, "lib" );
    my $w = "w";

    my $cmd;

        # moduleList must compile on all OS types
    $cmd = qq(perl -c$w "-I$lib" -MRandom::BestTiny::moduleList -e 1);
    ok( !system($cmd), "$i0 lint Random::BestTiny::moduleList" ) or 
                                                           BAIL_OUT();

    my $path = File::Spec->catfile( 'lib', 'Random', 'BestTiny', 
                                                 'moduleList.pm' );
    require_ok( $path ) or BAIL_OUT();

    my $can  = Random::BestTiny::moduleList->can('module_');
    ok( $can, "$i1 Random::BestTiny::moduleList can call ->module()" ) or
                                                           BAIL_OUT;
                        
    # assure moduleList returns a module (typically other than Rand)
    my $module = Random::BestTiny::moduleList->$can(); #get module
    ok ( $module, "$i1 Returned module" ) or BAIL_OUT;

    $cmd = qq(perl -c$w "-I$lib" -MRandom::BestTiny::Api$module_test -e 1);
    ok( !system($cmd), "$i0 lint Random::BestTiny::Api$module_test" ) or BAIL_OUT;

    $path = File::Spec->catfile( $cwd0, "lib", "Random", "BestTiny",
                                                        "Api$module_test.pm" );
    require_ok( $path ) or  BAIL_OUT();
  }

    #
    #   Random::BestTiny::ApiRand testing
  { #
    my $quality;
    {   #provide alternates to methods in SUPER class, which we are not yet requiring


        package Random::BestTiny::ApiRand;

        use vars qw($cwd0 $dirt0 $name0 $name00 $lib0 );
        use vars qw($i0 $i1 $i2);
        
        sub best_bytes { return $quality ? &best_quality : &best_normal() }

        sub bits_per_byte { return 8 }

        sub bytes_per_word { return 2 }

        sub bits_per_word { 
                   my $bpw = bytes_per_word;
                   my $bpb = bits_per_byte;
                   return $bpw * $bpb;
                   }

        sub signed_word_max
        {
            return ( 1 << ( bits_per_word - 1 ) ) - 1;
        }

        sub unsigned_word_max
        {
            my $class_or_self = shift;
            return ( 1 << $class_or_self->bits_per_word ) - 1;
        }

        sub quality { return $quality }
    }

    foreach my $q ( 0, 1 )
    {
        $quality = $q;          #(work around closure)

        my $bran = Random::BestTiny::ApiRand->new_({ quality => $quality});
        ok( $bran, "$i0 Random::BestTiny::ApiRand->new_({ " .
                        "quality => $quality})" ) || BAIL_OUT();

        my $best_bytes = $bran->best_bytes();
        ok ($best_bytes > 0, 
               "$i1 ->best_bytes() returned value $best_bytes" ) or
                        BAIL_OUT( "bad value=$best_bytes" );

        1;
        my $randomBuffer = $bran->rawz();       #use default byte count
        1;
        ok( $randomBuffer && $$randomBuffer, 
                         "$i1 ->rawz() gets bytes" )  or
                BAIL_OUT( Data::Dumper->Dump( 
                            [ 'randomBuffer' ] => [ $randomBuffer ] ) );

        cmp_ok( length($$randomBuffer), '==', $best_bytes,
                        "$i2 ->rawz() returned $best_bytes bytes" );

        # # # 

        my $best_bytes2 = $best_bytes * 100;     #get 100 * block size
        $randomBuffer =      #use well over default count
                           $bran->rawz( $best_bytes2 ); 

        cmp_ok( length($$randomBuffer), '==', $best_bytes2,
                "$i1 ->rawz( $best_bytes2 ) returns $best_bytes2 bytes" );

        my @rbytes = unpack( 'C*', $$randomBuffer );
        cmp_ok( scalar(@rbytes), '==', $best_bytes2,
                "$i1 unpacked $best_bytes2 bytes" );

        $t->ok_random( \@rbytes,  "$i2" );
        
        1;
    }
  }
}

exit POSIX::EXIT_SUCCESS();

#end
