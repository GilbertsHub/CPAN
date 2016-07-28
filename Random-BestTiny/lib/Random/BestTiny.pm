# Random::BestTiny - best light-weight random numbers OS can provide 

use strict; package Random::BestTiny;

use Config ();
use File::Spec ();
use Carp;

use Random::BestTiny::moduleList;

use vars qw( $VERSION );

$VERSION = "0.0";

=pod

=head1 NAME

Random::BestTiny--Best light-weight, low-voume, 
random numbers typical OS can provide.

=head1 USAGE

 use Random::BestTiny;                  #typical use - selects best for OS
 use Random::BestTiny module => 'Xxxx'; 
                                 #force Random::BestTiny::APIXxxx module

 $ros = Random::BestTiny->new();                  #low quality numbers
 $ros = Random::BestTiny->new( quality => $q );   #quality $q numbers
 $ros = Random::BestTiny->new( quality => $q, mode => 'Xxxx' ); #force 

 $bytes = $ros->randbytesz();  #return series of random bytes in scalar
 $r = $ros->randz( $n );       #random float number in the range of
                               #   (0 <= $r && $r < $n)
 @r = $ros->randz( $n, $cnt ); #produce $cnt random numbers

 # random values in different formats
 $bytes = $ros->bytesz( $n );  #produce $n random bytes in scalar

 $bits_per_word  = $ros->bitsz( $n, $bits_per_word ); #produce random bits

 # support methods -- not used by typical caller
 $best_info  = $ros->best_info();   #optimization information
 $best_bytes = $ros->best_bytes();  #best random block size
 $q = $ros->quality();         #return quality state set by constructor
 $best_bytes = $row->best_bytes(); #randbytesz() preferred byte count 

 $scalarref = $ros->rawz($n);  #access low-level 
                               # Random::BestTiny::$OsType class.
                               # effecient, but $n must be even multiple 
                               # of ->best_bytes().

=head1 DESCRIPTION

This class overcomes the typical quality limitations of perl's 
built-in rand() method by making use of the fact that
most modern operating systems have ways of providing 
high-quality random numbers,
at least in limited quantities,
using an "entropy pool" gathered as the OS works.
B<Rand::BestTiny> provides perl programs access to these numbers.

While B<Math::Random::Secure> is a larger, more complex, 
CPAN library that can be used to get both better and more secure 
random numbers, 
installing it can add over 40 modules to your system 
and is overkill for some applications.
Instlling it can lead to robust experiences in compile errors.

Unlike B<Math::Random::Secure>,
B<Random::BestTiny> does not change the built in rand() function of perl.
Thus object-oriented calls must be used to get random numbers.

Note the complete lack of a seed method in this class.

=cut




########################################################################
#
#   Internal Variables
#
# default values
my $module_default;     #module to use (static value, once set)
my $class_api_default;  #full class name of default module


########################################################################
#
#   Private Methods (no POD documentation for these)
#

#will populate with references to anonymous subs
my $_init;                      #common initilization 
my $_init_module;               #assure current module initialized

