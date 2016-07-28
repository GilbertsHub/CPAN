# t/030-FILE.t
# Copyright 2011 by Gilbert Healton

use strict; use warnings;

use POSIX qw( EXIT_FAILURE EXIT_SUCCESS );

use Getopt::Object;

use Data::Dumper;
   $Data::Dumper::Indent   = 1;
   $Data::Dumper::Sortkeys = 1;

use Test::More tests => 30;

my $i0 = "";
my $i1 = "  ";
my $i2 = "$i1  ";


( my $file_path = $0 ) =~ s/\.t$/.txt/;
my @argv_master = ( '--FILE3=baz', 'plain_option' );


#######################################################################
#
#   :FILE from true file
#
{
    my @argv = @argv_master;
    ok( -f $file_path, 
               "$i0 (1) FILE test pointing to true file $file_path" ) ||
        BAIL_OUT( qq(NO FILE "$file_path") );

    my $o = Getopt::Object->new( 
                    { ':FILE' => $file_path, ':ARGV' => \@argv },
                    'FILEbool!' => 0,
                    'FILE1=s'   => undef,
                    'FILE2=s'   => undef,
                    'FILE3=s'   => undef,
                       );
    ok( $o, "$i1 new(:FILE) created Getopt::Object object" ) or BAIL_OUT();
    ok( $o->{'FILEbool'}, "$i1 --FILEbool set" );
    cmp_ok( $o->{'FILE1'}, 'eq', 'hello', qq($i1 --FILE1 set to "hello") );
    cmp_ok( $o->{'FILE2'}, 'eq', 'world', qq($i1 --FILE2 set to "world") );
    cmp_ok( $o->{'FILE3'}, 'eq', 'baz',   qq($i1 --FILE3 set to "baz") );
    cmp_ok( scalar(@argv), '==', 1, qq($i1 found expected arg) );
    cmp_ok( $argv[0], 'eq', $argv_master[-1], qq($i2 found expected value) );
}

#######################################################################
#
#   :FILE from object
#
{
  {
    package Foobar;

    sub new
    {
        my $handle = IO::File->new( "<$file_path" );
        return $handle ? bless { handle => $handle } : $handle;
    }

    sub getline
    {
        my $self = shift;

        return $self->{'handle'}->getline;
    }
  }

    my $xargs = 2;              #arguments to expect
    sub do_file3
    {
        our $getopt_obj_hash;
        my (
            $option,
            $value,
            @extras ) = @_;

        ok( 1, "$i1 --FILE3 sub called" );
        cmp_ok( scalar(@_), '==', $xargs, "$i2 sub got $xargs args" );
        ok( $getopt_obj_hash->isa('Getopt::Object'),
                                    "$i2 sub isa Getopt::Object object" );
        cmp_ok( $option, 'eq', 'FILE3', "$i2 sub got expected --FILE3 option" );
        cmp_ok( $value,  'eq', 'baz',   "$i2 sub given value of baz" );

        $getopt_obj_hash->{"_$option"} = $value;
    }

    my @argv = @argv_master;
    my $foobar = Foobar->new();         #open file
    ok( $foobar, "$i0 (2) :FILE objectref test got special Foobar object" ) ||
        BAIL_OUT();

    my %options = (
                    'FILEbool!' => 0,
                    'FILE1=s'   => undef,
                    'FILE2=s'   => undef,
                    'FILE3=s'   => \&do_file3,
                  );
    my $o = Getopt::Object->new( 
                    { ':FILE' => $foobar, ':ARGV' => \@argv },
                     \%options );
    ok( $o, "$i1 new(:FILE) created Getopt::Object object" ) or BAIL_OUT();
    ok( $o->{'FILEbool'}, "$i1 --FILEbool set" );
    cmp_ok( $o->{'FILE1'}, 'eq', 'hello', qq($i1 --FILE1 set to "hello") );
    cmp_ok( $o->{'FILE2'}, 'eq', 'world', qq($i1 --FILE2 set to "world") );
    cmp_ok( $o->{'_FILE3'}, 'eq', 'baz',   qq($i1 --FILE3 set to "baz") );
    cmp_ok( scalar(@argv), '==', 1, qq($i1 found expected arg) );
    cmp_ok( $argv[0], 'eq', $argv_master[-1], qq($i2 found expected value) );
    cmp_ok( $options{'FILE3=s'}, 'eq', \&do_file3,
                "$i2 Special FILE3 sub ref remains proper value" );
}


#######################################################################
#
#   Now assure odd :FILE tricks work
#
{
    my $magic_value = 'should-not-see';
    my $magic_valueQM = quotemeta $magic_value;
  {
    package Bazbar;

    sub new
    {
        return bless [ '--noFILEbool', '--', "--FILE1=$magic_value" ];
                # "--" will leave --FILE1 unprocessed by Getopt::Long.
                # this should also trigger a warning because all options
                # must be processed by :FILE in properly configured worlds.
    }

    sub getline
    {
        my $self = shift;

        shift @$self;
    }
  }

    my @argv = @argv_master;
    my $bazbar = Bazbar->new();         #open file
    ok( $bazbar, "$i0 (3) :FILE objectref test got special Bazbar object" ) ||
        BAIL_OUT();

    my @warn;                   #capture warnings here
    my $o = Getopt::Object->new( 
                    { ':FILE' => $bazbar, 
                      ':ARGV' => \@argv, 
                      ':WARN' => \@warn  },
                    'FILEbool!' => 1,
                    'FILE1=s'   => undef,
                    'FILE2=s'   => undef,
                    'FILE3=s'   => undef,
                       );
    ok( $o, "$i1 new(:FILE) created Getopt::Object object" ) or BAIL_OUT();
    cmp_ok( scalar(@argv), '>=', scalar(@argv_master),
                "$i1 did not capture arguments from ARGV" );
    ok( !$o->{'FILEbool'}, "$i1 --FILEbool has been set FALSE" );
    ok( !defined($o->{'FILE1'}), qq($i1 --FILE1 NOT defined) ) ||
        diag('   FILE1=' . (defined($o->{'FILE1'}) ? $o->{'FILE1'} : "undef" ));
    cmp_ok( scalar(@warn), '==', '1', "$i1 Found expected :FILE warning" ) &&
    like( $warn[0], qr/^warn\s/, qq($i1 Warning starts with "warn" prefix));
    like( $warn[0], qr/$magic_valueQM/, "$i1 Warning value correct /$magic_value/" );
}


exit EXIT_SUCCESS;
