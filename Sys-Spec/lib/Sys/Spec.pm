# package to create build number 

use strict;

use 5.005;

package Sys::Spec;

our $VERSION = '3.001';

=head1 NAME

Sys::Spec - return available information on the current system
in textual format.

=head1 SYNOPSIS

 use Sys::Spec;

 $ss = Sys::Spec->new( 
	[-buildnum|installnum|patchnum|runnum=version | 
	        -id=name=version] )

 $valid_name = $ss->isvalid($trial_name); #check if $name is valid

 @m = $ss->get();		 #array of headers and keys
 $value = $ss->get($valid_name); #get specific value

 # extend Sys::Spec to get full text file
 $ss = Sys::Spec::Text->new( same as before )

 $ss->is_unixish();
 $ss->is_windowsh();

 $module = Sys::Spec->module();
 Sys::Spec->is_unixish();
 Sys::Spec->is_windowsh();

 Sys::Spec->insert( $heading, @item_list );

=head1 DESCRIPTION

This class obtains information about the current system that
has a long history of being useful to software developers
and support personnel working on systems of unknown type.
While written to support the B<sys-spec> program it
makes diverse information available to perl programs from a single class.

The "available information" includes the version of each 
B<Sys::Spec> module used to generate output.

One goal was to present a single, convient, interface to
information gathered from varied sources.

The published class functions and methods follow:

=over 2

=over 4

=cut


use POSIX;

use Carp;

use Config;	#import %Config from perl's master config list

use File::Basename;

my $fmt8601 = '%Y-%m-%dT%H:%M:%S';	#ISO 8601 format, as used herein

my $ml_inc = 1;				#@master_list internal increment

=pod

=item $ss = Sys::Spec->new(...)

Gathers information about the local system,
returning it in an object as a series of key/value pairs.

Valid arguments:

=over 2

=over 5

=item -buildnum|installnum|patchnum|runnum=version 
=item -buildnum|installnum|patchnum|runnum => version 
=item -id=name=version 

Provides the version of a specific application running on the system
whos information is being obtained by this class.
This results in a BUILDNUM and VERSION variables being emitted by
calls to B<get_text>().

See the B<sys-spec> program for more details on these values.

=back

=back

=cut

my $module;

my @master_list;

my %data;	#hash of current object
		#   key:   $self for object, as string (no longer reference)
		#   value: hashref to object members
		#            keys:  
		#              * lc: internal values that need to be kept
		#              * uc: public values for settings

sub internal_data_
{
    my $self = shift;
    return $data{$self};
}

