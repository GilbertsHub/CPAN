# Getopt::Object -- useful API to Getopt::Long
# Copyright 2011 to 2012 by Gilbert Healton

use strict;

our $VERSION;  $VERSION = '0.005';	#VERSION number

package Getopt::Object;

=pod

=head1 NAME

Getopt::Object--Enhanced command line option processing via true object class.


=head1 SYNOPSIS

 use Getopt::Object;		#useful API to Getopt::Long

 # Singleton Constructors: recommended for @ARGV command line arguments
 my $optobj = Getopt::Object->singleton( 
               ':BUNDLING' => 1,     #optional: enable "bundling"
               'opt1=i'    => undef, #integer option
               'opt2=s'    => undef, #string option
               'verbose!'  => 1,     #default to verbose
               ...
             );
 my $optobj = Getopt::Object->singleton( 
               { :config => [qw( bundling )]}, #optional: ::Parser options
               {  #valid command line options
                  'opt1=i'   =>    undef,    #integer option
                  'opt2=s'   =>    undef,    #string option
                  'verbose!' =>    1,        #default to verbose
                  ...
               }
             );
   ...
 if ( $optobj->{'opt1'} )       #test --opt1 setting

 # Classic constructor: for processing options outside of command lines
 my $altobj = Getopt::Object->new( ':ARGV' => \@alternate_args,
                                   'verbose!' => 1, ... );

 #with full hash %config options
 my %config = ( ':ARGV' => @alternate_args, ... );
 my $altobj = Getopt::Object->new( \%config, 'verbose!' => 1, ... );


=head1 DESCRIPTION

Getopt::Object provides an API to the classic Getopt::Long 
command line parser that is
very simple to use in small programs along with
enhanced power for programs with more complex option requirements.

This document is only covers the basics of using the features 
most people may use,
including "--long-name" options.

Additional details can be found in Getopt::ObjectPod.
Those who really want to dig into available features can also see Getopt::Long's
documentation, to access most of the features for Getopt::Object objects.

The I<EXAMPLES> section in these "Object" documents provide
examples as well as some details on usage.
Treat them as a type of "Quick Start" if you wish.

=head2 singleton() constructor (normal)

The singleton constructor is the best practice way 
to capture command line options in @ARGV at program startup.

Constructors are passed a description of acceptable command line options,
how to process them,
and the corresponding default values.
These are a series of key/value pairs in the style of a hash or
as a reference to a hash.
The hash keys provide both option names and 
control how the options are processed.

Keys starting with colons (:) are not command line option names but 
options changing the behavior of the constructor itself.
Only the most popular of such are described in this document.
Much more details on this subject are found in B<Getopt::ObjectPod>.

Successful constructor calls
return a reference to a blessed hash object containing 
keys for all option values.
The keys are the basic option names.

Failures return false values leaving option settings unavailable
to the caller with messages normally written to standard error
(but see B<:WARN>).

After B<singleton> captures any command line options
any further B<singleton> calls return the same object and options.
These later constructor calls must not have arguments and are
useful in large applications spread over many modules:

    package Foo;        #package wanting to access options
    ...
    my $optobj = Getopt::Object->singleton(); #reget options

Some interesting extensions,
such as having other modules define their own command line options,
are described in Getopt::ObjectPod.

=head2 new() constructor (special)

The B<new> constructor is called identically to the B<singleton>()
constructor but returns a unique option object.

B<new>() would be used if additional, independent,
options from sources other than the main command line need to be parsed.
See Getopt::ObjectPod for more details.


=head1 COMMAND LINE OPTION SUMMARY

While single-hyphen options are available, such as -osomefile.txt -v, 
POSIX style command line options starting with a double-hyphen are often more 
friendly.

  -osomefile.txt -v
  --outfile=somefile.txt  --verbose

All hyphen options, and any associated arguments, must precede any 
regular line arguments to
the command, such as the file names shown here.

  command --outfile=somefile.txt --verbose file1.txt file2.txt

In the general case the order of options is not important.
In the case of clashing options
the last option usually wins (--list vs --nolist),
but only the programmer may know for sure.

Option arguments can usually be given using two conventions:

  command  --first=foo-value --second bar-value

Users are free to mix different conventions on the same command.

