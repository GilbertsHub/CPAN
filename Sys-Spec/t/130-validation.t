#!/usr/local/scripts/perl
# t/120-validation.t -- validate results of prior formatting test

#
# COPYRIGHT, LICENSE, and WARRANTY
# 
# This program and documentation is copyright 2008 by Gilbert Healton.
# All rights reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
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

use File::Basename;
( my $name0 = basename($0) ) =~ s/\.t$//;

# get name of test step that generated test data
$name0 =~ /^(\d+)/;

use vars qw( $format_basename @format_list );
use vars qw( $name00 );

use File::Spec;
use Sys::Spec;


BEGIN 
{
    my $formats = File::Spec->catfile( "t", "formats.pl" );
    require $formats;
}

require $format_basename;

use vars qw( $VERSION );
$VERSION  = ( qw$Revision: 1.000 $ )[1];

my $VERSION_TEST = "42.999.002";	#arbitray test version

use Test::More tests => ( 0 + 3 * @format_list );

my $redirect = Sys::Spec->is_unixish
                ? ' 2>&1'
                : "";

foreach my $fmt ( @format_list )
{
    my $format = $fmt->{'format'};
    my $name   = $fmt->{'name'};
    my $suffix = $fmt->{'suffix'};

    my $testpath = File::Spec->catfile( "tmp", "$name00.$suffix" );
    ok( -f $testpath, "$format: $name $testpath exists" ) ||
    	BAIL_OUT( "ERROR: $!" );
    ok( -s $testpath, "  non-zero in size" ) ||
    	BAIL_OUT( "ERROR: $!" );

    my $which_exe = File::Spec->catfile( "scripts", "sys-spec-which" );

    my $vala = $fmt->{'vala'};
    if ( $vala && @$vala && $vala->[0] )
    {   #have a validation service
	my ( $vala_test, $vala_cmd ) = @$vala;	#extract "can we" and the test
	my @vala_test = ref( $vala_test ) 	#allow for multiple "can we"s
    		? @$vala_test			#  multiple
		: ( $vala_test );		#  single
	$vala_test = shift @vala_test;		#get basic program name
	my $which = qx(perl -Ilib "$which_exe" "$vala_test");
	$which =~ s/\s+//g if $which;
	unless ( ( $? >> 8 ) == EXIT_SUCCESS &&
	         $which && -f $which )    #can not do test if program missing
	{
	    diag(
	        "\t---will not test format=$format: " .
                "no \`$vala_test\` program---\n" );
	    $which = undef;
	}
	while ( $which && @vala_test )
	{   #iterate through any additional tests
	    my $vala_cmd = shift @vala_test;
	    my $stdout = qx( $vala_cmd$redirect );
	    if ( ( $? >> 8 ) != EXIT_SUCCESS )
	    {
		$stdout =~ s/^/   /gm;	#indent any lines of stdout
		$stdout =~ s/\s*$/\n/s; #assure \n ends stdout
		diag(
		    "\t---will not test format=$format: no \`$vala_cmd\`---\n"
		    . $stdout );
		$which = undef;
	    }
	}
	if ( $which )
	{   #file exsits... can run it
	    my $success = $vala_cmd =~ s/\$path/$testpath/g;
	    my $output = "(not run)";
	    local $?;
	    $output = qx($vala_cmd) if $success;
	    ok( $success && ( $? >> 8 ) == EXIT_SUCCESS,
	    	 	"  validate file via \`$vala_cmd\`" );
	}
	else
	{   
	    ok( 1, "  validation skipped... $vala_test program not present" );
	}
    }
    else
    {   #no validation service
	ok( 1, "  validation skipped... no automated validation available" );
    }
}

exit EXIT_SUCCESS;

#end: t/120-formatting.t
