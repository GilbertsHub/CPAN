# formats.pl - formats used in testing
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

use File::Spec;

use vars qw( $format_basename @format_list );

$format_basename = File::Spec->catfile( "tmp", "format_basename.txt" );
	# contains $name0 of test writing files to be verified used.

@format_list = 
      (
		# format:	format to pass to Sys::Spec
		# name:		human-friendly description of format
		# suffix:	suffix to use in output file
		# mode:		[ mode option and expected variable from mode ]
		# vala:		how to validate output file.
		# 		  [ vala_test, vala_command ]
		# 		      vala_test:  name of validation command
		# 		        (if this command does not exist then the
		# 		         test is not made).
                #                         # if array ref, then
                #                         #   [0] is command name
                #                         #   [1...] commands that MUST
                #                         #     execute successfully for
                #                         #     validation to occur.
		#		        undef: no validation command.
		# 		      vala_command: full command to do
		# 		        validation.
	{  format => "ecma", name => "ECMAScript", suffix => "js",
		mode => [ 'buildnum', 'BUILDNUM' ],
	      	vala => [ undef ]                       },
	{  format => "perl", name => "Perl",        suffix => "pl",
		mode => [ 'runnum',   'RUNNUM' ],
		vala => [ "perl", 
		      q(perl -cw -e "require q[$path]; 1") ] },
	{  format => "sh",   name => "Borne Shell", suffix => "sh",
		mode => [ "buildnum",    'BUILDNUM' ],
		vala => [ "sh", 'sh -n "$path"' ]       },
	{  format => "xml",  name => "XML",         suffix => "xml",
		mode => [ 'id=WHATEVER',   'WHATEVER' ],
		vala => [ "xmllint", 'xmllint "$path"' ] },
	{  format => "yaml", name => "YAML",        suffix => "yaml",
		mode => [ 'id=WHATEVER',   'WHATEVER' ],
		vala => [ [ "python", 'python -c "import yaml;"' ], 
		           q[python -c "import yaml; print yaml.dump(yaml.load(open('$path').read()))"] ] },
	{  format => "yaml0", name => "YAML-old",        suffix => "yaml0",
		mode => [ 'id=WHATEVER',   'WHATEVER' ],
		vala => [ "ysh", 'ysh <"$path" >"$path.stdout.txt"' ] },
      );

1;

#end: formats.pl
