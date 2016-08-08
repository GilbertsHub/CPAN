# Makefile.PL

use vars qw( $VERSION );
use vars qw( $VERSION_PACKAGE );

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Getopt::Object',
    VERSION_FROM    => 'VERSION_PACKAGE',

    PL_FILES        => {},		#assure MakeMaker never runs Build.PL
    META_MERGE	    => {

	'meta-spec'   => { version => 2 },

	resources     => {
	    repository      => {
	      type   =>  'git',
	      url    =>  'git://github.com/GilbertsHub/CPAN',	#/Getopt-Object
	      web    =>  'https://github.com/GilbertsHub/CPAN', #/Getopt-Object 
	      },
	},
    },
);

#end
