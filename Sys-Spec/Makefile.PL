# Makefile.PL

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Sys::Spec',
    VERSION_FROM    => 'VERSION_PACKAGE',

    EXE_FILES	    => [ qw( scripts/sys-spec ) ],
    INST_SCRIPT	    => "bin",

    META_MERGE	    => {

	'meta-spec'   => { version => 2 },

	resources     => {
	    repository      => {
	      type   =>  'git',
	      url    =>  'git://github.com/GilbertsHub/CPAN',	#/Sys-Spec
	      web    =>  'https://github.com/GilbertsHub/CPAN', #/Sys-Spec 
	      },
	},
    },
);

sub MY::postamble
{
    return <<'POSTAMBLE';

save_sample:
	os_name="`perl -Ilib scripts/sys-spec u_os_name | awk '{print $$2}'`" || exit $$?; \
	vendor="`perl -Ilib scripts/sys-spec os_d_vendor | awk '{print $$2}'`"; \
	if [ ."$$vendor" != . ]; then os_name="$$os_name-$$vendor"; fi; \
	cp tmp/110-sys-spec.txt "samples/$$os_name.txt";

POSTAMBLE
}