{                            #limit scope of hardware lexicals
#
#   hardware definitions
#
my $bits_per_byte = 8;       #bits-per-byte without relying on .h/.ph file
                             # assume 8-bit bytes
                             # (while Gilbert Healton has used 9-bit byte 
                             #  systems in the past, thankfull every one he
                             #  has seen, or even heard of, is not up to 
                             #  running perl...  but just in case this 
                             #  uglyness ever strikes we have this definition.
my $bytes_per_word;             # (typically 4 or 8)

# 
#   Common Initialization
#       # avoid POD as not to corrupt user man pages with internal stuff
#       # one-time initilization for this class
#       # no arguments or return value
#       # need not be called if $bytes_per_word true
$_init = sub            #internal one-time init
{
    my $explicit = shift;      #explicit module (from importer)

    unless ($bytes_per_word)
    {   #this is where we figure out the largest integer size we can
        # safely bit twiddle with for the local hardware.
        #need to very carefull in getting a proper answer for the 
        # "random" domain.
        #In particular OSes tend to use integer values to build randoms,
        # limiting the significant bits to that of integers
        # rather than the greater precisions under floating points.
        #Worse, the integers are limited to the true integer precision
        # of the hardware and not any artifical values, such as "longlong"
        # supported by software only in so many 32-bit machines.
        #sorry for the mess, but I found I needed to find values that worked.
     FIND_WORD_SIZE_SECTION:
       { 
        use integer;            #work with underlying integer precision


        # iterate across all possible sizes (shortsize is fail-safe)
        for my $try_key ( qw( longlongsize longsize intsize shortsize ) )
        {   #if one of these doesn't work, soemthing is seriously wrong
            if (exists($Config::Config{$try_key}))
            {     #size is known, but is it artifical?

                  #test with all the paranoia I've developed over decades
                  # of of bugs in precision and shift signs
                  my $bytes_try_word = $Config::Config{$try_key};
                  my $bits_try_word  = $bytes_try_word * $bits_per_byte;

                  my $int_negative  = 1 << ( $bits_try_word - 1 );
                  my $int_positive  = 1 << ( $bits_try_word - 2 );
                  my $int_half      = 1 << ( $bits_try_word - 3 );  #one-half try 

                  if ( $int_positive > 128  &&       #no integer overflow, and
                       $int_half < $int_positive &&  #no integer truncation,and
                       $int_half * 2 == $int_positive && #total success test
                       $int_negative < 0 )
                  {  #seems good on overflow... now dig into floating point
                    
                     no integer;        #flip back to float for a moment
                     my $real_positive  = 1 << ( $bits_try_word - 1 );
                     my $real_sqrt      = 1 << ( $bits_try_word / 2 - 1 );
                     
                     if ( $real_positive > $real_sqrt  &&
                          $real_positive >= $int_positive )
                     {   #success!
                         $bytes_per_word = $bytes_try_word;

                         last FIND_WORD_SIZE_SECTION;   #all done
                     }
                  }
            }
        }

        # loop did not find success... go very very fail-safe (and ugly/slow)
        #   (something is horribly wrong if we get here... but 
        #    keep production going)
        carp __PACKAGE__ . "->new() failed to find word size";
        $bytes_per_word = 1;
       }
    }

    if ($explicit)
    {   #explicit module: use it ragardless of how bad the choice is
        $module_default = $explicit;
    }
    elsif (defined($Math::Random::Secure::VERSION))
    {   #assume Math::Random::Secure is active, which overrides
        # native rand() with a much improved random generator.
        #Use if it we got it, but understand it's a heavy in size and
        # (already done) overhead.
        $module_default = 'Rand';
    }
    else
    {   #typical case uses OS-specific API
        $module_default = Random::BestTiny::moduleList::module_();
    }
        
    $class_api_default = __PACKAGE__ . "::Api$module_default";   #default class

    &$_init_module({             #initialize the default module
                      class_api  => $class_api_default,
                  });

    return 1;           #success
};


#
#   Initialize specific module
#       # avoid POD as not to corrupt user man pages with internal stuff
#       # one-time initilization for a module
#       # arguments: hash with following key/value pairs
#          # class_api   => full name of class to use
#
my %modules_seen;       #tracks modules actually used. typically just default.


$_init_module = sub
{
    my (
        $args ) = @_;

    my $class_api = $args->{'class_api'};
    return 2 if $modules_seen{$class_api};      #already initialized

    eval qq{require $class_api};    #require as class, not file
    return undef if $@;             #trouble

    return $modules_seen{$class_api} = 1;  #success
};


########################################################################
#
#   Hardware Related Methods
#       # Returns Random::BestTiny's view of local hardware, which can
#         be artifically different from reality to keep Random::BestTiny 
#         working well. 
#       # Subject to override by derived class needing alternate versions
#       # avoid POD as not to corrupt user man pages with internal stuff
#       # Application developers call these methods at their own risk.
########################################################################
#

sub bits_per_byte { $bits_per_byte }  #CHAR_BIT w/o relying on any .h

# The "word" size is the fundamental integer size this class works with,
# which may need to be shorter than the word size of the local hardware.
# The size chosen here must not produce sign errors, or any other artifacts,
# across all Random::BestTiny operations, including the API class.

sub bytes_per_word
{
    return $bytes_per_word;
}

sub bits_per_word 
{ 
    my $class_or_self = shift;

    return $class_or_self->bytes_per_word * $class_or_self->bits_per_byte;  
}

sub signed_word_max
{
    my $class_or_self = shift;
    return ( 1 << ( $class_or_self->bits_per_word - 1 ) ) - 1;
}

sub unsigned_word_max
{
    my $class_or_self = shift;
    return ( 1 << ( $class_or_self->bits_per_word - 1 ) ) * 2 - 1;
}

}

