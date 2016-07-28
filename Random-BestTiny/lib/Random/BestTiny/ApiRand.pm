# Generic Random::BestTiny Random Number API for sytems without quality randoms use strict;

package Random::BestTiny::ApiRand;

use vars qw( $VERSION @ISA );

$VERSION = "0.0";
@ISA = qw( Random::BestTiny );


########################################################################
#
#  API specific values
#

# best byte sizes for quality vs normal mode
use constant best_normal   => 2;      #typical short chosen to assure
                                      # we avoid any type of sign problem
                                      # on 32-bit systems.
use constant best_quality  => 2;      #"best" quality is the same as "normal"

# number of good random number levels
use constant levels        => 0;


########################################################################
#
#   Inside Out Objects and Member Definitions
#

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

    $datax->[$dx_best_bytes] = $self->best_bytes;       #save for quick access

    return $self;
}

sub DESTROY
{
    my $self = shift;

    if ($self && exists($datax{$self}))
    {
        my $datax = $datax{$self};
        if ($datax)
        {   #destroy any complex member data here
            1;          #(no complex member data)
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

    my $best_bytes = $datax->[$dx_best_bytes];  #get quickly 

    $blocksize = 0 if !$blocksize || $blocksize <= 0; #defend against wierd values

    my $true_blocks =      #get total number of whole blocks to read
                  int( $blocksize  / $best_bytes );
    $true_blocks = 1 if $true_blocks <= 0; #minimum of one block

    my $true_bytes =       #convention: always force even multiple
                  $true_blocks * $best_bytes; 

    my $buffer = "\0" x $true_bytes;    #preallocate return value

    my $bits_per_word = $self->bits_per_word(); #get working bit size

    my $big = $self->unsigned_word_max();
    for ( my $b = 0; $b < $true_blocks; $b++ )
    {   
        vec( $buffer, $b, $bits_per_word ) = int( rand( $big ) );
    }

    return \$buffer;            #return reference to new randoms
}

=pod

=head1 NAME

Random::BestTiny::ApiRand - Math::Random::Secure partner API (or fail-safe API).

=head1 DESCRIPTION

This API access perl's native rand() method to generate random values.
This is used by default if the high-quality B<Math::Random::Secure> 
class is present.

The only other default use of this class happens if a normal default
B<Random::BestTiny::APiXxx> class did not initialize for the current OS.

=head1 ALSO SEE

See the POD documentation in APiXxx.pod for information common to all APIs.

=head1 LIMITATIONS

If not partnered with B<Random::BestTiny::APiXxx>
the quality of the random number is suspect as
this uses perl's native random number method.

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Gilbert Healton.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; #end
