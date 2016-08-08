# Common Module processing for Sys::Spec

use strict;

use 5.005;

=head1 NAME

Sys::Spec::Module - Common code for many of the Sys::Spec::Module;:* modules.

=head1 USAGE

From within a OS-Xyz specific Sys::Spec::Module::Xyz module:

 use strict;

 package Sys::Spec::Module::Xyz;

 use Sys::Spec::Module;

 use vars qw( $VERSION @ISA );

 $VERSION = "1.000";
 @ISA = ( qw( Sys::Spec::Module ) );

 # one-time initialization... called during Sys::Spec initialization.
 sub init_
 {
    my ( $class ) = @_;

    my $module_values = $class->SUPER::init_();	#init Sys::Spec::Module

    	# (omit if no variables to register for THIS specific module)
    Sys::Spec->insert(	 	 #register any variables with Sys::Spec
	   qw(
	       :INTERNAL_VERSIONS
		 IV_SYS_SPEC_MODULE_XXX_VERSION
	     ) );

    .... any useful initialization code goes here ....

    #optional: if a series of distribution-specific searches needed
    $class->try_files_( \@try__list );

    return ( __PACKAGE__ );	#returns package
 }

=head1 DESCRIPTION

This module, and all of its methods,
are internal to Sys::Spec
and must not be called by application programs.
All documentation herein targets developers using Sys::Spec::Module classes
to extending Sys::Spec for supporting new operating systems or 
enhancing support of operating systems already supported by Sys::Spec.

Provides os_d_vendor, os_d_release, os_d_codename,
methods to all Modules.
It is strongly recommended that os-specific modules populate these values.

=head1 AVAILABLE METHODS

=over +2

=over +4

=cut


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }
#
#   OS SUBCLASS
#
package Sys::Spec::Module;

use POSIX;

our $VERSION = '3.001';

$VERSION = "3.001";
## NO NO NO!  See note in Sys::Spec.pm: @ISA = ( qw( Sys::Spec ) );

sub iv_sys_spec_module_version
{
    return $Sys::Spec::Module::VERSION;
}

########################################################################

my %module_values;	#static area for holding values 

sub os_d_vendor
{
   return $module_values{'os_d_vendor'}
	if exists $module_values{'os_d_vendor'};
}

sub os_d_release
{
   return $module_values{'os_d_release'}
	if exists $module_values{'os_d_release'};
}

sub os_d_codename
{
   return $module_values{'os_d_codename'}
	if exists $module_values{'os_d_codename'};
}



######################################################################

=pod

=item my $module_values_hashref = $class->SUPER::init_()

Initializes Sys::Spec::Module, and perhaps associated modules.

Returns hash reference to a static area information to the caller 
can be saved in.
The following keys are supported by Sys::Spec::Module if
the caller chooses to populate them:

=over +2

B<os_d_vendor>: vendor distributing this release of the OS.

B<d_os_release>: release of this vendors distribution of the OS.
This is intended for systems,
such as Linux, where multiple vendors release distributions of it.

B<d_os_codename>: 
any code name the vendor applies to the current OS,
if Sys::Spec can determine it.

=back

=cut

sub init_
{
    my (
    	$class,
	) = @_;

    %module_values = ();

    Sys::Spec->insert(
       qw(
	    :INTERNAL_VERSIONS
	      IV_SYS_SPEC_MODULE_VERSION
	 ) );

    Sys::Spec->insert(		#add our stuff to master list
	qw(
	    :OS
	     OS_D_VENDOR
	     OS_D_RELEASE
	     OS_D_CODENAME
	  ) );

    return ( \%module_values );
}

########################################################################
#
#   TRY KNOWN FILES
#	# the first caller of this is Sys::Spec::Modules::Unix.
#	# the @try__list defines class functions to call.
#	# the order the functions are defined in determines the order
#	  they are invoked (see push statements). THIS ORDER IS IMPORTANT.
#
=pod