sub new
{
   my (
	$proto,
	@args,
		) = @_;

   _init() unless $module;

   my $class = ( ref $proto ) ? ( ref $proto ) : $proto;

   my $self = \do { use vars qw( *globx ); local *globx };
   bless $self, $class;
   	# BEWARE: _init() below builds @ISA pointing to the $class module,
	#  and NOT the otherway around, as is typical.

   my $dataRh = $data{$self} = {};

   $dataRh->{'tmp'} = {};	#reserved for temporary "constructor only" data

   my $inc_delim = ( $ =~ /^MSWin/i ) ? ";" : ":"; 
   $dataRh->{"inc_delim"} = $inc_delim;
   $dataRh->{"buildname"} = "TSTAMP_CODE";	#default name

   #
   #   DEFAULT VALUES get_text() MAY CHANGE
   #
   $dataRh->{"bno"}   = 'bno_';
   $dataRh->{"debug"} = 0;

   #
   #   DECODE "-" arguments
   #
   my $version3;
   while ( @args && $args[0] =~ /^-(\w+)/ )
   {
	my $arg = shift @args;
		 # (different codes have different opening letters)
	if ( $arg =~ /^-+(buildnum|installnum|patchnum|runnum)(=.+)?$/ )
	{   
	    my $name    = $1;
	    if ( $2 )
	    {   #version (likely) follows number
		( $version3 = $2 ) =~ s/^=//;
	    }
	    else
	    {
		$version3 = shift @args;
	    }

	    $dataRh->{'version3'}  = $version3;
	    $dataRh->{'buildname'} = uc $name;
	    $dataRh->{"bno"} = substr( $name, 0, 1 ) . "no_";
	}
	elsif ( $arg =~ /^-+id(=(\w)=(.+))?$/ )
	{
	    my $id = "ID";		#set a default name
	    if ( $1 )
	    {   #name and version follows number
		$id = $2;
		( $version3 = $3 ) =~ s/^=//;
	    }
	    else
	    {
		my $arg = shift @args;
		if ( $arg =~ /^(\w+)=(.+)?$/ )
		{
		    $id = $1;
		    $version3 = $2;
		}
		else
		{   #assume only version number given
		    $version3 = $arg;
	        }
	    }
	    $dataRh->{'version3'}   = $version3;
	    $dataRh->{'buildname'} = $id;
	    $dataRh->{"bno"} = "$id\_";
	}
	elsif ( $arg =~ /^-+debug(=(\d+))?$/ )
	{
	    ++$dataRh->{'debug'};	#suppose incrementing level
	    $dataRh->{'debug'} = $2 if defined($2) && length($2);
	}
	else
	{   #invalid variable;
	    carp "$0: INVALID OPTION: Sys::Spec($arg)";
	    return undef;
	}
   }

   #
   #   ACQUIRE ALL STRING VALUES FROM APPROPRIATE CLASSES
   #
   my $subclass;
   for ( my $m = 0; $m < @master_list; $m += $ml_inc )
   {
	my ( $master ) = ( @master_list[($m,$m+$ml_inc-1)] );

	if ( $master =~ /^:(.+)$/ )
	{
	    $subclass = __PACKAGE__ . "::Internal::$1";
	    next;
	}

	my $ix = index( $master, "Sys::Spec::Module" );
	local $2;		#assure $2 empty
	my $value;
	if ( $master =~ /^(.*[^:])::(\w+)$/   &&  $ix != 0 )
	{   #user supplied function:
	    #   # caller does not get access to private data members
	    #   # function is in caller's class
	    my $c_class  = $1;
	    my $name_lc  = lc($2);
	    my $call_ref = UNIVERSAL::can( $c_class, $name_lc )  or
		die "->$c_class\::$name_lc does not exist. stopped";
	    $value = $self->$call_ref( $name_lc );
	}
	else
	{   #internal class... safe to pass private members
	    #   ix!=0: SimpleName: internal to Sys::Spec.pm. 
	    #             Expect straight Internal class.
	    #   ix==0: Sys::Spec::Module::HEADING_CLASS: module supporting 
	    #             this heading class (modules supporting multiple
	    #             heading classes will call insert() multiple times)
	    my ( $c_class, $name_lc )  = ( $ix == 0 )
	    			? ( $1, lc($2) )
	    			: ( $subclass, lc($master) );
	    my $call_ref = UNIVERSAL::can( $c_class, $name_lc )  or
		die "->$subclass\::$name_lc does not exist. stopped";
	    $value = $self->$call_ref( $dataRh, $name_lc );
	}

	$dataRh->{$master} = $value if defined $value;
   }

   delete $dataRh->{'tmp'};	#wipe temporary

   return $self;
}

sub DESTROY
{
   my $self = shift;

   if ( exists $data{$self} )
   {
	delete $data{$self}{'tmp'};	#wipe temporary
	delete $data{$self};		#wipe any remaining members
   }
   return
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }

sub _Config
{
   my ( $self, $dataRh, $name ) = @_;

    my $config_key =  lc $name;
   $config_key   =~ s/^perl_os_// ||
     $config_key =~ s/^perl_//;

   return exists $Config{$config_key}
             ?   $Config{$config_key}
             :   undef;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }
