#!/usr/local/scripts/perl
# t/120-formatting.t -- test sys-spec formatting

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

use FileHandle;
use File::Spec;
use Sys::Spec;

use File::Basename;
( my $name0 = basename($0) ) =~ s/\.t$//;

use vars qw( $format_basename @format_list );

BEGIN 
{
    my $formats = File::Spec->catfile( "t", "formats.pl" );
    require $formats;
}

use Test::More tests => ( 2 + 4 * @format_list );


use vars qw( $VERSION );
$VERSION  = ( qw$Revision: 1.000 $ )[1];

my $VERSION_TEST = "42.999.002";	#arbitray test version

ok( ( -d 'tmp' || mkdir 'tmp' ), "local tmp dir exists" )  ||
	BAIL_OUT( "   tmp DIR NOT PRESENT\n" );

{
    my $fh = FileHandle->new( ">$format_basename" );
    ok( $fh, "Write important info to $format_basename" ) ||
    	BAIL_OUT( "$format_basename: $!" );
    $fh->print( "#$format_basename: generated file: see $name0\n" );
    $fh->print( "\$name00 = '$name0';\n" );
    $fh->print( "#end\n" );
    $fh->close;
}

my $scripts_sys_spec = File::Spec->catfile( "scripts", "sys-spec" );
foreach my $fmt ( @format_list )
{
    my $format = $fmt->{'format'};
    	
    my $name   = $fmt->{'name'};
    my $suffix = $fmt->{'suffix'};
    my $mode   = $fmt->{'mode'};
    my $mode_name = $mode->[0];
    my $mode_vair = $mode->[1];

    my $testpath = File::Spec->catfile( "tmp", "$name0.$suffix" );
    unlink $testpath;

    my $redirect = Sys::Spec->is_unixish
                ? ' 2>&1'
                : "";
    my $cmd = qq(perl -Ilib "$scripts_sys_spec" --format="$format" --$mode_name="$VERSION_TEST" >$testpath  FORMAT_NAME="$name"$redirect);
    my $out = qx($cmd);

    ok( ( $? >> 8 ) == EXIT_SUCCESS,
            "$format: $name --$mode_name $scripts_sys_spec executed successfully" )  or
	BAIL_OUT( "$out\n  $cmd\n" );

    ok( -s $testpath, "  $testpath file written" );

    my $fh = FileHandle->new( $testpath, "r" );
    ok( $fh, "  $testpath opened for input" ) || 
	BAIL_OUT( "  $!\n" );

    		# allow for:
		#     name="value"      name = 'value'
		#     name = "value"    name = 'value'
		#     name => 'value'
		#     name := 'value'
		#     <name>value</name>
    my @lines = $fh->getlines;
    ok( scalar( grep( /$mode_vair *[:=>]+ *['"]?\d/, @lines ) ), 
		"  VERSION_$mode_vair number in file" ) ||
        diag( "  $cmd\n   observed:" .
                join(";", ( grep /VERSION_$VERSION_TEST/, @lines ) ) );
}

exit EXIT_SUCCESS;

#end: t/120-formatting.t
