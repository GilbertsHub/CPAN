#t/010-basic.t
# Copyright 2011 by Gilbert Healton

use strict;
use warnings;

use POSIX qw( EXIT_FAILURE EXIT_SUCCESS );

use Getopt::ObjectSimple;
use Data::Dumper;
   $Data::Dumper::Indent   = 1;
   $Data::Dumper::Sortkeys = 1;

my $i0 = "";
my $i1 = "  ";


my @test_steps;
BEGIN
{
@test_steps =  (
     { title => "all option types with =",
       argv  => [ '--string=string', '--int=5', '--float=3.14159',
                  '--counter', '--COUNT',
                  '--bool', '--boolnot' ],
       call  => { 'string=s' => undef,  'int=i' => 0, 'float=f' => 0, 
                  'counter+' => 0,
                  'bool' => 0, 'boolnot!' => 0 },
       vals  => { 'string' => 'string',  'int' => 5, 'float' => 3.14159, 
                  'counter' => 2,
                  'bool' => 1, 'boolnot' => 1 },
     },
     { title => "all option types without =",
       argv  => [ '--string' => 'string', 
                  '--int' => '5', '--float' => '3.14159',
                  '--counter', '--counter',
                  '--boolnot', '--bool' ],
       vals  => { 'string' => 'string',  'int' => 5, 'float' => 3.14159, 
                  'counter' => 2,
                  'bool' => 1, 'boolnot' => 1 },
     },
     { title => "no options... all at default",
       argv  => [],
       vals  => { 'string' => undef,  'int' => 0, 'float' => 0, 
                  'counter' => 0,
                  'bool' => 0, 'boolnot' => 0 },
     },


     { title => "assure == option passes well defined settings",
       argv  => [ '--string=string', '--int=5', '--float=3.14159' ],
       call  => { 'string==s' => undef,  'int==i' => 0, 'float==f' => 0 },
       vals  => { 'string' => 'string',  'int' => 5, 'float' => 3.14159 },
     },
     { title => "expected error: assure omitted == option fails",
       argv  => [ '--int=5', '--float=3.14159' ],
       call  => { 'string==s' => undef,  'int==i' => 0, 'float==f' => 0 },
       ERROR => 'required option omitted: --string',
     },

     { title => "Test --noboolnot properly complements",
       argv  => [ '--bool', '--boolnot', '--noboolnot' ],
       call  => { 'string=s' => undef,  'int=i' => 0, 'float=f' => 0, 
                  'counter+' => 0,
                  'bool' => 0, 'boolnot!' => 0 },
       vals  => { 'string' => undef,  'int' => 0, 'float' => 0, 
                  'counter' => 0,
                  'bool' => 1, 'boolnot' => 0 },
     },

     { title => "Test single-letter options WITHOUT bundling",
       argv  => [ '-a', '-v', '-v', '-i=hello.txt' ],
       call  => { 'alternate|a!' => 0, 'verbose|v+' => 0, 'in|i=s' => "", 
                 'avv' => undef },
       vals  => { alternate => 1, verbose => 2, in => 'hello.txt', 
                  avv => undef },
     },
     { title => "Test single-letter options WITH bundling",
       call  => { 'alternate|a!' => 0, 'verbose|v+' => 0, 'in|i=s' => "", 
                 'avv' => undef,
                 ':BUNDLING' => 1 },
       argv  => [ '-avv', '-ihello.txt' ],
     },
  );

}

use Test::More tests => 4 * @test_steps - 1;



#######################################################################

my $trouble = 0;

my $myWarns = 0;
my $myExpected = 1;             #number of expected warnings
my @myWarn;
sub myWarn
{
    $myWarns++;
    @myWarn = @_;
}

#######################################################################

my $argv;               #arrayref: @ARGV values for test
my $call;               #hashref: constructor arguments
my $vals;               #hashref: values to expect after call

foreach my $test ( @test_steps )
{
    $argv   = $test->{'argv'}    if exists $test->{'argv'};
    $call   = $test->{'call'}    if exists $test->{'call'};
    $vals   = $test->{'vals'}    if exists $test->{'vals'};

    ok( 1, "$i0 $test->{'title'}" ) or BAIL_OUT( "corrupted test hash" );
    ok( $argv, "$i1 ARGV=@$argv" ) or $trouble++;

    # deep copy master values that change into local copies
    my $vals_work = { %$vals };

    # parse the @ARGV options
    local $SIG{'__WARN__'} = \&myWarn ;

    my $o = Getopt::ObjectSimple->new( ':ARGV' => $argv, %$call );
    if ( ! exists($test->{'ERROR'}) )
    {   #should be successful
        unless ( ok( $o, "$i1 Parsing arguments successful") )
        {
            $trouble++;
            next;
        }

        my @deletes = grep( /^::/, keys %$o );
        delete @{$o}{@deletes};         #get rid of any internal keys
        is_deeply( $o, $vals_work, "$i1 deep comparision" );
    }
    else
    {   #should fail
        unless ( ok( !$o, "$i1 expected constuctor failure" ) )
        {
            diag( Data::Dumper->Dump( [ $o ] => [ 'object' ] ) );
            $trouble++;
        }
    }
}

exit $trouble ? EXIT_FAILURE : EXIT_SUCCESS;

#end