#
#   TEMPLATE SUBCLASS
#
{ package Sys::Spec::Internal::TEMPLATE ;

push( @master_list, qw( 
   ) );


sub template
{
   # my ( $self, $dataRh, $name ) = @_;
   # my ( $self, $dataRh ) = @_;
   # my ( $self ) = @_;

   return
}

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }
#
#   TIME SUBCLASS
#
{ package Sys::Spec::Internal::TIME ;

use POSIX;

push( @master_list, qw( 
      :TIME 
	TIME_T
	TIME_UTC
	TIME_LOCAL
	TIMEZONE_NAME
	TIMEZONE_OFFSET
	BUILDNUM
  ) );


sub time_t
{
   my ( $self ) = @_;

   return ( exists $ENV{'SYS_SPEC_TIME0'} && 
		     defined $ENV{'SYS_SPEC_TIME0'}  &&
		     $ENV{'SYS_SPEC_TIME0'} =~ /^\d+$/ )
			? $ENV{'SYS_SPEC_TIME0'} #use given time 
			: time;		         #use true time
}

sub time_utc
{
   my ( $self, $dataRh, $tmpRh, $name ) = @_;

   my @gmtime = gmtime $self->get( 'TIME_T' );
   $dataRh->{'gmtime'} = \@gmtime;
   return strftime( $fmt8601, @gmtime );
}

sub time_local
{
   my ( $self, $dataRh ) = @_;

   my @localtime = localtime $self->get( 'TIME_T' );
   $dataRh->{'localtime'} = \@localtime;
   return strftime( $fmt8601, @localtime );
}

sub timezone_name
{
   my ( $self, $dataRh ) = @_;

   my $localtimeRa = $dataRh->{'localtime'};
   my $zone_stuff = strftime( '%z|ZZZZZZ|%Z', @$localtimeRa );
   my $zone_numeric = undef;
   $zone_numeric = $1 if $zone_stuff =~ /^([^|]*)\|ZZZZZZ/;
   my $zone_name    = undef;
   $zone_name    = $1 if $zone_stuff =~ /ZZZZZZ\|([^|]*)$/;

   # it's been observed that some systems fill both with name (Win32)
   if ( defined($zone_numeric) && defined ($zone_name) &&
	$zone_name eq $zone_numeric  &&  
	$zone_numeric =~ /([a-z].*){5}/ )
   {   #zap the number if looks like name
 	$zone_numeric = undef;
   }

   $dataRh->{'tmp'}{'zone_numeric'} = $zone_numeric;

   return $zone_name;		#%Z in ANSI-C specification 
}

sub timezone_offset
{
   my ( $self, $dataRh ) = @_;
   my $zone_numeric = $dataRh->{'tmp'}{'zone_numeric'};	#number, as _string_
   return $zone_numeric;	#return string
}

sub buildnum
{    #regardless of -run, -build, -id, internally keep at "buildnum" 
   my ( $self, $dataRh ) = @_;
   my $gmtimeRa = $dataRh->{'gmtime'};

   return sprintf( '%02d%03d%02d%1d',
			    $gmtimeRa->[5]+1900-2000,
				$gmtimeRa->[7]+1,
				    $gmtimeRa->[2],
					int( $gmtimeRa->[1] / 6 ) );
}

}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }
#
#   VERSION SUBCLASS
#
{ package Sys::Spec::Internal::VERSION ;

push( @master_list, qw(
      :VERSION
	VERSION_BUILDNUM
        VERSION3
	VERSION2
	VERSION1
  ) );

# everything combined into one
sub version_buildnum
{
   my ( $self, $dataRh ) = @_;

   my $version = $dataRh->{'version3'};
   return undef unless $version;

   return $version . "." . $self->get('BUILDNUM');
}

sub version3
{
   my ( $self, $dataRh ) = @_;

   return $dataRh->{'version3'};
}

   # assure just major/minor information is available
sub version2
{
   my ( $self, $dataRh ) = @_;

   my $version2 = $dataRh->{'version3'};
   return undef unless defined $version2;
   $version2 =~ s/(^[^.,]+[.,][^.,]+).*/$1/;
   return $version2;
}

   # assure just majorr nformation is available
sub version1
{
   my ( $self, $dataRh ) = @_;

   my $version1 = $dataRh->{'version3'};
   return undef unless defined $version1;
   $version1 =~ s/[.,].*//;
   return $version1;
}

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }
#
#   HARDWARE SUBCLASS
#
{ package Sys::Spec::Internal::HARDWARE ;

use POSIX;

push( @master_list, qw(
     :HARDWARE
        U_HOSTNAME
	U_ARCH
	PERL_ARCHNAME
	PERL_ARCHNAME64
 ) );

sub u_hostname
{
   my ( $self, $dataRh ) = @_;

   # define the uname stuff here
   my @uname = POSIX::uname();		#get values, POSIX style
   $dataRh->{'uname'} = { map { ( $_, shift @uname ) } qw(
	     u_sysname u_nodename u_release u_version u_machine ) };
	     # Linux   myhost    2.6.26.6-49.fc8; xxx   i686
   	# NOTE: uname values are not standardized. 
	# See warning in `perldoc POSIX` man page.

   # now reference it
   my $u_hostname = $dataRh->{'uname'}{'u_nodename'};
   $u_hostname =~ s/\..*//;	#for security, chop off high-level names
   return $u_hostname;
}

sub u_arch
{
   my ( $self, $dataRh ) = @_;

   return $dataRh->{'uname'}{'u_machine'};
}

  # (redirect to _Config)
use vars qw( *perl_os_archname $perl_os_archname64 );
*perl_archname   = *perl_archname   = \&Sys::Spec::_Config;
*perl_archname64 = *perl_archname64 =\&Sys::Spec::_Config;
    # (assign twice to keep `perl -cw` happy by avoiding single ref)
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }
#
#   OS SUBCLASS
#
{ package Sys::Spec::Internal::OS ;

push( @master_list, qw(
      :OS 
        U_OS_NAME
	U_OSRELEASE
	U_OSVERSION
	PERL_OS_NAME
   ) );

sub u_os_name
{
   my ( $self, $dataRh ) = @_;

   return $dataRh->{'uname'}{'u_sysname'};
}

sub u_osrelease
{
   my ( $self, $dataRh ) = @_;

   return $dataRh->{'uname'}{'u_release'};
}

sub u_osversion
{
   my ( $self, $dataRh ) = @_;

   return $dataRh->{'uname'}{'u_version'};
}

sub perl_os_name
{
   return $;		#straight from perl's mouth
}


}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }
#
#   PERL SUBCLASS
#
{ package Sys::Spec::Internal::PERL ;

push( @master_list, qw(
      :PERL 	
        PERL_VERSION
	PERL_USETHREADS
	PERL_INC
 ) );

  # (redirect to _Config)
use vars qw( *perl_usethreads );
*perl_usethreads = \&Sys::Spec::_Config;


sub perl_version
{
   return $]
}