########################################################################
#
#   pseudo-importer that really selects the module
#       # being a well written class, nothing is exported, which
#         allows us to hijack &import() for our own purposes.
#       # We use the import method as a hook to allow callers to select 
#         the random number API on 'use' arguments.
#       # if module type is not explicity given, then the module
#         selection is deferred until the first call.
#
sub import
{
    my $class = shift;

    my %args = @_;

    if ( exists($args{'module'}) )
    {
        my $explicit = $args{'module'};

        if ( $module_default )
        {
           if ( $module_default ne $explicit )
           {
               carp qq(Too late for "use Random::BestTiny ( " .
                                        "module => \$explicit )" );
           }
       }
       else
       {   #have not yet decided... force the issue
           &$_init($explicit);
       }
    }
}


########################################################################
#
#   Member definitions kept as inside out objects
#       (Moose is not available in core perl, at least in vintages I would
#        need, and Random::BestTiny is not to have ANY non-core dependencies)
#

my %datax;
    my $dx_ = 0;      #(offset into inside out object members)

    my $dx_quality    = ++$dx_;     #quality, 0 (normal) or 1 (high)
    my $dx_module     = ++$dx_;     #module for this specific object
    my $dx_shared_api = ++$dx_;     #@shared hashref approprate to object


########################################################################
#
#   Class wide definitions
#
# As operating system APIs to random numbers tend to return a random 
# series of random binary bytes rather than conventional numbers, 
# provide ways to extract these bytes.
#   # Some OS APIs return a fixed number of bytes. 
#   # Some OS APIs can return a variable number of bytes.
# The following "shared" information allows each quality of an API to
# share buffers across all objects of the same quality.
# This gets important as fixed-length APIs tend to return more
# random bytes than typical calls need making it important to
# buffer them up somewhare for use in future calls to keep byte
# consumption low.

my @shared;        #array of hashes for quality related info for each quality.
#                  #  index is quality [0] low; [1] high.
#                  #  Each hash of information tracked for each API
#                  #     key: API name (full name of class)
#                  #     value: hash ref for details
#                  #        buffer  => original buffer of random bytes
#                  #        offsets => corresponding offset into buffer
#                  #        objects => number of current objects active
#                  #each combination of API and quality gets a dedicated
#                  # hashref to assure we do not mix bytes from
#                  # different APIs or qualities. 



########################################################################
#
#   Constructor and Destructors
#

=pod

=over 2

=item Random::BestTiny->new({\%args})

Create a new random number object to return numbers of the 
indicated quality.

The arguments are provided as a hashref with the following
key/value pairs:

=over 2

=over 8

=item quality => $bool

True if the highest quality random numbers are being requested.
On some implementations this can be notabily slower than the
low-quality random numbers.
If repeated high-quality random numbers are requested
the calls may block for periods of time on some
popular implemntations.

False, or omit, if a lesser quality random number is suffcient.
Such might not be suitable for higher quality cryptograpiclly 
secure applications:
only your local OS knows for sure.
Low-quality call times will never be longer than that of 
high quality random numbers and can be considerably faster.

It is possible,
even encouraged,
for an application to obtain both low and high 
quality objects for different parts of the operation.

This argument is ignored on systems with only one quality 
of number.

=item module  => $Xxxx

Indicates the module to use. 
Typically omitted to use the default value.

=back

=back

=cut

sub new               
{
   my (
        $proto,
        $args ) = @_;

   &$_init() unless $module_default;

   my $module_new    = $module_default;    #suppose default module & API
   my $class_api_new = $class_api_default; # #

   if ( exists($args->{'module'}) && $args->{'module'} )
   {    #caller requesting specific module and API
        $module_new = $args->{'module'};

        $class_api_new = __PACKAGE__ . "::Api$module_new";   #class to use

        return undef
                unless &$_init_module({ class_api => $class_api_new });
   }

   my $self = $class_api_new->new_( $args );
   my $datax = $datax{$self} = [];      #initilize inside-out object

   my $quality = $datax->[$dx_quality] = (exists($args->{'quality'}) &&
                                                 $args->{'quality'})   ?
                                                               1       : 
                                                               0       ;
   $datax->[$dx_module] = $module_new;

   my $shared = $shared[$quality];
   unless ($shared)
   {   #first time for this quality
       $shared = $shared[$quality] = {}; 
   }
   unless (exists($shared->{$module_new}))
   {  #first time for this API
      $shared->{$self} = {
                            buffer  => "\0" x 0,   #well defined empty string
                            offsets => 0,          #nothing in string, yet
                            objects => 0,          #zero usage count
                         };
   }

   my $shared_api = $datax->[$dx_shared_api] = $shared->{$self};

   $shared_api->{'objects'}++;                  #count this object

   return $self;
}

