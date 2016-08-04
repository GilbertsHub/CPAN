# Build.PL: build script
# 
use strict;

use Module::Build;
use File::Spec;

use vars qw( $VERSION );

$VERSION = "0.001";

use File::Copy ();

my $class;

$class = Module::Build->new
      ( module_name     => 'Random::BestTiny',
        dist_version    => '0.1',
        license         => 'perl',
	dist_abstract   => 
		"Random numbers using best API from local kernel",
	dist_author	=> 'Gilbert Healton <gilbert@healton.net>',

        meta_merge      => {
	    repository      => {
	      type   =>  "git",
	      url    =>  "git:/github.com/GilbertsHub/CPAN/Ramdom-BestTiny",
	      web    =>  "https://github.com/GilbertsHub/CPAN/Ramdom-BestTiny" },
	}

      )->create_build_script;

#end