sub perl_inc
{
   my ( $self, $dataRh ) = @_;
   my $inc_delim = $dataRh->{"inc_delim"};

   my $ml_inc = join( $inc_delim, @INC );

  return $ml_inc; 
}

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }
#
#   USER SUBCLASS 
#
{ package Sys::Spec::Internal::USER ;

push( @master_list, qw(
      :USER
       UID	
	UNAME	
	UNAME_LONG
	GID	
	GNAME
 ) );

sub uid
{
   return $>;
}

sub uname
{
   my ( $self, $dataRh ) = @_;

   local $@;
   my ( $p_name, $p_passwd, $p_uid, $p_gid, $p_quote, $p_comment, $p_gcos, @p);
   eval
   {   #Microsoft Windows, and likely other OSs, do not support password files
       ( $p_name, $p_passwd, $p_uid, $p_gid, $p_quote, $p_comment, $p_gcos,@p)=
		getpwuid( $dataRh->{'UID'} );
       $p_name    = "<unknown>" unless defined $p_name && $p_name =~ m/\S/;
       $p_gcos = "" unless defined $p_gcos && $p_gcos =~ m/\S/;
	$dataRh->{'tmp'}{'pw_gid'}     = $p_gid;
	$dataRh->{'tmp'}{'uname_long'} = $p_gcos;
   };

   return $p_name;
}

sub uname_long
{
   my ( $self, $dataRh ) = @_;
   return $dataRh->{'tmp'}{'uname_long'};
}

sub gid
{
   my ( $self, $dataRh ) = @_;

   my $gid = $);
   if ( ! $gid )
   {   #systems without concepts of "group" tend to return false $gid
	$gid = undef unless defined $dataRh->{'tmp'}{'pw_gid'};
		# if pw_gid undefined, indicates getpwuid() failed,
		# which indicates no concepts of groups.
   }
   $gid =~ s/\D.*//	#only keep first number if multiple values
   	if defined $gid;
   return $gid;
}

