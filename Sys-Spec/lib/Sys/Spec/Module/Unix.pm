# UNIX-specific module for Sys::Spec

use strict;

use 5.005;

package Sys::Spec::Module::Unix;

=head1 NAME

Sys::Spec::Module::Unix - Provides Sys::Spec with information from
UNIX compatiable operating systems.

=head1 SYNOPSIS

 $true_package = Sys::Spec::Module::Unix->init_();

=head1 DESCRIPTION

This is an internal class not to be called by normal users of Sys::Spec.
Intended to be called from Sys::Spec initialization.

Gather additional information on UNIX operating systems,
POSIX operating systems, 
and sufficiently compatible operating systems
such as LINUX distributions.

For systems like Linux, which have multiple distributions,
an attempt is made to return distribution specific information as well.
Currently this is vendor, distribution release, and vendor's code name.

"uname" information previously obtained by the B<Sys::Spec> super class
reports the basic information about the system.
The results of this call determine how any additional details
on the system are obtained.

=head1 TRADEMARKS

UNIX is a registered trademark in the United States and other countries,
licensed exclusively through X/Open Company Ltd.

POSIX is a registered trademark of the IEEE Inc.

LINUX is a registered trademark of Linus Torvalds.

=cut 


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }
#
#   UNIX MODULE
#
use FileHandle;

use Sys::Spec::Module;

use vars qw( $VERSION @ISA );

$VERSION = "3.000";
@ISA = ( qw( Sys::Spec::Module ) );

my $module_values;	#hashref into Sys::Spec::Modules for common info

sub iv_sys_spec_module_unix_version
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


########################################################################
#
#   LINUX: /etc/redhat-released: RED-HAT FAMILY OF OPERATING SYSTEMS
#
sub _try_redhat
{
    my $class   = shift;
    my $path   = shift;

    my $fh = new FileHandle( $path, "r" )
    	or  return undef;

    my $line = $fh->getline();
    $line =~ s/\s+$//;			#super-chomp
#Red Hat Enterprise Linux WS release 4 (Nahant Update 2)
#Red Hat Linux release 9 (Shrike)
#Fedora Core release 6 (Zod)

    my ( $x_vendor, $x_release, $x_codename ) = ( undef, undef, undef );

    if ( $line =~ 
         /^\s*(Red *Hat .*Linux*) .*release *([-.\d]+) .*\(([^()]+)\)/i )
    {   #red hat BRANDED Linux
	( $x_vendor, $x_release, $x_codename ) = ( $1 , $2, $3 )
    }
    elsif ( $line =~ 
	/^\s*(Fedora) *Core .*release *([-.\d]+) .*\(([^()]+)\)/i )
    {   #Fedora, distributed by Red Hat
	( $x_vendor, $x_release, $x_codename ) = ( $1 , "Core $2", $3 )
		# NOTE: not sure if this should be
		#   x_vendor = "Fedora"       x_release = "Core 6"
		#      OR
		#   x_vendor = "Fedora Core"  x_release = "6"

    }
    elsif ( $line =~
	/^\s*(Red *Hat) .*release *([-.\d]+) .*\(([^()]+)\)/i )
    {	   # some generic red hat we don't have special knowledge of
	( $x_vendor, $x_release, $x_codename ) = ( $1 , $2, $3 )
    }
    elsif ( $line =~
	/^\s*(\S.*\S) .*release *([-.\d]+) .*\(([^()]+)\)/i )
    {	   # some generic, likely derived from RH, but not RH, Linux
	( $x_vendor, $x_release, $x_codename ) = ( $1 , $2, $3 )
    }

    my $return = 0;
    if ( defined($x_vendor) && length($x_vendor) )
    {   #something found to return
	$return++;
	$module_values->{'os_d_vendor'}  = $x_vendor;
	$module_values->{'os_d_release'} = $x_release
	     if length($x_release)   &&   ++$return;
	$module_values->{'os_d_codename'} = $x_codename
	     if length($x_codename)  &&   ++$return;
    }

    return $return;
}

push ( @try__list, { 
		perl_os =>  "linux",
		file    => "/etc/redhat-release",
		sub     => \&_try_redhat,
		   } );


########################################################################
#
#   LINUX: DEBIAN FAMILY OF OPERATING SYSTEMS
#
sub _try_debian
{
    my $class = shift;
    my $path = shift;

    my $fh = new FileHandle( $path, "r" )
    	or  return undef;

    my ( $x_vendor, $x_release, $x_codename );
    while ( my $line = $fh->getline() )
    {
	$line =~ s/\s+$//;			#super-chomp
# deb cdrom:[Debian GNU/Linux 4.0 r4a _Etch_ - Official i386 DVD Binary-1 20080803-20:48]/ etch contrib main
	if ( $line =~ m|^deb\s+[^:]*:\[(Debian)\s+GNU/Linux\s+
			([.\d]+\s[a-z0-9]+)\s+_([A-Z][a-z\d]+)_\s+
			.*\]|ix )
	{
	    ( $x_vendor, $x_release, $x_codename ) = ( $1 , $2, $3 );
	    last;
	}
    }

    my $return = 0;
    if ( defined($x_vendor) && length($x_vendor) )
    {   #something found to return
	$return++;
	$module_values->{'os_d_vendor'} = $x_vendor;
	$module_values->{'os_d_release'} = $x_release
	     if length($x_release)   &&   ++$return;
	$module_values->{'os_d_codename'} = $x_codename
	     if length($x_codename)  &&   ++$return;
    }

    return $return;
}

