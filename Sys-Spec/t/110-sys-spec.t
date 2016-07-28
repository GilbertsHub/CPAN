#!/usr/local/scripts/perl
# t/110-sys-spec.t -- test sys-spec.pl

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
use File::Spec;

use File::Basename;
( my $name0 = basename($0) ) =~ s/\.t$//;

use Test::More tests => 5;


use vars qw( $VERSION );
$VERSION  = ( qw$Revision: 1.000 $ )[1];

my $VERSION_TEST = "1.999.002";		#test version

my $scripts_sys_spec = File::Spec->catfile( "scripts", "sys-spec" );

ok( ( -d "tmp" || mkdir( 'tmp' ) ), "local tmp dir exists" )  ||
	die "   $!\n";

my $testpath = File::Spec->catfile( "tmp", "$name0.txt" );
unlink $testpath;

my $command = qq(perl -Ilib "$scripts_sys_spec" --buildnum=$VERSION_TEST >$testpath 2>&1);
my $out = qx($command);

ok( $? == 0, "$scripts_sys_spec executed successfully" )  or
	die "(?=$?): $out\n";

ok( -s $testpath, "$testpath file written" );

my $fh = FileHandle->new( "<$testpath" );
ok( $fh, "$testpath opened for input" ) || 
	die "  $!\n";
ok( scalar( grep( /VERSION_BUILDNUM=['"]\d/, $fh->getlines ) ), 
		"VERSION_BUILDNUM number in file" );

exit 0;

#end: t/110-sys-spec.t