sub DESTROY
{
    my $self = shift;

    if ( $self && exists($datax{$self}) )
    {
        my $datax = $datax{$self};
        if ( $datax )
        {   #any complex member data should be explicitly destroyed here

          RELEASE_SHARED_BLOCK:
           {
            my $shared_api = $datax->[$dx_shared_api];  #shared info
            if ( $shared_api )
            {   #we have information shared among all objects of this quality

                if ( defined($shared_api->{'objects'}) &&
                             $shared_api->{'objects'}-- > 0)
                {   #more objects remain for this quality and API
                    last RELEASE_SHARED_BLOCK;
                }

                # this was the last object of this quailty && API or
                #   table was corrupted. clean out
                my $quality = $self->quality();
                delete $shared[$quality]->{$datax->[$dx_module]};
            }
           }

           $datax->[$dx_shared_api] = undef;    #always clear complex value
        }

        delete $datax{$self};
    }
}


########################################################################
#
#   Public Random Number APIs
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

=pod

=item $ros->randbytesz( [ $blocksize [, $blockcount ] ] )

Return a scalar, or array of scalars,
containing blocksize random bytes.

=over 2

=over 12

=item blocksize

Optional number of random bytes to return in each block.
Defaults to number of bytes in local systems
"word size" (typically largest true integer) values.

=item blockcount 

Optional number of blocksize blocks to return.
Defaults to 1.

Values greater than 1 are discouraged on high-quality objects as 
reading large numbers of high-quality bytes may "block" the application.

=back

=back

Array context: returns array of blockcount blocksize blocks.

Scalar context: when $blockcount is 1, or defaults to 1,
returns a single string of $blocksize random bytes.
Else returns array reference to $blockcount blocks of 
$blocksize random bytes.

Note: this is the most effcient high-level Random::BestTiny API 
to random values.
Using $blocksize that is an even multiple of $ros->best_bytes() 
is most effcient of all.

=cut