push ( @try__list, { 
		os   =>  "linux",
		file => "/etc/apt/sources.list",
		sub  => \&_try_debian,
		   } );


########################################################################
#
#   LINUX: /PROC/VERSION FILE (generic Linux)
#
sub _try_proc_version
{
    my $class = shift;
    my $path = shift;

    my $fh = new FileHandle( $path, "r" )
    	or  return undef;

    my $line = $fh->getline();
    $line =~ s/\s+$//;			#super-chomp

#Linux version 2.4.20-8 (bhcompile@porky.devel.redhat.com) (gcc version 3.2.2 20030222 (Red Hat Linux 3.2.2-5)) #1 Thu Mar 13 17:54:28 EST 2003
#Linux version 2.6.18-1.2798.fc6 (brewbuilder@hs20-bc2-4.build.redhat.com) (gcc version 4.1.1 20061011 (Red Hat 4.1.1-30)) #1 SMP Mon Oct 16 14:37:32 EDT 2006

    my ( $x_vendor, $x_release, $x_codename ) = ( undef, undef, undef );
    ( $x_vendor, $x_release ) = ( $1, $2 )
        if $line =~ /^\s*Linux\s+version.*
		     \(([^()]+)\s+([-._0-9]+)\)\)
		    [^()]*$/ix;

    my $return = 0;
    if ( defined($x_vendor) && length($x_vendor) )
    {   #something found to return
	$return++;
	$module_values->{'os_d_vendor'}  = $x_vendor;
	$module_values->{'os_d_release'} = $x_release
	     if defined($x_release) && length($x_release) && ++$return;
	$module_values->{'os_d_codename'} = $x_codename
	     if defined($x_codename) && length($x_codename) && ++$return;
    }

    return $return;
}

push ( @try__list, { 
	  perl_os =>  "linux",
	  file    => "/proc/version",
	  sub     => \&_try_proc_version,
	} );


########################################################################
#
#   From Copyright Information
#	(added for HP-UX, but trying to be generic)
#
sub _try_copyright
{
    my $class = shift;
    my $path = shift;

    my $fh = new FileHandle( $path, "r" )
    	or  return undef;

    my $return = 0;
    my $line = $fh->getline();
    if ( $line =~ /copyright[-\s0-9]+(\S.*),/i )
    {
	$module_values->{'os_d_vendor'} = $1;
	$return++;
    }

    return $return;
}

push ( @try__list, { 
	  file => "/etc/copyright.dist",
	  sub  => \&_try_copyright,
	} );



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
	     IV_SYS_SPEC_MODULE_UNIX_VERSION
	  ) );

    $module_values = $class->SUPER::init_();

    $class->try_files_( \@try__list );

    return ( __PACKAGE__ );
}

######################################################################
# 
#  take POSIX command arguments, with possible ">" and "<" style 
#  I/O redirections, a format appropriate for the local system.
#

use Scalar::Util ();

sub posix2command
{
    my $self    = shift;

    my $command;
    my @newargs = ();

    if ( @_ == 1 )
    {   # one-argument... must be list
	if ( defined $_[0] )
	{   #have SOMETHING defined in first arg
	    my $ref_type = Scalar::Util::reftype( $_[0] );
	    if ( $ref_type eq "SCALAR" )
	    {   #scalar: assume command
		$command = shift;
	    }
	    elsif ( $ref_type eq "LIST" )
	    {   #list: first argument is command, remainder is args
		$command = shift @_;
		@newargs = @_;
	    }
	    elsif ( $ref_type eq "HASH" )
	    {

	    }
	}
	@newargs = shift @_ if @_;

    }

    my $command = shift;


    if ( @_ && ref( $_[0] ) )
    {
	1;
    }
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

__END__

__RED HAT__
root@komarr root]# cat /proc/version 
Linux version 2.4.20-8 (bhcompile@porky.devel.redhat.com) (gcc version 3.2.2 20030222 (Red Hat Linux 3.2.2-5)) #1 Thu Mar 13 17:54:28 EST 2003

[root@komarr root]# cat /etc/redhat-release 
Red Hat Linux release 9 (Shrike)


__FEDORA CORE__
[gilbert@foster bin]$ cat /proc/version 
Linux version 2.6.18-1.2798.fc6 (brewbuilder@hs20-bc2-4.build.redhat.com) (gcc version 4.1.1 20061011 (Red Hat 4.1.1-30)) #1 SMP Mon Oct 16 14:37:32 EDT 2006


[gilbert@foster bin]$ cat /etc/redhat-release 
Fedora Core release 6 (Zod)

#end
