#!/usr/local/bin/perl
# t/010-Sys-Spec.t -- test Sys::Spec.pl w/o Text 

#
# COPYRIGHT, LICENSE, and WARRANTY
# 
# This program and documentation is copyright 2008 by Gilbert Healton.
# All rights reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# 
# See <http://www.perl.com/perl/misc/Artistic.html>
#
#   NO WARRANTY
# 
# Because the program is licensed free of charge, there is no warranty.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, 
# THE IMPLIED WARRANTIES OF MERCHANTIBILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.
# 

use strict;


use POSIX;		#"all the world's a POSIX stage"

use Test::More tests => 7;

use vars qw( $VERSION );
$VERSION  = ( qw$Revision: 1.0 $ )[1];

BEGIN { use_ok( 'Sys::Spec', 'can use Sys::Spec' ) }

my $ss;
ok( $ss = Sys::Spec->new(), "Sys::-Spec->new()" )  or
	BAIL_OUT( "CAN NOT CONSTRUCT NEW Sys::-Spec\n" );

my @master_list;
ok( @master_list = $ss->get, "get master_list values" ) or
	BAIL_OUT( "get() RETURNED EMPTY MASTER_LIST\n" );

my $errors = 0;
my $count = 0;
my $within_head = -1;
foreach my $master ( @master_list )
{
    if ( $master =~ /^:/ )
    {   #heading
	if ( $within_head == 0 )
	{
	    $errors++;
	    diag( "  ----- HEADING ERROR: no entries between headings -----\n" );
	}
        printf( " %s\n", $master );
	$within_head = 0;
    }
    else
    {
	if ( $within_head < 0 )
	{
	    $errors++;
	    diag( "  ----- HEADING ERROR: no heading in first slot -----\n" );
	}
	my $m = $master;
	$master =~ s/.*:://;
	my $value = $ss->get($master);
	printf( "  \%-12s = \%s\n", $m, $value )
		if defined $value;

	$within_head++;		#count entry within heading
    }
    $count++;
}

if ( $within_head == 0 )
{
    $errors++;
    diag( "  ----- HEADING ERROR: no entries after last heading -----\n" );
}

ok( $count >= 20, "At least twenty values found" );

ok( $errors == 0, "No heading errors" );

ok( defined($ss->get("IV_SYS_SPEC_VERSION")), "IV_SYS_SPEC_VERSION defined" );

ok( defined($ss->get("U_ARCH")), "U_ARCH defined" );

exit 0;

#end: t/010-Sys-Spec.t
