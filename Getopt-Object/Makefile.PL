# Makefile.PL

use vars qw( $VERSION );
$VERSION = "0.1";

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Getopt::Object',
    VERSION_FROM    => 'VERSION_PACKAGE',
);

#end
