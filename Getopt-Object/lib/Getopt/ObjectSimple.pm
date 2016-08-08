# Getopt::ObjectSimple -- simple object API to Getopt::Long
# Copyright 2011 to 2012 by Gilbert Healton
# This module is free software; you can redistribute it and/or modify 
# it under the same terms as Perl 5.8.10. For more details, see
# the full text of the licenses in the directory LICENSES.

use strict;

our $VERSION;  $VERSION = '0.005';	#VERSION number

=pod

=head1 NAME

Getopt::ObjectSimple--Processing command line options using a 
simpler object class than Getopt::Object.

=head1 SYNOPSIS

 use Getopt::ObjectSimple;	#useful API to Getopt::Long

 # SINGLETON is recommended for capturing command line options
 my $newobj = Getopt::ObjectSimple->singleton( 
                # (provide option descriptions and default values)
               'opt1=i'   =>    undef,    #integer option
               'opt2=s'   =>    undef,    #string option
               'verbose!' =>    1,        #default bool to verbose
               ...
             );
   ...
 if ( $optobj->{'opt1'} )       #test --opt1 setting

   ...
 # NEW is recommened for anything other than command lines
 my $newobj;
 {                      #(limit scope of local @ARGV)
     $newobj = Getopt::ObjectSimple->new( 
               ':ARGV'    =>    \@alternate, #alternate @ARGV
               'opt1=i'   =>    undef,    #integer option
               'opt2=s'   =>    undef,    #string option
               'verbose!' =>    1,        #default bool to verbose
               ...
             );
 }

=head1 DESCRIPTION

Provides a true-object oriented interface to Getopt::Long
for parsing command line options.
The returned object contains values for all possible options with
well defined defaults.

All valid options, settings, and the associated defaults,
are provided in the constructor call creating the object and
are not scattered across different definitions and calls.
All options are returned in the object.

Proper use of the singleton constructor 
makes it trivial for any module to access command line options.

A following I<EXAMPLES> section provides
examples as well as some details on usage and can serve as a 
Quick Start.

=head2 singleton() constructor (normal)

The singleton constructor is provided to capture command line options
in @ARGV for the main program.
After B<singleton> captures command line options
any further B<singleton> calls return the original object and options.
These later constructor calls must not have arguments:

    package Foo;        #packaging wanting to access options
    ...
    my $optobj = Getopt::ObjectSimple->singleton(); #reget options

=head2 new() constructor (special)

The B<new> constructor is called identically to the B<singleton>()
constructor but returns distinctly unique option objects.

B<new>() would be used if additional, independent,
options from other sources needed to be parsed.
Especially options that are not to conflict with command line options.

   my $newobj;
   $newobj = Getopt::ObjectSimple->new( ':ARGV' => @my_argv, ... )

The :ARGV option is used to pass the address of the arguments to
be parsed when @ARGV is not approprate (the usual case).

=head1 RETURN CONDITIONS

=head2 Successful Returns

On success a reference to a hash object is returned where
all options have a key/value pair in the hash:

   $optobj->{'debug'}           #tests if --debug is set

All command line options captured by Getopt::ObjectSimple() are 
shifted out of @ARGV.
The remaining @ARGV values contain command line arguments
the program is expected to process.

The following would leave the "file" arguments in @ARGV:

  command --outfile=somefile.txt --verbose file1.txt file2.txt

=head2 Trouble Returns

Fatal errors normally cause the constructor to return a false value.
The contents of @ARGV are undefined on this condition.
Very severe problems may result in die calls, which can be trapped.

=head2 Mandatory options

Most option keys taking C<=> may also use a double equal sign,
C<==>, to flag options that must have well set values
if the program is to run.

A diagnostic is printed and a constructor failure is returned
if such options have values that are not well set at the end of the call.
Values of C<undef> or empty string ("") are considered not well set.

Beware: a zero (0) is considered well set.

C<==> is a Getopt::Object extension not available 
to direct callers of Getopt::Long (as of 2011-12).

=head1 EXAMPLES

=head2 Typical Use

 use Getopt::Object;
  . . .
 my $optobj = Getopt::ObjectSimple->singleton(
                'foo==s' => undef,       #--foo must be set (==)
                'bar=s'  => undef,       #--bar has no default
                'baz==s' => "e-thumb",   #--baz must not be set ""
                                         # (default value is OK)
                'answer=i' => 42,        #--answer defaults to 42
                'verbose:1' => 0,        #--verbose sets 1 if no arg
                );        #baz must not be set

 # process any arguments that follow the /^-/ options
 foreach my $arg ( @ARGV )
 {
     print "Processing argument $arg\n"
	 if $optobj->{'verbose'};

     process_arg( $arg );
 }

=over +2

=over +2

=item *

The C<--foo> option must be set by the caller 
due to the double equal (C<==>) and default value of C<undef>.

=item *

While C<--bar> remains C<undef> if not set it can be set to an
empty string by C<--bar=> by an empty argument after the C<=>.


=item *

While C<--baz=> may be omitted as the default value is well defined,
the use of C<--baz=> to set an empty value results in
the Getopt::Object constructor failing on return due to the double equal (C<==>).

=back

=back


=head2 With Hash References

