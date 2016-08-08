#Sys::Spec::Text: format output text


use strict;

=head1 NAME

Sys::Spec::Text - extend Sys::Spec to express available information on the current system,
application,
build number,
run id,
etc.,
as generated code in several formats.

=head1 SYNOPSIS

 use Sys::Spec::Text;

 $sst = Sys::Spec::Text->new( ... all Sys::Spec arguments ... )

 $text = $sst->get_text( 
		[ -prefix => ppp, ]
		[ -format = "sh"|"ecma"|"perl"|"xml", ]
 		[ name => value, name2 => value2, ... ]
		      )

 @m = $sst->get();		#array of headers and keys
 $value = $sst->get($key);	#get specific value

 $module = Sys::Spec::Text->module();

 Sys::Spec::Text->insert( $heading, @item_list );

=head1 DESCRIPTION

Gives the Sys::Spec class the ability to generate 
source code containing the values in formats usable to programs as 
well as people.
Output may be generated in several types of formats.

While the original purpose is to support the B<sys-spec> program,
it makes diverse information available to perl programs using 
a single class.

All functionality of Sys::Spec is available to Sys::Spec::Text.
Only the additional functions are described in this document.

The B<get_text>() function is the prime purpose of the existence of 
this class.

=over +4

=cut


package Sys::Spec::Text;

our $VERSION = '3.001';

use File::Basename;

use Sys::Spec;			#asure SUPER class is present

use vars qw( @ISA );

@ISA = qw( Sys::Spec );


Sys::Spec->insert( 		#add our stuff to master list
    qw(
        :INTERNAL_VERSIONS
	 IV_SYS_SPEC_TEXT_VERSION
      ) );

sub iv_sys_spec_text_version
{
   return $Sys::Spec::Text::VERSION;
}


my %code_names = (
  # UGLY... temporary ... plan a better way in the future.
      ':TIME'			=> "Values from the time of the snapshot",
	TIME_T			=> "current time_t time",
	TIME_LOCAL		=> "local time (ISO 8601 format)",
	TIMEZONE_NAME		=> "name of local time zone",
	TIMEZONE_OFFSET		=> "local time zone offset",
	TIME_UTC		=> "Universal Time (ISO 8601 format)",
	BUILDNUM		=> "Build number",
	RUN_ID			=> "Run-ID",
	TSTAMP_CODE		=> "Time stamp code",
      ':VERSION'		=> "Version information of the application",
	VERSION3		=> "Full Version without build number",
        VERSION_BUILDNUM        => "Full Version with build number",
        VERSION_RUN_ID          => "Runl Version with Run-ID",
        VERSION_TSTAMP_CODE     => "Full Version with time stamp code",
	VERSION2		=> "Major/Minor version",
	VERSION1		=> "Only major version",
     ':HARDWARE'		=> "Values derived from the hardware",
        U_HOSTNAME		=> "Host or node name (via uname)",
	U_ARCH			=> "Architecture (via uname)",
      ':OS'			=> "Values derived from OS itself",
       U_OS			=> "OS Name (via uname)",
	U_OSRELEASE		=> "OS release (via uname)",
	PERL_OS_NAME		=> "OS name, as perl sees it",
	PERL_ARCHNAME		=> "Architecture name (via perl)",
	PERL_ARCHNAME64		=> "Well defined on 64-bit ",
	OS_D_VENDOR		=> "OS Vendor name (via Sys::Spec::Module::\$x)",
	OS_D_RELEASE		=> "OS Release",
	OS_D_CODENAME		=> "OS Code name",
      ':PERL'			=> "Values from perl",
       PERL_VERSION		=> "Perl's version",
	PERL_INC		=> "Perl's search path",
	PERL_USETHREADS		=> "Perl has thread support",
      ':USER'			=> "Values describing the current user",
       UID			=> "User id",
	UNAME			=> "User login name",
	UNAME_LONG		=> "User textual name",
	GID			=> "Users group id",
	GNAME			=> "Users main group name",
     ':INTERNAL_VERSIONS'	=> "Version information on Spec",
	 IV_BUILD_NUM		=> "Sys::Spec version",
	 'main::IV_BUILD_NUM_MAIN' => "sys-spec application",
   );

sub code_names_
{
    my (
        $class,
	%hash ) = @_;

    foreach my $key ( keys %hash )
    {
	$code_names{$key} = $hash{$key}
		if defined $key and defined $hash{$key};
    }

    return
}


#######################################################################