=item $class->try_files_( \@try__list )

Step through a series of options to obtain 
distribution specific information,
typically in files.
Each step represents a distribution-speicifc extraction option.
Stepping stops once the desired information has been collected.

The argument is an array of hash references,
one for each distinct distribution extraction method.
Each hash supports the following keys:

=over +2

B<file>:
path to the distribution specific file.
Creative developers may pass information other than file paths here.

B<sub>:
reference to subroutine to call to attempt to extract the information
for the current step.

The subroutine is passed the file name,
as obtained from the B<file> key.

The function returns true if the information has been extracted.
This prevents any further subroutines in the array from being called.

B<perl_os>:
Optional value that must be the name of the OS,
as known to perl's B<$^O> variable,
that the subroutine applies to.
If defined,
the subroutine is not called unless B<$^O>
I<exactly> matches this value.

=back

Returns false if values were not extracted.
Else returns the same true the called subroutine returned.

=cut


sub try_files_
{
    my (
    	$class,
	$try__list,	#array of hashrefs providing functions to "try"
			#   key   => os type, as known to $^O.
			#   value => hashref to associated value
			#            file: path to file to open
			#            sub:  coderef to sub to call sith
			#                  $class->$subref($file) signature.
			#	     os:   specific OS type to call under
			#	           (not called on mismatch, always
			#	           called if omited or false)
	) = @_;

    my $perl_os = $;  #get official OS name, as known to perl
			# (does NOT require prior initializations, etc.)


    for ( my $f = 0; $f < @$try__list; $f++ )
    {
	my $list = $try__list->[$f];

	my $file   = $list->{'file'};
	my $sub    = $list->{'sub'};
	my $try_os = undef;
	$try_os = $list->{'perl_os'} if exists $list->{'perl_os'};

	my $return = $class->$sub($file) 
		if !defined($try_os) 
                  || $try_os =~ /^$perl_os\b/i;

	return $return 		#return if found enough
		if defined($return) && $return;
    }

    return 0;
}



1;

__END__

=pod

=back

=back

=head1 REQUIREMENTS

=over +2

=over +2

=item *

Sys::Spec::Module::Xyz modules 
I<Must not> specifiy C<@ISA = ( ... Sys::Spec )>:
this ISA chain is handled in a different way.

=item *

Call C<Sys::Spec-E<gt>insert(>...C<)> to register any methods that 
return possible variable values. insert() takes a single argument 
providing an arry ref.

The first array member must select the heading, in Sys::Spec's @master_list,
the variable is to be associated with.
This is a string starting with a ":" followed by a name that could be 
used as a variable.
A new heading may be generated simply by mentioning it.

The heading section is followed by entries providing names of any
variables defined by the module.
Variable names should be upper case and
their matching function names I<must use all lower case.>

See Sys::Spec->insert() documentation for additonal details,
though note the registered subroutine argument lists are different.

=item *

The registered function names are called 
as described in Sys::Spec documentation,
except the arguments are different.
The first argument is the class name,
the second is a hash reference to 
internal static storage for the current 
Sys::Spec object.
And the third is the called subroutine name.

The hashref has a reserved key of C<{'tmp'}>,
which is another hashref for use during constructor operations.
Module functions registered with B<insert>() 
can save information herein to pass to further functions
down the chain of functions I<in the same B<insert>() call>.

The C<{'tmp'}> hashref is deleted
just before the B<new>() method returns to the caller.

=back

=back

=head1 COPYRIGHT, LICENSE, and WARRANTY

This program and documentation is copyright 2008 by Gilbert Healton.
All rights reserved.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head2 NO WARRANTY

Because the program is licensed free of charge, there is no warranty.

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
WARRANTIES, INCLUDING, WITHOUT LIMITATION, 
THE IMPLIED WARRANTIES OF MERCHANTIBILITY
AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#end