Though not used much in the samples,
hash references can be used for all option familys:

 use Getopt::Object;

 my %options = (
             'debug|d+'      => 0,
             'verbose|z+'    => 0,
             'outfile|o==s'  => undef,
               );
  . . .
 my $optobj = Getopt::Object->singleton(
             \%options
                );

=head2 Double Hyphen
 
     command --debug --verbose --outfile=foo.txt zap1
     command --debug --verbose --outfile=foo.txt -- --zap2

A "--" ends option processing, all following items are arguments and not options.
In these commands both of the "zaps" are command line arguments 
left in @ARGV. 
Especially "--zap2".
The use of C<--> prevents Getopt routines from processing 
following elements of @ARGV, even if they start with hyphens.

=head1 RESTRICTIONS

Having subroutine references in default values is not supported.
That requires the more complex Getopt::Object package.

=head1 ALSO SEE

B<Getopt::Long> for the many variations, options,
and all of the obscure and advanced behaviors available to callers
of B<Getopt::ObjectSimple> that are not covered herein.
Not everything transfers, but much does.
B<Getopt::Long::Parser> is not used.

B<Getopt::Object> for a more powerful extension of Getopt::ObjectSimple
that has deeper compatibility with
B<Getopt::Long> and B<Getopt::Long::Parser>.

=head1 COPYRIGHT AND LICENSE

Copyright 2011 to 2016 by Gilbert Healton

This module is free software; you can redistribute it and/or modify 
it under the same terms as Perl 5.8.10. For more details, see
the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but it is provided “as is” and without any express
or implied warranties. For details, see the full text of
the license in the file LICENSE.

=head1 REPOSITORY

https://github.com/GilbertsHub/CPAN and see Getopt-Object therein.

=head1 ACKNOWLEDGEMENTS

To S<Johan Vromans E<lt>jvromansE<64>squirrelE<46>nlE<gt>>,
author of the B<Getopt::Long> module,
which is the base class used with B<Getopt::Object>.


=head1 DISCLAIMER

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
without implied warranties. For details, see the full text of
the referenced GPL.


=cut

package Getopt::ObjectSimple;

use Carp;
use Getopt::Long ();

use vars qw( @ISA );    #for becoming a Getopt::Object if that class present

###### central constructor

sub new
{
    my $proto = shift;          #pick off class name

    #if both Getopt::ObjectSimple and Getopt::Object are present
    #  use Getopt::Object.
    if ( exists &Getopt::Object::new )
    {
        unshift( @_, "Getopt::Object" );
        @ISA = ( 'Getopt::Object' ) if @ISA == 0;
        goto &Getopt::Object::new
    }

    my %args;
    if ( @_ == 1 )
    {   #sinlge remaining argument is reference
        %args = %{$_[0]};
    }
    else
    {   #else expect in-line arguments
        %args = @_;
    }

    my $fatals = 0;
    my $class = ref($proto) ? ref($proto) : $proto;

    #put default value into object keyed by primary option name
    my @init_keys = grep /^\w/, keys %args;
    my $self = { map{ 
                ( my $k = $_ ) =~ s/\W.*//;     #isolate key name
                ( $k, $args{$_} )       #return option name and default
                  } @init_keys };

    #build list of Getopt::Long objects without ==s that confuse it
    my @getopt_args = map {
                    ( my $k = $_ ) =~ s/==/=/;  #strike mandatory keys
                    $k 
                          } @init_keys;

    # allow Getopt::ObjectSimple->new( ':ARGV' => \@alternate_argv );
    local *ARGV = exists($args{':ARGV'}) ? $args{':ARGV'} : \@ARGV;

    #call Getopt::Long with bundling enabled, if requested
    Getopt::Long::Configure( "bundling" )
        if  exists($args{':BUNDLING'}) && $args{':BUNDLING'};

    my $return;
    $return = Getopt::Long::GetOptions( $self, @getopt_args );
    return $return unless $return;

    #now assure mandatory == options well defined
    foreach my $key (grep( /==/, keys %args ) )
    {
        ( my $k = $key ) =~ s/\W.*//;
        if ( !defined $self->{$k} || $self->{$k} eq '' )
        {   #complain loudly
            carp( "--$k= option not well set\n" );
            $fatals++;
        }
    }

    # return to caller
    return undef if $fatals;

    bless $self, $class;

    return $self;
}

###### singleton constructor

my $singleton;          #object to share with all
sub singleton
{
    return $singleton if $singleton;

    #if both Getopt::ObjectSimple and Getopt::Object are present
    #  use Getopt::Object.
    if ( exists &Getopt::Object::new )
    {   #special case when both classes present
        shift @_;
        unshift( @_, "Getopt::Object" );
        $singleton = &Getopt::Object::singleton;
        @ISA = ( ref $singleton ) if $singleton && @ISA == 0;
                #force ISA for any caller's $o->isa('Getopt::ObjectSimple')
    }
    else
    {   #typical case
        # be sure module not calling singleton too early
        croak "empty singleton() called before arguments parsed"
            unless @_ >= 2;

        $singleton = &new;          #call new passing our @_
    }

    return $singleton;          #return new object
}

1;
#end: Getopt::Simple.pm