The special option double-hyphen (C<-->) cleanly stops further 
option processing.
The C<--> is discarded and
all following words are considered command line arguments and
are not processed by Getopt::Object,
even if such start with hyphens.

  command  --first=foo-value -- --argument1 argument2 argument3

By default only enough of the option name to uniquely identify the 
option needs to be given.
The following can have the same impact as the prior.

  command  --fir=foo-value -- --argument1 argument2 argument3

=head1 POPULAR OBJECT CONFIGURATIONS

In addition to command line options constructors accept an
options to the constructor itself or the underlying 
Getopt::Long::Parser object.
The names of such options start with colons (:) and may be
provided mixed with the regular options or in a hash reference, or both.

While Getopt::Long::Parser class has many strange and mysterious options for
advanced developers not described herein,
one stand out is "bundling",
which allows commands to also use more classic single hyphen,
one-letter,
UNIX options that can be "bundled" together.
A bundled B<-xv> is the same as separate S<B<-x -v>>.
Without bundling each option must be followed by a space.

The simple way to request bundling is to use S<B<:BUNDLING => 1>> 
in the options. 
To connect more directly to Getopt::Long::Parser use 
the somewhat cryptic B<:config> hash reference as 
the first argument to the constructor:

   Getopt::Object->singleton( 
            { :config => [ qw( bundling ) ] }, 
            'alternate|a' => 0, 'in|i=s' => 0, 'verbose|v' => 0 );

More on how this works is beyond the scope of this document.
Dig in the documents mentioned elsewhere if you want the details.


=head1 CONSTRUCTOR COMMAND LINE OPTIONS

All valid command line options, 
how Getopt operations are to process the options,
along with default values,
are provided as an array of key/value pairs to the constructors.

=over +2

=over +2

=item *

The key,
usually quoted,
provides the option name,
any option name aliases, 
and how options are to be processed.

=item * 

Value provide the default value for options if
not changed from the command line.

=back

=back

While most command line options only have a single name,
keys accept a series of pipe (C<|>) delimited names for the option.
The first name is primary and 
is the hash key to access the option setting in the returned object.

    'debug|z+' => 0             # --debug and z alias

    #accessing
    $optobj->{'debug'}          #correct: finds --debug or -z
    $optobj->{'z'}              #wrong: no key named 'z'

Option names may be followed by an optional special character 
defining how the options are handled.
This character is often followed by additional settings
providing specific handling.

Option handling can be grouped by broad classes:

=over +2

=over +9

=item Bool

Options without a special character are set true if the option is given.

!: options followed by exclamation ("xxx!") are also booleans
set true by C<--xxx>
and false by a "no" prefix (--noxxx).

Booleans never have option arguments.

=item String

C<=s> identifies options that are to accept string values.

=item Counter

+: options ended by a plus sign are integer counters incremented
by each occurrence of the option.

Restriction: default values should be well defined integers,
such as zero.

=item Integer

C<=i> identifies options that are to accept integers.

C<=o> identifies extended integers that also accept 
octal (C<0377>) or hexadecimal (C<0xFF>) values.

=item Float

C<=f> identifies options that are to accept floating point numbers.

=item Mandatory options

Most option descriptions taking C<=> may use a double equal sign,
C<==>, to flag options that must have well set values
if the program is to run.

A diagnostic is printed and a constructor failure is returned
if such options maintain a value that is not well set
when the constructor is finished.
A default of C<undef> or empty string ("") are considered not well set.

Beware: a zero (0) is considered well set.

C<==> is a Getopt::Object extension not available 
to direct callers of Getopt::Long (as of 2011-12).

Restriction: C<==> is not to be used with options providing subroutine
references in the default value.
Subroutine references do not behave quite as with Getopt::Long so 
see Getopt::ObjectPod for vital details.

=item Optional option arguments

A C<:I<letter>> colon rather than C<=I<letter>> indicates any option argument 
is optional.

    'outfile:s'  =>  "default.txt"

Restriction: if the option argument is present on the command line
the C<=> syntax must be used:

   --optional=value
   --empty_argument=
   --missing_argument
   --wrong  without_equal       #this is wrong: "=" is required
   --wrong= also_wrong          #also wrong: "= " is empty argument

