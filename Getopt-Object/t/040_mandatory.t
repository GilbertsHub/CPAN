# t/040-mandatory.t
# Copyright 2011 by Gilbert Healton

use strict;
use warnings;

use POSIX qw( EXIT_FAILURE EXIT_SUCCESS );

use Getopt::Object ( 'use_me=s' => 'should be used by defaut' );
                # (normally arguments used by modules to add 
                #  module-specific options at compile time, use
                #  of this in main is not typical, but nice for 
                #  writing tests. See :BEGIN configuration)

use Data::Dumper;
   $Data::Dumper::Indent   = 1;
   $Data::Dumper::Sortkeys = 1;

use Test::More tests => 15;

my $i0 = "";
my $i1 = "  ";
my $i2 = "  $i1";


#######################################################################

my @values_array;
my %values_hash;
my $scalar;

my @indirect_array;
my %indirect_hash;
my $indirect_array = \@indirect_array;
my $indirect_hash  = \%indirect_hash;

my %options = ( 
                'string==s'     => undef,          #simple object member
                'scalar==s'     => \$scalar,       #ref outside object
                'array==s'      => \@values_array,
                'hash==s'       => \%values_hash,
              );
my @option_keys = sort keys %options;

#
#   Assure manditory flags all forms of omitted options
#
{
    my @argv = ();
    my @warnings;

    @values_array = %values_hash = ();
    my $o = Getopt::Object->new( 
                  { ':ARGV' => \@argv, ':WARN' => \@warnings },
                  %options );

    ok( !$o, "$i0 object creation without any manditory options failed" ) or 
        BAIL_OUT( "object should not of been created" );

    cmp_ok( scalar(@warnings), '==', scalar(@option_keys),
                        "$i1 Got expected number of troubles" ) or
        BAIL_OUT( join( "\n", @warnings ) );

    cmp_ok( scalar(@warnings), '==', scalar(grep(/^die/,@warnings)),
                        "$i1 All troubles are fatal DIEs" ) or
        diag( join( "\n", @warnings ) );

    #ZZZ verify each option has a warning for it
    my $troubles = 0;
    ok( 1, "$i1 Each key has exactly one trouble:" );
    foreach my $key ( @option_keys )
    {
        my $k = $key;
        $k =~ s/==/=/g;         #allow Getopt::Long to not know ==
        my $kQM = quotemeta($k);
        $kQM =~ s/=/=+/g;       #also allow Getopt::Long to know ==
        my @t = grep( /--$kQM$/, @warnings );
        cmp_ok( scalar(@t), '==', 1, "$i2 $key" );
    }
}
#
#   assure manditory notices all forms of submitted options
#
{
    my @argv = (
                '--string=:STRING',
                '--scalar=:SCALAR',
                '--array=:ARRAY1',        '--array=:ARRAY2',
                '--hash=k1=:HASH1',       '--hash', 'k2=:HASH2',
                'LEFTOVER'
               );
    my @warnings;

    my @expect_array  =  qw( :ARRAY1 :ARRAY2 );
    my %expect_hash   =  ( k1 => ':HASH1',   k2 => ':HASH2' );
    
    @values_array = %values_hash = ();
    my $o;
  eval
  {
    $o = Getopt::Object->new( 
                  { ':ARGV' => \@argv, ':WARN' => \@warnings },
                  %options );
  };
    ok( ! $@, 
         "$i0 object creation with all manditory options did not die") or
                Data::Dumper->Dump( [ \$@,  \@warnings,  \@argv ] =>
                                    [ '$@', '@warnings', '@argv' ] );

    ok( $o, "$i1 object created" ) or 
        BAIL_OUT( "object not created.\n" .
                Data::Dumper->Dump( [ \@warnings,  \@argv ] =>
                                    [ '@warnings', '@argv' ] ) );

    cmp_ok( scalar(@argv), '==', 1, "$i1 all -- options captured" ) or
        BAIL_OUT( "ARGV not properly processed:\n" .
                Data::Dumper->Dump( [ \@warnings,  \@argv ] =>
                                    [ '@warnings', '@argv' ] ) );

    ok( defined($o->{'string'}) && $o->{'string'} eq ':STRING',
            "$i1 --string=:STRING" ) or
        diag( "--string not captured: " .
                Data::Dumper->Dump( [ $o->{'string'} ] => [ 'string' ] ) );

    ok( defined($o->{'scalar'}) && ${$o->{'scalar'}} eq ':SCALAR',
            "$i1 --scalar=:SCALAR" ) or 
        diag( "--string not captured: " .
                Data::Dumper->Dump( [ $o->{'scalar'} ] => [ 'scalar' ] ) );
   
    is_deeply( $o->{'array'}, \@expect_array,
                "$i1 --array=:ARRAY1,:ARRAY2" );

    is_deeply( $o->{'hash'}, \%expect_hash,
                "$i1 --hash=k1=>:HASH1,k2=>:HASH2" );


}

exit EXIT_SUCCESS;