my $format_default = 'sh';		#default format (must exist)
my %formats =	# controls output format strings at the low level
 (
		# NOTE: do NOT want to expose these formats
		#   to callers due to potential changes for
		#   future languages.
		# NOTE: in sformat* strings:
			#  %p is prefix
			#  %n  variable name
			#  %v  variable value
			#  %t  title name

    csh  => {   #C-shell
    		quotes   => [ "'", '"' ],   #available quotes
	   	comment1 => '# ',           #start comment lines
	        comment2 => '# ',	    #continue comment lines
	        comment3 => '',		    #end comment series
	        sformat  => 'set %p%n = %v;', #how to format definitions
	        sformat1 =>  'set %n = %v;',      #user definition format
	        sformat2 =>  [],	    #start and end total block
	 },
    ecma => {   #ECMAScript
	        quotes   =>  [ '"' ],        #available quotes
	        comment1 =>  '/* ',	      #start comment lines
	        comment2 =>  ' * ',	       #continue comment lines
	        comment3 =>  ' */',	        #end comment series
	        sformat  =>  '  this.%p%n = %v;', #how to format
	        sformat1 =>  '  this.%n = %v;', #user definition format
	        sformat2 =>  [	               #start and end total block
				'function %p%t() {',
				'}'
                             ],
	 },
    perl => {   # perl
	        quotes   =>  [ "'", '"' ],  #available quotes
	        comment1 =>  '# ',	    #start comment lines
	        comment2 =>  '# ',	    #continue comment lines
	        comment3 =>  '',	    #end comment series
	        sformat  =>  '        %p%n => %v,',  #how to format
	        sformat1 =>  '       %n => %v,',     #how to format
	        sformat2 =>  [ '$%p%t = {', '};' ],  #start and end block
	},
    sh   => {   #Borne shell
    		quotes   => [ "'", '"' ],   #available quotes
	   	comment1 => '# ',           #start comment lines
	        comment2 => '# ',	    #continue comment lines
	        comment3 => '',		    #end comment series
	        sformat  => '%p%n=%v;',     #how to format definitions
	        sformat1 =>  '%n=%v;',      #user definition format
	        sformat2 =>  [],	    #start and end total block
	 },
    xml => {    # XML
	        quotes   =>  [ ],           #available quotes
	        comment1 =>  '<!-- ',	    #start comment lines
	        comment2 =>  '  ** ',	    #continue comment lines
	        comment3 =>  ' -->',	    #end comment series
	        sformat  =>  '<%p%n>%v</%p%n>',  #how to format
	        sformat1 =>  '<%n>%v</%n>',      #how to format
	        sformat2 =>  [ "<%p%t>", "</%p%t>" ],
	},
    yaml => {   #YAML 
    		quotes   => [ ],  #available quotes
    		#quotes   => [ '"' ],  #available quotes
    		#quotes  => [ "'", '"' ],  #available quotes
	   	comment1 => '    # ',       #start comment lines
	        comment2 => '    # ',	    #continue comment lines
	        comment3 => '',		    #end comment series
	        sformat  => '    %p%n: %v', #how to format definitions
	        sformat1 => '    %n: %v;',  #user definition format
	        sformat2 => [ "%psys_spec:"], #start and end total block
	 },
    yaml0 => {   #YAML 
    		quotes  => [],            #available quotes (avoid on old)
	   	comment1 => "\n# ",       #start comment lines
	        comment2 => "# ",	  #continue comment lines
	        comment3 => '',		  #end comment series
	        sformat  => '    %p%n: %v', #how to format definitions
	        sformat1 => '    %n: %v;',  #user definition format
	        sformat2 => [ "%psys_spec:"], #start and end total block
	 },
 );
sub internal_formats_ 
{
    my (
    	$self_or_class,
	$format_code,
	) = @_;

    return sort keys %formats unless $format_code;

    return undef unless exists $formats{$format_code};

    return $formats{$format_code};
}



#######################################################################

=pod

=item $text = $ss->get_text(...)

Return all known settings expressed as code in a selected format.
The caller may also specify custom name/value pairs to include in the output.

These are followed by any caller provided name => value pairs, without the leading hyphen.

Options are expressed as traditional -name => value pairs.

=over +2

=over +2

=item -format => language

Selects the language to be returned.
Current values are:

=over +2

B<csh>:
C-Shell.

B<ecma>:
ECMAScript (e.g., JavaScript).

B<perl>:
Perl programming language.

B<sh>:
Borne shell.
This is the default setting.

B<xml>:
XML

B<yaml>:
YAML format (see YAML or YAML::Tiny perl modules).
Requires newer parsers that properly handle comments.

BUG: older parsers will include "#" comments within values.

B<yaml0>:
YAML format (see YAML or YAML::Tiny perl modules).
Older format that uses simpler comments (produces ugly yaml)
that work with older parsers.

=back


=item -prefix => string

Provides prefix to appear before
symbols representing system values,
but not before any additional symbols representing names from caller provided name/value pairs.

=item name => value

Additional name value pairs from caller.
Must follow any "-" options.

=back

=back