sub gname
{
   my ( $self, $dataRh ) = @_;

   my ( $g_name, $g_passwd, $g_gid, $g_members );
   local $@;
   eval 
   {   #just in case groups are not supported even if passwords are
	( $g_name, $g_passwd, $g_gid, $g_members ) = 
					getgrgid( $dataRh->{'GID'} );
	$g_name = "<unknown>" unless defined $g_name && $g_name =~ /\S/;
   } if exists $dataRh->{'GID'};
   unless ( defined($g_name) && length($g_name) )
   {
       $g_name = undef;	#assure undefined if no group names
   }

   return $g_name;
}

}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # }
#
#   INTERNAL_VERSIONS SUBCLASS
#
{ package Sys::Spec::Internal::INTERNAL_VERSIONS;

push( @master_list, qw(
 	 :INTERNAL_VERSIONS
	 IV_SYS_SPEC_VERSION
 ) );


sub iv_sys_spec_version
{
   return $Sys::Spec::VERSION;
}


}

=pod

=item $valid_name = $ss->isvalid( $trail_name )

Indicates if the $trail_name is a valid variable name for the B<get>() method.

Returns false if the $trial_name key is not valid.
Returns the ideal B<get>() key if the trial key is valid.
This key may have a class name prefix.

B<isvalid>() can cope with common difficlties with incoming keys,
such as the case not matching that of the actual key.
If the trial key would be valid if a class identifier prefix existed,
the prefix is added, and included in the return value.

NOTE: B<get>() returns undef for both invalid keys and
keys that are officially valid,
but the current call can not extract.
Use of B<isvalid>() is the only way to determine if a key is valid or not.

RESTRICTION:
If the $trial_name argument has a class prefix,
the prefix must be exact.
In the expected case prefixes are not used.

RESTRICTION:
All variable names, internal and external,
must be unique.
Even across case boundries.
Having two variable names that differ only in case represents
an undefined condition.

=cut

sub isvalid
{
   my (
   	$self,
        $name,
	) = @_;

   return undef unless exists $data{$self};
   my $dataRh = $data{$self};	

   unless ( exists $dataRh->{$name} )
   {    #name does not exist: give class name a try
	my $lcn = lc( quotemeta( $name ) ); #^\w+$ or bust
	my @hits;
	foreach my $key ( @master_list )
	{   #search list for variations on names
	    next if $key =~ /^:/;	#ignore heading markers
	    my $lc_key = lc $key;
	    push( @hits, $key )  if $lc_key eq $lcn  ||
		  		    $lc_key =~ /:$lcn$/i;
	}
	return undef unless @hits == 1;
	$name = $hits[0];
   }

   return undef unless exists $dataRh->{$name};

   return $name;
}


=pod

=item @key_list = $ss->get()
=item $value = $ss->get($key)

The B<get>() method provides callers access to values 
discoved by B<new>().

The first argument signature returns an array containing
all headers and keys for information Sys::Spec might be able to retrieve.
Headers are identified using names that start with
a colon (:) followed by a valid symbol name.

The second returns any value associated with a specific key,
or undef if a value could not be obtained.
The key may be a simple symbol or include a class name before the final
item name.
The final item name uses all upper case character.
A few other internal keys are available and should be considered
"protected" elements
available to internal B<Sys::Spec> operations but not to it's callers.

=cut

