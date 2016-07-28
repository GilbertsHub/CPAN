# t/050-class_conflict.t
# Copyright 2012 by Gilbert Healton

use strict;
use warnings;

use POSIX qw( EXIT_FAILURE EXIT_SUCCESS );

use Getopt::Object;             #assume main uses Object and
use Getopt::ObjectSimple;       # some module uses ObjectSimple


use Test::More tests => 3;

my $i0 = "";
my $i1 = "  ";
my $i2 = "  $i1";


#######################################################################


my %options = ( 
                'string=s'     => undef,          #simple object member
              );

#
#   assure that if both classes "used" the more complex Getopt::Object wins.
#
my $simple = Getopt::ObjectSimple->new( \%options );
isa_ok( $simple, 'Getopt::Object' );

my $singleton = Getopt::ObjectSimple->singleton( \%options );
isa_ok( $singleton, 'Getopt::Object' );


ok( Getopt::ObjectSimple->isa("Getopt::Object"), '@ISA works' );


exit EXIT_SUCCESS;
