# Unix Specific Random::BestTiny Random Number API use strict;

package Random::BestTiny::ApiUnix;

use IO::File ();
use File::Spec ();

use vars qw( $VERSION @ISA );

$VERSION = "0.0";
@ISA = qw( Random::BestTiny );


########################################################################
#
#  API specific values
#

# best byte sizes for quality vs normal mode
use constant best_normal   => 128;    #typical short chosen to assure
                                      # we avoid any type of sign problem
                                      # on 32-bit systems.
use constant best_quality  => 16;     #"best" quality is the same as "normal"

# number of good random number levels
use constant levels        => 2;



########################################################################
#
#   Inside Out Objects and Member Definitions
#

# "inside out" objects and member definitions
my %datax;
        my $dx_ = 0;

        my $dx_best_bytes = $dx_++;     #best byte size
        my $dx_quality    = $dx_++;     #internal copy of quality

my @active;     #array of hashes
                #  [0]: low quality hashes
                #  [1]: high quality hashes
                #     hash: information on open files for quality
                #        handle =>  file handle
                #        path   =>  path to random device (for reference)
                #        count  =>  number of opens

my @devices = ( qw( urandom random ) );


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

    my $quality = (exists($args->{'quality'}) &&
                          $args->{'quality'})   ?
                                        1       : 
                                        0       ;

    unless ($active[$quality])
    {
        my $path = File::Spec->catfile( "", "dev", $devices[$quality] );
        my $handle   = IO::File->new( "<$path" );
        return $handle unless $handle;
        $active[$quality] =
           {
                path   => $path,
                handle => $handle,
                count  => 0
           };
    }

    $active[$quality]->{'count'}++;

    $datax->[$dx_best_bytes] = $self->best_bytes;       #quick access
    $datax->[$dx_quality]    = $quality;                #keep private

    return $self;
}

sub DESTROY
{
    my $self = shift;

    if ($self && exists($datax{$self}))
    {
        my $datax = $datax{$self};

      CLEAN_BLOCK:
       {
        if ($datax)
        {   #still have member object (normal case)
            my $quality = $datax->[$dx_quality];
            my $active  = $active[$quality];
            if ( $active )
            {   #always expect to come through here
                if ( --$active->{'count'} > 0 )
                {   #other objects still using file handle
                    last CLEAN_BLOCK;
                }    
                
                #last object using device... time to close
                $active->{'handle'}->close() if $active->{'handle'};
                $active->{'handle'} = undef;

                $active[$quality] = {};
            }
        }
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

    $blocksize = 0 if !$blocksize || $blocksize <= 0; #defend against wierd values

    my $best_bytes = $datax->[$dx_best_bytes];  #get quickly 

    my $true_blocks =      #get total number of whole blocks to read
                  int( $blocksize / $best_bytes ); 
    $true_blocks = 1 if $true_blocks <= 0; #minimum of one block

    my $true_bytes =            #convention: always force even multiple 
                $true_blocks * $best_bytes;

    my $buffer;
    my $n = $self->readz( \$buffer, $true_bytes );

    return $n unless $n > 0;    #return trouble

    return \$buffer;            #return reference to new randoms
}


########################################################################
#
#   read buffer
#
sub readz
{
    my ( $self, 
         $bufferRef,    #reference to scalar to read information into
         $length,       #number of random bytes to read
           ) = @_;

    my $datax = $datax{$self};
    my $quality = $datax->[$dx_quality];

    local $_;                   #since read insists a local buffer, and
    use vars ( '*_' );          # copying data from a local lexical to 
    *_ = $bufferRef;            # $$bufferRef is ineffcient, play symbol
                                # table games to point $_ to what is in
                                # $bufferRef.

    my $n = $active[$quality]->{'handle'}->read( $_, $length );
                # using read() rather than sysread() as sysread() would
                # return short blocks if not enough enthrophy is
                # available under high-qulaity reads. read() also
                # handles signal interruptions, etc., in the best manner
                # for the local system.

    return $n;
}
    
=pod

########################################################################
########################################################################

=head1 NAME

Random::BestTiny::ApiUnix - Random::BestTiny API for Unix Operating Systems

=head1 DESCRIPTION

This is the low-level Random::BestTiny class for 
UNIX operating systems, 
and other operating systems that share the 
/dev/random and /dev/urandom kernel devices for obtaining
random numbers.

A key part of the design of this class is to have only a single 
file handle open for each quality of random numbers 
regardless of how many objects of that quality are opened.

=head1 ALSO SEE

See the POD documentation in APiXxx.pod for information common to all APIs.

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Gilbert Healton.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; #end
