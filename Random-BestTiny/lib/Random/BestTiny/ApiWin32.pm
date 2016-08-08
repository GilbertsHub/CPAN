# Win32 Specific Random::BestTiny Random Number API

use Win32;
use Win32::API;

use strict;

package Random::BestTiny::ApiWin32;

use vars qw( $VERSION @ISA );

our $VERSION = '0.3';
@ISA = qw( Random::BestTiny );


########################################################################
#
#  API specific values
#

# best byte sizes for quality vs normal mode
use constant best_normal   => 32;     #typical short chosen to assure
                                      # we avoid any type of sign problem
                                      # on 32-bit systems.
use constant best_quality  => 32;     #"best" quality is the same as "normal"

# number of good random number levels
use constant levels        => 1;



########################################################################
#
#   fail-safe Win32 overrides until can better test on 64-bit systems
#

sub bytes_per_word { return  4 }


########################################################################
#
#   Inside Out Objects and Member Definitions
#

# "inside out" objects and member definitions
my %datax;
        my $dx_ = 0;
        my $dx_best_bytes = $dx_++;     #best byte size


########################################################################
#
#   Constructor and Destructors
#

sub new_
{
    my (
        $class,                       #(guaranteed class name)
        $args ) = @_;

    my $self = \do { use vars qw(*globx); local *globx; }; 
    bless $self, $class;

    my $datax = $datax{$self} = [];

    $datax->[$dx_best_bytes] = $self->best_bytes;       #quick access

    return $self;
}

sub DESTROY
{
    my $self = shift;

    if ($self && exists($datax{$self}))
    {
        my $datax = $datax{$self};
        if ($datax)
        {   #still have member object (normal case)
            1;
        }

        delete $datax{$self};
    }
}



########################################################################

sub rawz
{
    my (
        $self,
        $blocksize,
          ) = @_;

    my $datax = $datax{$self};

    $blocksize = 0 if $blocksize <= 0;         #defend against wierd values

    my $best_bytes = $datax->[$dx_best_bytes];  #get quickly 

    my $true_blocks =      #get total number of blocks
                  int( $blocksize / $best_bytes );
    $true_blocks = 1 if $true_blocks <= 0; #minimum of one block

    my $bytes_per_word = $self->bytes_per_word;
    my $bits_per_word  = $self->bits_per_word;

    my $b32 = $bits_per_word; 
    my $y4  = $bytes_per_word;

    my $CT = new Win32::API 
               "advapi$b32","CryptAcquireContextA",'PNNNN','N' ||
                     die "$^E\n"; # Use MS crypto or die

    my $buffer = "\0" x 0;      #well defined zero byte buffer

    for ( my $b = 0; $b < $true_blocks; $b++ )
    {
        # Microsoft's FIPS-compliant random number generator
        my $GR = new Win32::API "advapi$b32",  
                      "CryptGenRandom",'NNP','N' || die "$^E\n"; 

        my $rnd = "\0" x $b32;          # allocate 32-byte (256-bit)

        my $h   = "\0" x $y4;           # allocate 4-byte temporary 
        my $r = $CT->Call($h,0,0,1,0xF0000000); # Acquire context
        $h = unpack('L', $h);           # Unpack the four bytes
        $r = $GR->Call($h,$b32,$rnd);   # Call random-number generator

        $buffer .= $rnd;                #append binary bytes to return
        1;
    }

    return \$buffer;            #return reference to new randoms

}


=pod

=head1 NAME

Random::BestTiny::ApiWin32 - Random::BestTiny API for Microsoft Windows 

=head1 DESCRIPTION

This is the low-level Random::BestTiny class for 
Microsoft Windows operating systems under Active State perl,
and other perl implementations that share a 
sufficiently compatiable Win32::API module.

=head1 ALSO SEE

See the POD documentation in APiXxx.pod for information common to all APIs.

On 64-bit systems the "Win32 API for 64-bit systems" is used so the internal,
name is still Win32.
See http://use.perl.org/comments.pl?sid=42238&cid=67234 for more.

http://wiki.nil.com/Pre-Shared_Key_Generation

=head1 REPOSITORY

https://github.com/GilbertsHub/CPAN   Random-BestTiny

=head1 COPYRIGHT AND LICENSE

Copyright 2011, 2016 by Gilbert Healton.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; #end