C<:I<integer>> may configure command line options accepting integers.
If an option is not given the provided integer value is used.

  #set to 5 if just --verbose is used, --verbose=n sets to n. 
  #  Else defaults to 1
  verbose:5 =>  1,    

=back

=back

=head1 RETURN CONDITIONS

On success a reference to a hash object is returned where
all options have a key/value pair in the hash:

   $optobj->{'debug'}           #tests if --debug is set

All command line options captured by Getopt::Object() are 
shifted out of @ARGV.
The remaining @ARGV values contain command line arguments
the program is expected to process.

The following would leave the "file" options in @ARGV:

  command --outfile=somefile.txt --verbose file1.txt file2.txt

Fatal errors normally cause the constructor to return a false value.
The contents of @ARGV are undefined on this condition.

Keys private to the class can also be present in the hash.
Such always start with a colon and are to be ignored by callers
and never presented to outside users.


=head1 SINGLETONS

If the main program calls the C<singleton> constructor rather than C<new>
to capture command line options
then any module in the execution can also access the options
by using:

       use Getopt::Object;

       my $localobj = Getopt::Object->singleton();

The big restrictions are that the main program must
have previously captured the command line arguments with a 
run time singleton constructor call
and the later singleton calls do not have arguments.

=head1 EXAMPLES

=head2 Typical Use

 use Getopt::Object;
  . . .
 my $optobj = Getopt::Object->singleton(  #fetch @ARGV options
                'foo==s' => undef,       #--foo must be set
                'bar=s'  => undef,       #--bar is optional
                'baz==s' => "e-thumb",   #--baz must not be set ""
                                         # (default value is OK)
                'answer=i' => 42,        #--answer defaults to 42
                'verbose:1' => 0,        #--verbose sets 1 if no arg
                ); 

 # @ARGV contains @ARGV members not captured by Getopt::Object
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
the Getopt::Object constructor failing due to the double equal (C<==>).

=back

=back

=head2 With Single Letter Bundled Options

The POSIX/Linux world usually allows single-letter options, 
with single hyphens, to be "bundled".
A bundled "-dv" is the same as "-d" and "-v".

 use Getopt::Object;
  . . .
 my $optobj = Getopt::Object->singleton(
             'debug|d+'      => 0,
             'verbose|z+'    => 0,
             'outfile|o==s'  => undef,
             :BUNDLING       => 1,      #(shortcut to following call)
                );

 my $optobj = Getopt::Object->singleton(
             { :config =>  [ qw( bundling ) ] },  #must be first!
             'debug|d+'      => 0,
             'verbose|z+'    => 0,
             'outfile|o==s'    => undef,
                );

The best practice of using single-character options 
is to have long option names, 
such as C<--debug>, be the prime name,
and the corresponding single letter option, C<-d>, be secondary.

=head2 With Hash References

Though not used much in the samples, hash references can be used 
for all option familys:

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
  . . .
 my $optobj = Getopt::Object->singleton(
             { :config =>  [ qw( bundling ) ] },  #must be first!
             \%options
                );

=head2 Double Hyphen
 
     command --debug --verbose --outfile=foo.txt zap1
     command --debug --verbose --outfile=foo.txt -- --zap2

In these commands both of the "zaps" are command line options 
left in @ARGV. 
Especially "--zap2".
The use of C<--> prevents Getopt routines from processing 
following elements of @ARGV, even if such start with hyphens.

=head1 ALSO SEE

The documentation in B<Getopt::ObjectPod> for 
additional information on the B<Getopt::Object> class.

B<Getopt::Long> for the many variations, options,
and all of the obscure and advanced behaviors available to callers
of B<Getopt::Object> that are not covered herein.

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2016 by Gilbert Healton

This module is free software; you can redistribute it and/or modify 
it under the same terms as Perl 5.8.10, or later. For more details, see
the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but it is provided "as is"
without express or implied warranties. 
For details, see the full text of the license in the file LICENSE.

=head1 REPOSITORY

https://github.com/GilbertsHub and see CPAN/Getopt-Object therein.

=head1 ACKNOWLDGEMENTS

To S<Johan Vromans E<lt>jvromansE<64>squirrelE<46>nlE<gt>>,
author of the B<Getopt::Long> module,
which is the base class used with B<Getopt::Object>.


=cut

#######################################################################