sub get
{
   my (
   	$self_or_class,		# (Sys::Spec->get() is only valid class call)
        $name,
	) = @_;

   if ( @_ <= 1 )
   {   #return COPY of master list if no name given
	my $caller = caller;
	return @master_list if wantarray; #return copy of data in array context
	return [ @master_list ];          #return deep copy to protect original
   }

   # NOTE: from this point on $self_or_class is always $self, no class name

   return undef unless exists $data{$self_or_class};
   my $dataRh = $data{$self_or_class};

   unless ( exists $dataRh->{$name} )
   {    #name does not exist, at least as given: check if actually valid
	$name = $self_or_class->isvalid($name);
	return undef unless $name;
   }

   return undef unless exists $dataRh->{$name};

   return $dataRh->{$name};
}


=pod

=item Sys::Spec->insert( $heading, @names );

This class function allows friends of Spec to add their
version numbers,
and additional values specific to a particular system,
to the master variable list.
This is only intended for use by classes extending Sys::Spec to
enable Sys::Spec to include the output of these additional classes
in its list of information.

=over 2

=over 2

=item $heading:

Heading to register function under,
which controls where the associated variables are generated in the output.
See the results of calls to B<get>(), without arguments, 
for a list of current headings.

Always starts with a leading colon (:) and does not contain white space.
Must be a valid variable name, 
all in upper case,
as well as descriptive text.

New headings can be created by simply registering them.

=item @names

Names of variables, as they are to appear in the output.
A corresponding function name must exist in the current package/class,
with the same name, I<execpt all in lower case letters>.

=back

=back

Returns number of registered headings/variables on success.
Returns undef on error. 

=over 2 

The order that new function names registered with B<insert>()
are called in are guaranteed to follow
the order in the B<insert>() call.
This guarantee excludes replacement function names,
names registered by different B<insert>() calls,
or registered under different headings.

=back 

=cut

