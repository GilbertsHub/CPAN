#t/010-basic.t
# Copyright 2011 by Gilbert Healton

use strict;
use warnings;

use POSIX qw( EXIT_FAILURE EXIT_SUCCESS );

use Getopt::Object ( 'ignore_me' => 
                     'This should be ignored by default with new' );
                        # (see :BEGIN configuration)
use Data::Dumper;
   $Data::Dumper::Indent   = 1;
   $Data::Dumper::Sortkeys = 1;

my $i0 = "";
my $i1 = "  ";


my @test_steps;
BEGIN
{
my $std_call  = { 'string=s' => undef,  'int=i' => 0, 'float=f' => 0, 
                  'counter+' => 0,
                  'bool' => 0, 'boolnot!' => 0, };
my $std_vals  = { 'string' => 'string',  'int' => 5, 'float' => 3.14159, 
                  'counter' => 2,
                  'bool' => 1, 'boolnot' => 1 };
@test_steps =  (
     { title => "all option types with =",
       argv  => [ '--string=string', '--int=5', '--float=3.14159',
                  '--counter', '--COUNT',
                  '--bool', '--boolnot' ],
       call  => $std_call,
       vals  => $std_vals,
     },
     { title => "all option types without =",
       argv  => [ '--string' => 'string', 
                  '--int' => '5', '--float' => '3.14159',
                  '--counter', '--counter',
                  '--boolnot', '--bool' ],
     },
     { title => "With :ARGV option",
       argv  => [ '--hello', 'world' ],
       config => [ ':ARGV' =>
                    [ '--string' => 'string', 
                      '--int' => '5', '--float' => '3.14159',
                      '--counter', '--counter',
                      '--boolnot', '--bool' ], ],
     },
     { title => "With in-line :ARGV option",
       argv  => [ '--hello', 'world' ],
       call  => { %$std_call,
                  ':ARGV' =>
                    [ '--string' => 'string', 
                      '--int' => '5', '--float' => '3.14159',
                      '--counter', '--counter',
                      '--boolnot', '--bool' ] },
       config => [],
     },
     { title => "no options... all at default",
       config => [],
       call  => $std_call,
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
       config => [ ':config' => 'bundling' ],
       argv  => [ '-a', '-v', '-v', '-ihello.txt' ],
       call  => { 'alternate|a!' => 0, 'verbose|v+' => 0, 'in|i=s' => "", 
                 'avv' => undef },
       vals  => { alternate => 1, verbose => 2, in => 'hello.txt', 
                  avv => undef },
     },
     { title => "Test single-letter options WITH bundling",
       config => [ ':config' => 'bundling' ],
       argv  => [ '-avv', '-ihello.txt' ],
     },
  )

}

use Test::More tests => 4 * @test_steps + 1;


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

my $argv;
my $call;
my $vals;
my $config = { ':config' => 'nodebug' };
foreach my $test ( @test_steps )
{
    $argv   = $test->{'argv'}    if exists $test->{'argv'};
    $call   = $test->{'call'}    if exists $test->{'call'};
    $vals   = $test->{'vals'}    if exists $test->{'vals'};
    $config = $test->{'config'}  if exists $test->{'config'};

    ok( 1, "$i0 $test->{'title'}" ) or BAIL_OUT( "corrupted test hash" );
    ok( $argv, "$i1 ARGV=@$argv" ) or $trouble++;

    # deep copy master values that change into local copies
    local @ARGV = @$argv;
    my $vals_work = { %$vals };

    # parse the @ARGV options
    local $SIG{'__WARN__'} = \&myWarn ;
    @myWarn = ();

    my $o = Getopt::Object->new( $config, $call );
    if ( ! exists($test->{'ERROR'}) )
    {   #should be successful
        unless ( ok( $o, "$i1 Parsing arguments successful") )
        {
            $trouble++;
            next;
        }
        if ( @myWarn )
        {   #unexpected warning
            $myWarn[0] =~ s/\s+$//s;
            diag( "TROUBLE: Unexpected Warning: @myWarn" );
        }

        my @deletes = grep( /^::/, keys %$o );
        delete @{$o}{@deletes};         #get rid of internal keys
        is_deeply( $o, $vals_work, "$i1 deep comparision" );
    }
    else
    {   #should fail
        $myWarn[0] =~ s/\s+$//s if @myWarn;
        my $errorQM = quotemeta $test->{'ERROR'};
        my $errorRE = qr/$errorQM/;
        like( "@myWarn", $errorRE ,
                 "$i1 expected warning trapped: @myWarn" ) ||
                $trouble++;

        unless ( ok( !$o, "$i1 expected constuctor failure" ) )
        {
            diag( Data::Dumper->Dump( [ $o ] => [ 'object' ] ) );
            $trouble++;
        }
    }
}

cmp_ok( $myWarns, '==', 
        $myExpected, "$i0 Found expected $myExpected warnings" ) or
   $trouble++;

exit $trouble ? EXIT_FAILURE : EXIT_SUCCESS;

#end
