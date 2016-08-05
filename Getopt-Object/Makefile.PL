# Makefile.PL

use vars qw( $VERSION );
$VERSION = "0.2";

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Getopt::Object',
    VERSION_FROM    => 'VERSION_PACKAGE',

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
