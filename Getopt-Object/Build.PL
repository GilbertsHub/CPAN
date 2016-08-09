# Build.PL: build script
# 
use strict;

use vars qw( $VERSION );

use Module::Build;


my $class;

$class = Module::Build->new
      ( module_name     => 'Getopt::Object',
	dist_version_from => 'VERSION_PACKAGE',
        license         => 'perl',
	dist_abstract   => 
		"Extend Getopt::Long to easily create and maintain command line options",
	dist_author	=> 'Gilbert Healton <gilbert@healton.net>',
	configure_requires => { 'Module::Build' => 0.40 },

        meta_merge      => {
	    repository      => {
	      type   =>  "git",
	      url    =>  "git:/github.com/GilbertsHub/CPAN",	  # Getopt-Object
	      web    =>  "https://github.com/GilbertsHub/CPAN" }, # Getopt-Object
	}

	  )->create_build_script;

#end