All times in generated output are in Coordinated Universal Time (UTC).
The term GMT is no longer used as a modern international standard
(search the web for the exact quote
I<"The Best Of Dates, The Worst Of Dates">
for more details).

These build numbers are small enough for people to manually compare with
each other yet fine enough to serve most build environments.

Be advised that there is no standard for what the various fields represent.
Different releases of perl,
and different OS vendors,
can read different things into the definitions.

=cut

#
#   produce language name=value formats, and a few other stand along 
#   strings
sub _format
{
    my (
	$self,
	$format,	#format (in style of sprintf, but different)
	$name,		#name to format, if any  (%n)
	$value,		#value to format, if any (%v)
	) = @_;

    my $dataRh = $self->internal_data_;

    my $formatRh = $dataRh->{"format"};
    my @quotes   = @{$formatRh->{"quotes"}};

    $value = "" unless defined $value;	#allow for sformat strings

    if ( @quotes )
    {   #normal programming quotes
    	# will treat:
	#    (") double quotes as requiring escapment of common meta chars
	#    (') single quotes only escape quotes and escapes.
	# The @formats definition is expected to palce the favored quote
	# first when multiple quotes are allowed.
	my $quote;			
	while ( @quotes )
	{   #look for quote that's NOT in use
	    $quote = shift @quotes;
	    my $quoteQM = quotemeta $quote;
	    last unless $value =~ /$quoteQM/;
	}
	if ( $quote eq '"' )
	{   #oops... may need to escape things... 
	    $value =~ s/(["\\])/\\$1/g;	#escape universal
	    $value =~ s/([\$\!])/\\$1/g;	#escape shell metas as well
	}
	$value = "$quote$value$quote";		#quote the value
    }
    else
    {   #no quotes... for now assume its xml
	$value =~ s/</&lt;/g;		#dead stupid escaping, but
	$value =~ s/>/&gt;/g;		# is enough for the simple XML
					# we generate.
    }

    $format =~ s`(\%\w)`
		my $v = $1;
		if    ( '%n' eq $v )
		{
		    $v = $name    
		}
		elsif ( '%v' eq $v )
		{
		    $v = $value;
		}
		elsif ( '%p' eq $v )
		{
		    $v = lc( $dataRh->{'bno'} )
		}    
		elsif ( '%t' eq $v )
		{
		    $v = lc( $dataRh->{'buildname'} )
		}    
		$v `ge;

    return $format;
}

sub get_text
{
    my (
   	$self,
	@args ) = @_;

    my $basename0 = basename $0;

    my $dataRh = $self->internal_data_;

    #
    #   DECODE "-" arguments
    #
    my $version3;
    while ( @args && $args[0] =~ /^-(\w+)/ )
    {
	my $arg = shift @args;
	if ( $arg =~ /^-+format(=.+)?$/ )
	{
	    my $format_try;
	    if ( $1 )
	    {   #format (likely) follows "="
		( $format_try = lc $1 ) =~ s/^=//;
	    }
	    else
	    {
		$format_try = lc( shift @args );
	    }
            $format_try =~ s/['"]+//g;          #wipe any quotes
	    my $format_hashref = $self->internal_formats_($format_try);
	    if ( $format_hashref ) 
	    {   #valid entry
		$dataRh->{"format"} = $format_hashref;
	    }
	    else
	    {
                my $not = "not "  .
                        join( " ", sort $self->internal_formats_() );
use Data::Dumper;
		return "INVALID FORMAT: \"$format_try\": ignored ($not)\n"
                        . Dumper( \%formats );
	    }
	}
	elsif ( $arg =~ /^-+prefix(=.+)?$/ )
	{
	    if ( $1 )
	    {   #version (likely) follows number
		( $dataRh->{"bno"} = $1 ) =~ s/^=//;
	    }
	    else
	    {
		$dataRh->{"bno"} = shift @args;
	    }
	}
	else
	{   #invalid variable;
	    return "$0: INVALID ARGUMENT: Sys::Spec->get_text()";
	}

    }
    #
    #   START GENERATING RETURN TEXT
    #
    $dataRh->{"format"} = $formats{$format_default}
    	unless defined $dataRh->{"format"};

    my $formatRh = $dataRh->{"format"};
       $formatRh = $formats{$format_default} unless defined $formatRh;
    my $comment1 = $formatRh->{"comment1"};
    my $comment2 = $formatRh->{"comment2"};
    my $comment3 = $formatRh->{"comment3"};
    my $sformat  = $formatRh->{"sformat"};
    my $sformat1 = $formatRh->{"sformat1"};
    my @sformat2 = @{$formatRh->{"sformat2"}};

    my $return = <<RETURN;		#assure well defined
	:$comment1 System Snapshot
	:$comment2
        :$comment2   Generated file alert.
        :$comment2     * This file contains a snapshot of the local system,
        :$comment2       time, and selected version information at the
        :$comment2       time indicated below.
        :$comment2     * This file was generated by the $basename0 program
        :$comment2       using perl's Sys::Spec class.
        :$comment2     * Any changes made to this file will be lost the
        :$comment2       next time the program runs.
        :$comment2     * DISCLAIMER: there are no well honored definitions
        :$comment2       for many of these values. Therefore expect them to 
        :$comment2       drift  across operating systems, or even different
        :$comment2       distributions of the same OS or perl.
        :$comment2     * IMPORTANT: portable software must be prepared to
	:$comment2       find that some of these definitions will not be
	:$comment2       present in some run time environments.
        :$comment2  $comment3
	:$comment1    WARRANTY
	:$comment2  THIS OUTPUT IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR 
	:$comment2  IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, 
	:$comment2  THE IMPLIED WARRANTIES OF MERCHANTIBILITY
	:$comment2  AND FITNESS FOR A PARTICULAR PURPOSE.
        :$comment2  $comment3
RETURN
   $return =~ s/^\s*://mg;	#wipe leading stuff

   $return .= $self->_format( $sformat2[0] ) . "\n" if @sformat2;

   my $buildname = $dataRh->{'buildname'};	#provide default name

   my $header = ( $comment2 =~ /(\S)\s*$/
				? $1
				: "" ) x 60;

   my @ml = $self->get();		#get master list
   my $subclass_last = undef;		#subclass name put out
   my $subclass_now  = undef;		#pending subclass name

   my $caller_class  = undef;		#class to call method in.
   					#  undef for internal operations.

   while ( @ml )
   {
	my $name = shift @ml;

	if ( $name =~ /^:(\w+)/ )
	{
	    if ( !defined( $subclass_last ) ||
	         $name ne $subclass_last )
	    {
	 	 $subclass_now = $caller_class = $name;
		 $subclass_now =~ s/.*://;	#assure pure name
	    }

	    next;
	}

	my $value = $self->get($name);
	if ( $name eq "BUILDNUM"  ||
	     $name eq "VERSION_BUILDNUM" )
	{
	    $name =~ s/BUILDNUM/$dataRh->{'buildname'}/;
	}
	my $name_tmp = $name;		#name to use in generated code
	$name_tmp =~ s/.*://;
	if ( defined $value )
	{
	    if ( ! defined( $subclass_last ) ||
		 $subclass_now ne $subclass_last )
	    {   #put out heading when putting out first value
		 if ( defined $subclass_now )	#fail-safe
		 {   #expect to come through here in all cases
		     $return .= "\n\n" if $return;
		     $return .= "$comment1$header\n";
		     $return .= $comment2 . "\n";
		     $return .= "$comment2   " .
				"$subclass_now INFORMATION\n";
		     $return .= "$comment2     # " . 
		     	          $code_names{$caller_class} . "\n"
			    if exists $code_names{$caller_class};
		     $return .= $comment2 . " " . $comment3 . "\n";

		     $subclass_last = $subclass_now;
		 }
	    }

	    my $line_out = $self->_format( $sformat, $name_tmp, $value ); 
	    if ( exists $code_names{$name} )
	    {   #have a comment to put out
		my $padding = 40 - length $line_out;
		   $padding =  1 if $padding < 1;
		$line_out .= ' ' x $padding;
		$line_out .= "$comment1$code_names{$name} $comment3";
	    }
	    $line_out =~ s/\s*$/\n/;

	    $return .= $line_out;
	}
   }

   #
   #   ADD CUSTOM INFORMATION
   #
   if ( grep( /=/, @args ) )
   {

	$return .= <<EOF;
	    :\n
	    :$comment1 $header
	    :$comment2
	    :$comment2    CUSTOM SETTINGS
	    :$comment2 $comment3
EOF

	foreach my $arg ( @args )
	{
	    next unless $arg =~ /^([-.\w]+)=(.*)/;

	    $return .= $self->_format( $sformat1, $1, $2 ) . "\n";
	}
	$return .= "\n\n";
   }

   #
   #   return all text
   #
   $return =~ s/^[ \t]+://mg;

   $return .= $self->_format( $sformat2[1] ) . "\n" if @sformat2 >= 2;

   $return .= "\n\n$comment1 end of generated file $comment3\n";

   return $return;
}


1;

__END__

=pod

=back

=head1 COPYRIGHT, LICENSE, and WARRANTY

This program and documentation is copyright 2008 by Gilbert Healton.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head2 NO WARRANTY

Because the program is licensed free of charge, there is no warranty.

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
WARRANTIES, INCLUDING, WITHOUT LIMITATION, 
THE IMPLIED WARRANTIES OF MERCHANTIBILITY
AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

#end
