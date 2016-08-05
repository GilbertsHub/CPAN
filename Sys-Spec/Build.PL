# Build.PL: build script
# 
use strict;

use Module::Build;
use File::Spec;

use vars qw( $VERSION );

$VERSION = "1.000";

use File::Copy ();

my $class = Module::Build->subclass(
	class => "Module::Build::Custom",
	code  => <<'SYSSPEC_BUILD' );
	    sub ACTION_save_sample
	    {
		local(@INC) = ( "lib", @INC );
		require Sys::Spec;

		my $ss = Sys::Spec->new();

		my $os_name      = $ss->get( 'u_os_name' );
		my $vendor       = $ss->get( 'os_d_vendor' );

                my $prefix = $os_name;
                if ( $ss->is_windowsish )
                {  #Windows systems put NT in $os_name for "NT conventions",
                   # which bacially includes everything after XT.
                   # dig for another name that is more useful.
                   $prefix = $ss->get( 'os_d_release' );
                }

		$prefix   .= "-$vendor" 
			if defined($vendor) && length($vendor);

                $prefix =~ s/[^-.,\w]+/_/g;     #use generic safe file names
                $prefix =~ s/^_+//;
                $prefix =~ s/_+$//;
                $prefix =~ s/_([-.])/$1/g;

                my $source = File::Spec->catfile( "tmp", "110-sys-spec.txt" );
		my $target = File::Spec->catfile( "samples", "$prefix.txt" );
		File::Copy::copy( $source => $target ) ||
		    die "Save Sample Failed: $!\n";

	    	print "saved: $target\n";
	    }

	    sub ACTION_return_1
	    {
		return 1;
	    }

	    sub ACTION_return_0
	    {
		return 0;
	    }

	    sub ACTION_return_undef
	    {
		return undef;
	    }
SYSSPEC_BUILD

$class->new
      ( module_name     => 'Sys::Spec',
        license         => 'perl',
	dist_abstract   => 
		"Retrieve available information on the current system " .
		"in text file format.",
	dist_author	=> 'Gilbert Healton <gilbert@healton.net>',

        meta_merge      => {
	    repository      => {
	      type   =>  "git",
	      url    =>  "git:/github.com/GilbertsHub/CPAN",	#/Sys-Spec
	      web    =>  "https://github.com/GilbertsHub/CPAN",	#/Sys-Spec
	      },
	}

      )->create_build_script;

