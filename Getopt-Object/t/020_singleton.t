# t/20-singleton.t
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

use Test::More tests => 4;

my $i0 = "";
my $i1 = "  ";


#######################################################################

local @ARGV = ( '--string=string', '--int=5', '--float=3.14159',
                '--use_me=active',
                '--counter', '--counter', '--bool', '--boolnot' );

my $o = Getopt::Object->singleton( 
              'string=s' => undef,  'int=i' => 0, 'float=f' => 0, 
                  'counter+' => 0,
                  'bool' => 0, 'boolnot!' => 0 );

ok( $o, "$i0 singleton created object" ) or BAIL_OUT();

my @deletes = grep( /^::/, keys %$o );
delete @{$o}{@deletes};         #get rid of internal keys
is_deeply( $o, { 'string' => 'string',  'int' => 5, 'float' => 3.14159, 
                  'counter' => 2,
                  'use_me' => 'active',
                  'bool' => 1, 'boolnot' => 1 },
           "$i1 singleton created expected contents" );

my $s = Getopt::Object->singleton();
ok( $s, "$i0 second singleton returned object" ) or BAIL_OUT();
cmp_ok( $s, 'eq', $o, "$i1 second singleton returned the same object" );


exit EXIT_SUCCESS;