use Getopt::Long ();    #Getopt::Object has a, not IS A, Getopt::Long
use Scalar::Util ();
use IO::File;
use Carp qw(carp);

# :BEGIN options captured here
my %begin_options;              #late binding options saved here
my $begin_options = 0;          #true if too late for late binding

use constant OPTIONAL_FILE => '#';	#start :FILE names for optional files

# Override import (base code shamelessly stolen from Getopt::Long)
sub import 
{
    my $pkg = shift;            # package
    my @ours = ();              # symbols to import
    my @config = ();            # configuration
    my $dest = \@ours;          # symbols first
    for ( @_ ) {
        if ( $_ eq ':config' ) {
            $dest = \@config;   # config next
            next;
        }
        push(@$dest, $_);       # push
    }

    # handle our own options (if any)
    if ( $begin_options == 0 )
    {   # not too late
        %begin_options = @ours if @ours && (@ours & 1) == 0;
    }
    else
    {   #too late for options
        warn __PACKAGE__, ": Too late for BEGIN options on use";
    }

    # And configure Getopt::Long options
    Configure(@config) if @config;
}

# constructor
sub new
{
    my $proto = shift;

    # first look for internal configurations from singleton
    my %config;         #configuration values
                        #  lower case keys (e.g., :config): Getopt::Long options
                        #  upper case keys (e.g., :ARGV): our options
    if ( @_ >= 2 &&  $_[0]  &&  ref $_[0] )
    {   #looks like an internal configuration option from singleton() to me
        if ( Scalar::Util::reftype($_[0]) eq 'ARRAY' )
        {   #allow singleton() to have different defaults than new()
            %config = @{shift @_};     #expand singleton default options
        }
    }

    # now look for configurations user provided in a hashref
    if ( @_ >= 2 &&  $_[0]  &&  ref($_[0]) &&
           Scalar::Util::reftype($_[0]) eq 'HASH' )
    {   #still >= 2 imply user provided configurations
        my $cfg = shift;
        my @keys = keys %$cfg;
        @config{@keys} = @{$cfg}{@keys};   #drop in user desires
    }

    # now remember where callers arguments are
    my $init_args;      #reference to caller's key/default arguments

    if ( @_ == 1 )
    {   #one argument imply hash reference holds valid options & defaults
        $init_args = \%{shift @_};
    }
    else
    {   #expect remaining @_ to be key/value pairs: copy to hash 
        $init_args = { @_ };
    }

    #allow ':' values in regular argument list to override prior :s
    foreach my $key ( grep /^:\w/, keys %$init_args )
    {
        $config{$key} = delete $init_args->{$key};
    }

    #short cut for bundling
    if  ( exists($config{':BUNDLING'}) && $config{':BUNDLING'} )
    {   # shortcut to bundling active... assure %config has it as well
        if ( !exists($config{'config'}) || 
             !grep( /^bundling$/, @{$config{'config'}} ) )
        {
            $config{'bundling'} = [ qw( bundling ) ];  #options for object
        }
    }

    # get just the regular option names in a consistent order
    my @init_keys = sort {
                      my $ret = lc($a) cmp lc($b);
                      $ret ? $ret : $a cmp $b 
                    } grep /^\w/, keys %$init_args;  

    # :ARGV is processed here by using local redirection of @ARGV
    # in a way safe for singletons.
    if ( exists($config{':ARGV'}) && defined($config{':ARGV'}) )
    {   # existence of :ARGV is pseudo configuration providing
        #  actual arguments to parse. 

        my $argv = delete $config{':ARGV'};

        local *ARGV;     #isolate @ARGV in a special way
        *ARGV = $argv;   #alias @ARGV to :ARGV argument (critical to
                         # allowing caller's :ARGV to be updated
                         # to reflect processed arguments)
        my %begin_save = %begin_options;  #now save lexicals
        my $begin_save = $begin_options;  # #
        %begin_options = ();              #reset lexicals
        $begin_options = 0;               #

        my $ret = new( $proto, \%config, $init_args );	#nested constructor call

        %begin_options = %begin_save;   #restore lexicals (@ARGV will
        $begin_options = $begin_save;   # recover when local goes out
                                        # of scope)
        return $ret;    #return object
    }

    # continue main construction
    my $warn_ref = 		#look if capturing warnings
         ( exists($config{':WARN'}) && $config{':WARN'} && 
		 Scalar::Util::reftype($config{':WARN'}) eq 'ARRAY' ) ?
		                       $config{':WARN'}  :  undef;

    my $argv_count = @ARGV;     #members in @ARGV before any :FILE inserts

    my $file_config;
    if ( ( exists($config{':FILE'}) && ( $file_config = $config{':FILE'}) )  ||
         ( exists($config{':<'})    && ( $file_config = $config{':<'})    )  )
    {   # :FILE or :< redirects to input file
	my $o = quotemeta( OPTIONAL_FILE );
        my $ref_switch = ref($file_config);     #true if object reference 
	my $file_safe = $file_config;		#save working copy of path
        my $optional;
        unless ( $ref_switch )
        {   #not reference... preprocess path
            $optional = $file_config !~ /^($o)/;   #notice if file optional
            $file_safe =~ s/^[<>+|\s[:cntrl:]]+//; #safe file path
            $file_safe =~ s/[<>|\s[:cntrl:]]+$//;  # #
        }
        if ( $file_safe =~ /\w/ )              #fail-safe check
        {   #only if $file_safe remains significant
            my $file_handle = $ref_switch ?
                                  $file_config : 
                                  IO::File->new( "<$file_safe" );
            if ( $file_handle )
            {   #prepend onto @ARGV so any conflicting user arguments can "win"
                my @lines;      #intermediate argument storage
                while ( my $line = $file_handle->getline() )
                {
                    $line =~ s/^\s+//;      #clean line
                    $line =~ s/[\r\n]+$//;

                        # NOTE: considering adding ':include' type statement
                        # if need arises.

                    next unless $line;      #ignore blank and comments
                    next if $line =~ /^#/;

                    push( @lines, $line );  #save line
                }
                $file_handle->close unless $ref_switch;
                unshift( @ARGV, @lines );
            }
            elsif ( ! $optional )
            {   #Trouble right here in River City, with a capital T
                my $warn = __PACKAGE__ . 
                            qq(: Option file "$file_safe" not found: $!\n);
                $warn_ref ? push( @$warn_ref, "die $warn" ) : carp $warn;
                return undef; 
            }
	}
    }

    my %init;
    @init{@init_keys} = @{$init_args}{@init_keys};

    $config{':BEGIN'} = 0 unless exists($config{':BEGIN'});
                #(new() defaults to 0: singleton() to 1)
    if ( $config{':BEGIN'} )
    {   # existence of :BEGIN is pseudo configuration requesting
        # options gathered up at compile time from different modules
        
        foreach my $begin ( sort keys %begin_options )
        {
            #(stupid test... should be smarter to be happy if no clashes )
            if ( exists($init{$begin}) )
            {   #key already present
                my $warn = __PACKAGE__ . ": BEGIN key $begin already used\n";
		$warn_ref ? push( @$warn_ref, "warn $warn ") : carp $warn;
            }
            else
            {   #known not present... add to list
                push ( @init_keys, $begin );
            }
            $init{$begin} = $begin_options{$begin};
        }
    }
        
        # initialize the object to all default values
    my $self = {
                  map{
                       ( my $k = $_ ) =~ s/\W.*//;
                       ( $k => $init_args->{$_} )
                     } @init_keys
               };
    $self->{'::warn'} = $warn_ref;

    #once we get this far bless object to assure %user_subs sub refs
    #can access object, such as it is, during the sub calls.
    my $class = ref($proto) ? ref($proto) : $proto;
    bless $self, $class;
    	# From this point on the DESTROY destructor will be called
        # for all failures

    # initialize internal object
    my $parser = Getopt::Long::Parser->new();
    if ( $config{':config'} )
    {   #configurations 
        my $cfg_opt = $config{':config'};
        $cfg_opt = [ $cfg_opt ] if ! ref $cfg_opt; #if 1 scalar, force array
        $parser->configure( @$cfg_opt ) if @$cfg_opt;
    }

     #parse command line options
    my @init_keys2 = map{ my $k = $_; $k =~ s/==/=/; $k } @init_keys;
        # at this time Getopt::Long does not support '==', so make '='

    my $success;
    {  #make local $getopt_obj_hash so sub references in default values can use $self
       my $caller_package;
       my $cc;
       for ( $cc = 0; $cc < 20; $cc++ )
       {   #back up to retrieve callers package
           $caller_package = caller($cc); 
           last if $caller_package && 
                   $caller_package !~ /^Getopt::Object\w*$/;
       }
       my $eval = <<"EVAL";
           package $caller_package;
           our \$getopt_obj_hash;
           local \$getopt_obj_hash = \$self;    #publish variable our caller may access
           \$success = \$parser->getoptions( \$getopt_obj_hash, \@init_keys2 );
           1;
EVAL
        eval $eval;
        if ( $@ )
        {
            carp $eval;
            return undef;
        }
    }

    #verify :FILE did not leave junk in @ARGV 
    if ( @ARGV > $argv_count )
    {   #more @ARGV elements now indicates :FILE had troubles
        my $warn = __PACKAGE__ . qq(: :FILE left dangling option "$ARGV[0]"\n);
	$warn_ref ? push( @$warn_ref, "warn $warn ") : carp $warn;
    }
    
    #verify required '==' options are present
    my @omitted =      #find any omitted options
              grep{ my $ret = undef;            #suppose all is OK
                    if ( /\w==/ )
                    {   # insist on well defined value
                        ( my $k = $_ ) =~ s/\W.*//; 	#get base key
			my $v = $self->{$k};	#$v is reference to value
			my $reftype = Scalar::Util::reftype($v) || ".";
			if ( 'SCALAR' eq $reftype )
                        {   #indirect scalar 
                            $v = $$v;        #fetch value
                        }

			if ( 'ARRAY' eq $reftype )
			{   #array reference: all values must be good
			    $ret = @$v ?
			       grep{ !defined( $_ ) || $_ eq '' } @$v :
			       1;               #true for trouble on empty
			}
			elsif ( 'HASH' eq $reftype )
			{   #hash reference: all keys and values must be good
			    $ret = %$v ?
			       grep{ !defined( $_ ) || $_ eq '' } 
                                          ( keys(%$v), values(%$v) ) :
			       1;               #true for trouble on empty
			}
			else
			{   #assume classic scalar value, even if CODE
			    $ret = !defined( $v ) || $v eq ''
			}
                    }
                    $ret 
                  } @init_keys;

    1;

    if ( @omitted )
    {
        foreach my $omitted ( @omitted )
        {
            $omitted =~ s/\|.*?=//;     #drop any aliases
            $omitted =~ s/==/=/;        #drop double ==
            $success = undef;
            my $warn = __PACKAGE__ . ": required option omitted: --$omitted\n";
	    $warn_ref ? push( @$warn_ref, "die $warn" ) : carp $warn;
        }
    }

    # finish object initialization
    $self->{'::keys'}   = \@init_keys;  #remember original keys
    $self->{'::config'} = $parser;      #remember the object

    # return object to caller
    if( $success )
    {   #good to go... polish off the object

        $begin_options++;           #count this call 
    }
    else
    {   #trouble ... caller does not get an object
        $self = $success;
    }

    return $self;
}


# singleton constructor
my $singleton;          #object to be shared by all callers

sub singleton
{
     return $singleton if $singleton;

       # check if library .pm module requesting unavailable singleton
     return undef if @_ == 1;   #singleton has not yet been called!

       # call new() with a default of :BEGIN => 2 then remember the result
     my $proto = shift;
     $singleton = new( $proto, [ ':BEGIN' => 2 ], @_ );

     return $singleton;         #return success or failure
}

# destructor... 
sub DESTROY
{
    my $self = shift;

    #older, more complex code used to do things... keeping anyway
}


# get warnings
sub getwarn
{
    my $self = shift;

    return wantarray ? @{$self->{'::warn'}} : $self->{'::warn'};
}

# provide accessor to list of known option keys
#   (key names are as originally passed, including special chars)
sub getkeys
{
    my $self = shift;

    my @copy = @{$self->{'::keys'}};
                # copy for protection of originals

    return wantarray ? @copy : \@copy;
}

# provide accessor to internal Getopt::Long::Parser object, 
# though it is worthless in the normal course of events.
sub config
{
    my $self = shift;

    return $self->{'::config'};
}

1;      #end Getopt::Object
