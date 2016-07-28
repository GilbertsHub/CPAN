# Windows-specific module for Sys::Spec

use strict;

use 5.005;

package Sys::Spec::Module::Win32;

=head1 NAME

Sys::Spec::Module::Win32 - Provides Sys::Spec with information from
Microsoft Windows operating systems.

=head1 SYNOPSIS

 $true_package = Sys::Spec::Module::Win32->init_();

=head1 DESCRIPTION

This is an internal class not to be called by normal users of Sys::Spec.
Intended to be called from Sys::Spec initialization.


=head1 TRADEMARKS

MICROSOFT and WINDOWS OPERATING SYSTEM are registered trademarks
of Microsoft Corporation.

=cut 


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }
#
#   MICROSOFT WINDOWS OPERATING SYSTEM MODULE
#
use FileHandle;

use Win32;

use Sys::Spec::Module;

use vars qw( $VERSION @ISA );

$VERSION = "3.000";
@ISA = ( qw( Sys::Spec::Module ) );

my $module_values;	#hashref into Sys::Spec::Modules for common info

sub iv_sys_spec_module_win32_version
{
    return $VERSION ;
}



########################################################################
########################################################################
#
#  Try OS and Distributin Specific techniques to extract information
#  on all OSs that it even makes half-ways sense for.
#  We search every way due to cross polination of ideas between 
#  systems as well as all of the forks that go in in Linux distributions.

my @try__list;		#( name => function_ref ) list





######################################################################
#
#  one-time initialization
#	# this init_(), called by Sys::Spec initialization,
#	  assures all appropriate "Module"s are initialized.
#	# returns name of high-level package Sys::Spec is to use.
#	# The init_()'s called by this _init() return address of
#	  internal storage in Modules used to hold static information.
#	  In particular common return values (see Sys::Spec::Modules).
sub init_
{
    my (
    	$class,
	) = @_;

    Sys::Spec->insert( 		#add our stuff to master list
	qw(
	    :INTERNAL_VERSIONS
	     IV_SYS_SPEC_MODULE_WIN32_VERSION

	  ) );

    Sys::Spec->insert(		#new entries for Win32 environments
	qw(
	    :OS
	     WIN32_BuildNumber
	     WIN32_FsType
	     WIN32_MaxComplen
	     WIN32_GetArchname
	     WIN32_GetChipname
	  ) );

    Sys::Spec->insert(		#replace values that Win32 treats 
                                # very differently than historic perl
                                # environments do.
	qw(			
	    :USER		
	       UID
	       UNAME
	       UNAME_LONG
	       GID
	       GNAME
	  ) );

	     
    $module_values = $class->SUPER::init_();

    $class->try_files_( \@try__list );

  {
     my ( $string, $major, $minor, $build, $id ) = Win32::GetOSVersion();

    my $osname = Win32::GetOSName();
    $module_values->{'os_d_vendor'} = "Microsoft" if $osname =~ /^Win/;
    $osname .= "; $string" if defined($string) && $string =~ /\S/;
    $module_values->{'os_d_release'}  = $osname;
    $module_values->{'os_d_codename'} = undef;
  }

    #  TO_DO...
    #Win32::LoginName();

    return ( __PACKAGE__ );
}

sub uid			{ return undef }
sub uname		{ Win32::LoginName() }
sub uname_long		{ return undef }
sub gid			{ return undef }
sub gname		{ return undef }

sub win32_buildnumber
{
    return Win32::BuildNumber();
}

sub win32_fstype
{
    my (
        $self,
	$dataRh,
       ) = @_;

    my ( $fst, $flags, $maxcomplen ) = Win32::FsType();
    $dataRh->{"tmp"}{"win32_maxcomplen"} = $maxcomplen;
    my $return = sprintf( '%s/0x%08x:', $fst, $flags );
    my $map = {
	0x00000001  => "case-sensitive names",
	0x00000002  => "preserves case",
	0x00000004  => "Unicode",
	0x00000008  => "preserve/keep ACLs",
	0x00000010  => "file-based compression",
	0x00000020  => "disk quotas",
	0x00000040  => "sparse files",
	0x00000080  => "reparse points",
	0x00000100  => "remote storage",
	0x00008000  => "compressed volume",
	0x00010000  => "object identifiers",
	0x00020000  => "EFS", };
    my $delim = "";
    foreach my $key ( sort keys %$map )
    {
	if ( $flags & $key )
	{
	    $return .= $delim . $map->{$key};
	    $delim = "; ";
        }
    }
    return $return;
}

sub win32_maxcomplen
{
    my (
        $self,
	$dataRh,
       ) = @_;

    return $dataRh->{"tmp"}{"win32_maxcomplen"};
}


sub win32_getarchname
{
    my $return = exists( $ENV{'PROCESSOR_ARCHITECTURE'} )
    		       ? $ENV{'PROCESSOR_ARCHITECTURE'} 
		       : Win32::GetArchName();
}

sub win32_getchipname
{
    return Win32::GetChipName();
}


######################################################################

=pod

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

1;

#end