sub insert
{
   return undef unless @_ >= 3;

   my (
   	$class,
	$heading,
	@names ) = @_;

   _init() unless $module;

   # validate and extract heading
   my $heading_tmp = $heading;		#make working copy of 
   return undef 			#insist on valid head names
   	unless $heading =~ /^:+[a-z]\w+$/i;	#
		# (beware that the above is subject to change)
   my $headingQM = quotemeta $heading_tmp;  #assure safe

   my ( $package ) = caller;		#package name of caller

   #
   #   look for heading in existing list
   #
   my $h;		#becomes index in @master_list to insert into
   my $h2 = @master_list;	#suppose new heading to insert at end
   for ( $h = $#master_list; $h >= 0; $h -= $ml_inc )
   {
	if ( $master_list[$h] =~ /^:/ )
	{   #some type of heading
	    last if $master_list[$h] =~ /$headingQM$/i;

	    $h2 = $h;		#heading, but not ours. 
	}
   }

   my @insert;		#holds what to insert, including any heading

   if ( $h < 0 )
   {   #did NOT find heading... will insert onto end
	push( @insert, $heading_tmp );
	$h2 = @master_list;	#insert into end of list
   }

   #
   #   validate arguments
   #
   for ( my $n = 0; $n < @names; $n += $ml_inc )
   {
       my $name = $names[$n];	#pick off variable name
	if ( $name =~ /^[a-z]\w+$/i )
	{   #simple name: keep it if looks safe
	    my $namex = "$package\::$name";
	    push( @insert, $namex )
	    	unless grep { lc($_) eq lc $namex } ( @master_list, @insert );
	}
   }
   #
   #   stuff arguments into correct place
   #
   splice( @master_list, $h2, 0, @insert ) if @insert >= 1;

   return scalar @master_list;
}

=pod

=item $code = Sys::Spec->module();

Returns the internal symbolic system type used by Sys::Spec to
determine how to gaher information from the local system.
Used to read in the Sys::Spec::Module::Xyx module on
Xyx systems.
Lots of cautions in using this outside of Sys::Spec!

=cut

	# Shamelessly stolen from File::Spec, but commenting out
	# systems I have no access to but hope others will
	# augment with. Likley will grow in different ways than
	# File::Spec.
my %module = (
	      # MacOS   => 'Mac',
	      MSWin32 => 'Win32',
	      # os2     => 'OS2',
	      # VMS     => 'VMS',
	      # epoc    => 'Epoc',
	      NetWare => 'Win32', # does File::Spec::Win32 works on NetWare?
	      symbian => 'Win32', # eoes File::Spec::Win32 works on symbian?
	      # dos     => 'OS2',   # Yes, File::Spec::OS2 works on DJGPP.
	      # cygwin  => 'Cygwin'
	    );


=pod

=item Sys::Spec->is_unixish();
=item Sys::Spec->is_windowish();

Returns if the local system behaves like the named system.
Returns false, which may be under, if not.

These may be used as class or object methods.

At this time only the above functions are provided.
It is hoped that others will extend Sys::Spec to systems the
current developer does not have available to him.

=cut
sub module
{
    _init() unless $module;
    return $module;
}


sub is_unixish
{
    _init() unless $module;
    return $module =~ /^Unix/;
   
}

sub is_windowsish
{
    _init() unless $module;
    return $module =~ /^Win/;
}

sub _init		#internal one-time init
{
    $module = ( exists( $module{$} ) && $module{$^O} ) || 'Unix';

    require "Sys/Spec/Module/$module.pm";	#read in at run time after
    						# all other modules available

    my $c = "Sys::Spec::Module::$module";	#class to use
    my $init = UNIVERSAL::can( $c, "init_" );
    push( @ISA, $c->$init() );
		# note: @ISA chain starts at non-traditional place!
}


1;

__END__

=pod

=back

=back

=head1 SECURITY

To help maintain the security of systems Sys::Spec gathers information 
this author does not provide methods that return 
unique information that can identify a specific host to outside readers.
The closest that is returned is the host name and user name, group,
if any are defined on the local system.
The host name is stripped of any domain information and it is hoped 
that the user names will not mean much out of context of the host,
or location, the information come from.
Still, be careful how the results are distributed.

=head1 DISCLAIMER

Given the fact that there are no standards for what many of the 
system calls, files, etc., used to obtain the returned information 
should hold, or even mean, 
there is no warranty from the author on the usability of the 
software or the values returned by it.
Still, this author finds programs like this very useful.

Before using a value it is best to wander though the sample files
included with the package to look at what values from different
operating systems include, and how they differ.


=head1 ENVIRONMENT

If the environment variable B<SYS_SPEC_TIME0> exists when B<new> is called
it must contain the “official time” for the build,
as returned by perl's core B<time>() function.

  export SYS_SPEC_TIME0=$(time -u %s);	#as shell command (Linux)
  export SYS_SPEC_TIME0=$(perl -e 'print time,"\n"'); #general shell
  local $ENV{'SYS_SPEC_TIME0'} = time;	#as perl statement

Note: the B<local> in the perl line restricts the existance of the variable 
to the scope of the current {block}. Omit B<local> for global scope.

=head1 SEE ALSO

B<sys-spec>(1),
B<uname>(3),
B<POSIX::uname>(3p),
C<use Config>.

See the B<Sys::Spec::Text> class extends B<Sys::Spec> to generate 
code in several formats containing all available values.

=head1 AUTHOR

Gilbert Healton <F<gilbert@healton.net>>.


=head1 ACKNOWLEDGEMENTS

All those contributing to the early authors of the File::Spec class for
the idea of how to get different behavior on different systems.
The 5.005_04 author list credits
Kenneth Albanowski <F<kjahds@kjahds.com>>, Andy Dougherty
<F<doughera@lafcol.lafayette.edu>>, Andreas KE<ouml>nig
<F<A.Koenig@franz.ww.TU-Berlin.DE>>, and Tim Bunce <F<Tim.Bunce@ig.co.uk>>. 

=head1 HELP WANTED

If you find this program useful and want to extend it
to other operating systems,
the authour would really like to hear from you.

Any corrections to documentation or bug fixes would also be apprciated 
to no __END__.

=head1 REPOSITORY

https://github.com/GilbertsHub/CPAN and see Sys-Spec therein.

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

# end
