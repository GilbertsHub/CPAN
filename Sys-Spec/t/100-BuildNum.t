# t/100-Spec.t: test Sys::Spec package
#

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

use POSIX;
use FileHandle;

use Test::More tests => 7;

use vars qw( $VERSION );
$VERSION  = ( qw$Revision: 1.000 $ )[1];

BEGIN { use_ok( 'Sys::Spec::Text' ) }

$ENV{'SYS_SPEC_TIME0'} = time;		#set time of day

{
    my $x = Sys::Spec::Text->insert( qw(
    	:INTERNAL_VERSIONS
	  IV_BUILD_NUM_TEST
    ) );

sub iv_build_num_test
{
    return 9.876;
}
}

my $bn = Sys::Spec::Text->new( -buildnum => "1.2.3" );
ok( $bn, "Sys::Spec::Text object created" );

my $sys_spec1 = $bn->get('BUILDNUM');
ok( $sys_spec1 =~ /^\d{8}$/, 
	"build number is 8-digit numeric: $sys_spec1" );

my $long_text2 = $bn->get_text();

ok( length($long_text2) > 100, "long text present" );

ok( $long_text2 =~  /=.*9\.876/, "->insert() variable returned" );


$ENV{'SYS_SPEC_TIME0'} += 24*60*60;	#advance time 24 hours
my $bn3 = Sys::Spec::Text->new();
ok( $bn3, "second Sys::Spec::Text object created" );

my $sys_spec3 = $bn3->get('BUILDNUM');	#get just build number
ok( $sys_spec3 >= $sys_spec1 + 1000,
	"SYS_SPEC_TIME0 controls build number time" ) ||
   print STDERR "  FAILED: $sys_spec3 >= $sys_spec1 + 100000\n";

exit EXIT_SUCCESS;

#end t/100-Spec.t
