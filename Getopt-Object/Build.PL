# Build.PL: build script
# 
use strict;

use Module::Build;
use File::Spec;


our $VERSION_PACKAGE;
require File::Spec->rel2abs( "VERSION_PACKAGE" );

use vars qw( $VERSION );
$VERSION = "0.1";               #define our version AFTER VERSION_PACKAGE

use File::Copy ();

my $class;

$class = Module::Build->new
      ( module_name     => 'Getopt::Object',
        dist_version    => $VERSION_PACKAGE,
        license         => 'perl',
	dist_abstract   => 
		"Extend Getopt::Long to easily create and maintain command line options",
	dist_author	=> 'Gilbert Healton <gilbert@healton.net>',

        meta_merge      => {
	    repository      => {
	      type   =>  "git",
	      url    =>  "git:/github.com/GilbertsHub/CPAN/Getopt-Object",
	      web    =>  "https://github.com/GilbertsHub/CPAN/Getopt-Object" },
	}

	  )->create_build_script;

#end