sub randbytesz
{
    my (
        $self,
        $blocksize,     #optional bytes to fetch in each block
        $blockcount,    #optional number of blocks to fetch
       ) = @_;

    my $datax = $datax{$self};
    my $shared_api = $datax->[$dx_shared_api];

    my $bits_per_byte = $self->bits_per_byte();   #bits in a byte

       # assure have something to read
    $blocksize = $self->bytes_per_word()          #assure
          if ! $blocksize || $blocksize <= 0;

    $blockcount = 1 if !$blockcount or $blockcount <= 0;

    my $best_bytes = $self->best_bytes();

    my $true_blocks = undef;     #block count to actually read

    my @return;

    for ( my $b = 0; $b < $blockcount; $b++ )
    {   #for each block requested by caller

        my $random_bytes;

        if ( $blocksize % $best_bytes == 0 )
        {   #even multiple... dive directly into raw
            $random_bytes = ${$self->rawz( $blocksize )};
        }
        else
        {   #doing things the hard way
            $random_bytes = "\0" x 0;    #initialize bytes to return

            my $quality = $self->quality();     #quality as 0/1 index

            while ( length($random_bytes) < $blocksize )
            {   #need to build up

                my $available = length($shared_api->{'buffer'}) -
                                       $shared_api->{'offsets'};
                if ( $available <= 0 )
                {   #need to get more
                    if ( !$true_blocks )
                    {
                        $true_blocks = 1;     #blocks to read (for now)
                                # NOTE: as this is "tiny", and not for
                                #  large blocks, we just keep it 
                                #  simple for now
                    }
                    $shared_api->{'buffer'} = ${$self->rawz($true_blocks)};
                    $shared_api->{'offsets'} = 0;

                    $available = length($shared_api->{'buffer'});
                }

                #grab from working
                my $use = $available <= $blocksize ? 
                                        $available :  #use em up
                                        $blocksize ;  #just enough
                $random_bytes .= substr( $shared_api->{'buffer'},
                                         $shared_api->{'offsets'},
                                         $use );
                $shared_api->{'offsets'} += $use;
            }
        }

        push @return, $random_bytes;

    }
    
    return @return if wantarray;
    return $return[0] if $blockcount <= 1;
    return @return;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

#:## get hexadecimal random number
#:#sub randhexz
#:#{
#:#    my (
#:#        $self,
#:#        $n,
#:#          ) = @_;
#:#
#:#    my @return = $self->rawz( $n );
#:#
#:#    my $return;
#:#    foreach my $r ( @return )
#:#    {
#:#        my $p = sprintf( "\%04x", $r );
#:#
#:#        $return .= $p;
#:#    }
#:#
#:#    return $return;
#:#}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# get character version
#:#sub rand32base64z
#:#{
#:#    my (
#:#        $self,
#:#        $n,
#:#          ) = @_;
#:#
#:#    my @return = $self->raw32z( $n );
#:#
#:#    my $return;
#:#    foreach my $r ( @return )
#:#    {
#:#        my $p = encode_base64($r,"\0");  # Convert binary to ascii
#:#        chop($p); chop($p);           # Remove final '='
#:#
#:#        $return .= $p;
#:#    }
#:#
#:#    return $return;
#:#}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# based on perl's rand()

=pod

=item $ros->randz($max,$cnt)

Returns random numbers from zero, up to, but not including,
the maximum size given on the argument.

=over 2

=over 6 

=item $max

Optional upper limit of values.
Defaults to 1.

=item $cnt

Number of values to return.

=back 

=back

In array context returns array of values.
In scalar context returns scalar value if $cnt == 1, 
else return reference to array of scalars.

=cut

sub randz
{
    my (
        $self,
        $max,
        $cnt,
       ) = @_;

    my $uFormat = 'l!';         #unpack's system-dependent "long" format

    my $bits_per_word      = $self->bits_per_word();   
    my $unsigned_word_max  = $self->unsigned_word_max();  #max shift size 

        #default to largest integer for system
    $max = 1 if $max <= 0;
        # NOTE: as perl is working in floating point we can handle 32-bit
        # positive numbers just fine. But as not all of our callers might.
        # the default is to use 31 bits to remain positive in 
        # everyones perspective.

    my $divisor = $unsigned_word_max / $max;   #get appropriate divisor

    my @randoms;
    my $cntMax = ( $cnt && int($cnt) > 0 ) ? int($cnt) : 1;

    for ( my $c = 0; $c < $cntMax; $c++ )
    {
        my $random_raw   = $self->randbytesz($self->bytes_per_word);
        my $random_value = vec( $random_raw, 0, $bits_per_word );
        $random_value = -$random_value if $random_value < 0;  #assure positive
        push( @randoms, $random_value / $divisor );
    }

    # array wanted
    return  @randoms if wantarray;
    return $randoms[0] if @_ <= 2 || $cntMax <= 1;
    return \@randoms;
}


########################################################################
#
#   Accessor Methods
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

=pod

=item $ros->quality()

Returns true if the current object is set for high-quality random numbers.

=cut

sub quality
{
    return $datax{$_[0]}->[$dx_quality];
}


#
#   View Of The Local Operating System
#
#     # "Module" stuff shamelessly stolen from File::Spec, but 
#       commenting out systems I have no access to but hope others will
#       augment with.
#          # Critical code put in Random::BestTiny::moduleList;
#     # Likley will grow in different ways than File::Spec so consider the 
#       local OS concepts specific to Random::BestTiny's point of view, 
#       which can easily break if used outside of random number generation.
#

=pod

=item $code = Random::BestTiny->module();
=item $code = $ros->module();

Identifies the API being used to generate random numbers.

The first method, the class call, returns the default module for the
local OS.

The second version, the method call, returns the module being used
for the current object.

=cut

sub module
{
    my $class_or_self = shift;

    &$_init() unless $module_default;

    if (ref $class_or_self)
    {   #object call... return specific module name
        return $datax{$class_or_self}[$dx_module];
    }
    else
    {   #class call: return default module
        return $module_default;
    }
}


=pod

=item $ros->best_info()

Returns a hashref containing
various information about the current random number API that
applications can make use of to improve their portability or efficency 
across different platforms and other environments.

Restrictions: Many and important:

=over 2

=over 2

=item *

The perspective of the OS type is very much limited to 
the API Random::BestTiny selected for the OS
is unlikley to port well to most other uses.

=item *

Implemented for internal use by Random::BestTiny, but made public for
what should be rare use by outsiders when callers 
need to know this information to make better use of 
Random::BestTiny. 

While such use by outsiders likely indicates a bad spot in the logic,
in the real world of legacy applciations you might be stuck with it.

The $ros->best_info() method is more trustworthy on getting 
key attributes about random numbers.

=back

=back


The following key/value pairs are present in the hash:

=over 2

=over 6

=item best_bytes

Optimal bytes to read at the current object's quality.

=item normal_quality

Optimal bytes to read at the "normal" quality.

=item best_quality

Optimal bytes to read at the "best" quality.
If different from "normal" it is assured that there are separate 
high quality numbers.
However nothing is proved if the values are the same.

=item levels

Avaiable quality levels for random numbers:

=over 2

=over 3

=item 2

System has both high and normal-quality random numbers.

=item 1

System only supports one quality level for random numbers.
Though they should have resonable cryptograpic quality,
it may be wise to understand more if serious quaility is required.

There will be no difference in quality between
the "high" and "normal" levels.

=item 0

This system is known not to support
cryptographically secure random numbers,
of if it does,
there is no current B<Rand::BestTiny> API to it.

=back

=back

=item quality

True if current object uses high-quality random numbers.

=back

=back

NOTE:
while the information herein is available via various 
public and internal methods,
this is the recommended method for applications to
get information from API level internal methods.

=cut

sub best_info
{
    my $self = shift;

    return {
         # information also available elsewhere
        quality      => $self->quality(),
        best_bytes   => $self->best_bytes(),

         # information coming directly from API
        best_normal  => $self->best_normal(),
        best_quality => $self->best_quality(),
        levels       => $self->levels(),
           };
}

=pod

=item $ros->best_bytes()

Returns the best_bytes value, as found in $rbos->best_info().
Intended for quick access to this commonly used value.

=cut

sub best_bytes
{
    my $self = shift;

    return $self->quality()   ? 
        $self->best_quality() : 
        $self->best_normal()  ;
}


########################################################################


=pod

=back


=head1 RANDOM INTRODUCTION 

The historic pseudo-random number generators based on the
randu() and rand() functions 
were often good enough back before the archaic days of the '90's
but simply do not hold up to producing random numbers that are 
crypographiclly secure in modern contexts,
modern engineering applictions, mathmatical theories, 
or even computer science operations.

While many extensions to the classic pseudo-random number generators
have been built,
and are much improved,
they still at heart are pseudo-random number generators. 

Today most modern operating systems can produce random numbers of much 
higher quality for applications.
While the theory of how such work is beyond this INTRODUCTION
(but look for a not-yet-existant Random::BestTiny::More document), 
be aware that the way these routines work, 
varies from OS to OS.
See LIMITATIONS for common limitations developers need to be aware of.

The Random::BestTiny class is designed to provide perl developers with
a consistent API to the local quality random number generator.

Some operating systems have two-levels of random numbers:

=over 2

=over 3

=item *

A higher quaility, which might be produced at a slower pace.
Some popular systems will even "block" for short periods of times
if depeleted pools of quality random numbers build up again.

=item *

A lower quality number, 
usually much better than pseudo-random number generators, 
that are produced as fast as needed.

=back

=back

While the best random numbers come from special hardware,
not many computers come with such yet.
And if available, Random::BestTiny could be extended to connect to them.

Cryptograpically secure applications may need to stick with
sparing use of high quality numbers.


=head1 HISTORY

Gilbert Healton got interested in random numbers while still in college,
mostly because the classic "pseudo" random numbers were not up to doing
what was wanted at the time.
Then sometimes the local OS did not have a decent generator so
Knuth's "randu" was ported to the local OS, 
often modified to gather some enthrophy from the local OS to seed it.

Gilbert revisited random numbers at irregular intervals for the same reason.
The "/dev/random" and "/dev/urandom" devices were pounced on when they
became available under Linux, and later other operating systems. 

Microsoft Windows remained the remaining nut to crack, 
but that changed once a web search turned up an early sample of code now
best described under the Wikipedia article at:

    http://en.wikipedia.org/wiki/CryptGenRandom

As Gilbert currently does not have access to other operating systems 
Random::BestTiny only works with UNIX compatiables and 
Microsoft Windows operating systems with the known APIs.
It is hoped that others can contribute APIs for other popular systems
that are not currently supported.

Somehow Gilbert missed the Math::Random::Secure,
but upon installing it found that while the functionality of it was great 
the installtion could be complex if the many modules it requires 
did not neatly install cleanly. 

Random::BestTiny however is only a few pure perl files and is esay to install.

=head1 LIMITATIONS

Most of the following limitations do not apply to conventional
general purpose operating systems,
especially servers,
that have been running for hours on end.

=over 2

=over 2

=item *

Freshly booted systems may have very small pools of quality 
random numbers.
This problem can be more accute on relatively simple systems booting from 
read-only media, such as CDs, or in kiosk envronments.

=back

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Gilbert Healton. 

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; #end
