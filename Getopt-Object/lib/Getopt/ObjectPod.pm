# Copyright 2011 by Gilbert Healton

=pod 

=head1 NAME

Getopt::ObjectPod--Additional documentation on processing command line options via the Getopt::Object class.

=head1 SYNOPSIS

 use Getopt::Object;		#useful API to Getopt::Long
 my %config_family = ( :config1 => val1, :config2 => val2, ... );
 my %line_family   = ( opt1 => dflt1, opt2 => dflt2, ... );

 # singleton constructor recommended for command line arguments
 my $optobj = Getopt::Object->singleton(\%config_family, \%line_family);
 my $optobj = Getopt::Object->singleton(\%config_family,  %line_family);
 my $optobj = Getopt::Object->singleton(%config_family,  %line_family);
 my $optobj = Getopt::Object->singleton(%line_family,  %config_family);
 my $optobj = Getopt::Object->singleton( \%line_family );
 my $optobj = Getopt::Object->singleton(  %line_family );
   ...
 if ( $optobj->{'opt1'} )       #test --opt1 setting

 # a classic constructor (mostly  used with :ARGV option)
 $config_family{':ARGV'} = \@alternate_args;
 my $optobj = Getopt::Object->new( \%config_family, \%line_family );
 my $optobj = Getopt::Object->new( \%config_family,  %line_family );
 my $optobj = Getopt::Object->new( %config_family,  %line_family );
 my $optobj = Getopt::Object->new( %line_family,  %config_family );
 my $optobj = Getopt::Object->new( \%line_family );
 my $optobj = Getopt::Object->new(  %line_family );

 $optobj->getwarn();            #get known warnings in :WARN

 # internal support methods not expected to be used in normal calls
 $optobj->getkeys()     #keys to original %line_family
 $optobj->config()      #access embedded Getopt::Long configuration

=head1 DESCRIPTION

This document provides greater on using Getopt::Object 
not covered by the main Getopt::Object document.

Getopt::Object is an API to Getopt::Long providing a 
true object class to parse command line arguments
in a manner that the author finds more easy to set up, call,
and maintain,
compared to Getopt::Long.

Several additional features beyond classic Getopt::Long are also provided,
including a singleton constructor permitting easier sharing of options 
across modules and the ability for individual modules to 
add additional command line options to the program.

A I<DEFINITIONS> section provides definitions used herein.

An I<EXAMPLES> section provides examples beyond those in
the B<Getopt::Object> document.
Some may wish to treat this as a Quick Start.

=over 2

=over 3

=item *

Only a single constructor call is needed to
define all options, set default values,
and configure the underlying object. 

=item *

All configurations impacting the returned object
are passed in to the constructor.

=item *

To avoid polluting the callers name space no 
names can be exported to the callers package.

=item *

mod_perl safe.

=back

=back

=head2 singleton() constructor (normal)

A classic singleton constructor intended to capture 
command line options in @ARGV and making those captured arguments
to any module in the program.

Keys starting with colons (:) are not command line option names but
options changing the behavior of the constructor itself.
Only the most popular of such are described in this document.
Much more details on this subject are found in B<Getopt::ObjectPod>.

If a hashref starts the argument list that has provides ':' options
to the constructor.
Additional ':' options can be mixed in with the remaining regular 
option/default value pairs.

The remaining arguments provide key/value pairs in the style of a hash,
or a single reference to such a hash.
All all valid command line options,
how Getopt modules are to process the options,
and the default values for the options (e.g., "foo=s" =E<gt> 'bar' ),
are provided in the keys.
The values provide default values for the option.
A value of undef can be used to indicate the option has not yet been set.

By default command line options are captured and removed from @ARGV.

Success returns a reference to a hash object containing all option values.
This hash is keyed by the basic option name.

Failures return false values leaving option settings unavailable
to the caller with messages normally written to standard error
(but see B<:WARN>).
The state of @ARGV is undefined on failure returns.

Advanced Trick:
Modules compiled before the B<singleton> constructor is first called
may add additional options to the main B<singleton> call.
See B<:BEGIN> for additional details and restrictions.

    Package Foo::Bar;
    use Getopt::Object ( 'Foo_Bar_debug+' => 0 );

=head2 new() constructor (special)

The B<new> constructor is called identically to the B<singleton>()
constructor but returns distinctly unique objects.

B<new>() would be used if additional options, 
independent from other sources, needed to be parsed.
Options not associated with any command line options.
An option array reference is usually passed in with
an B<:ARG> configuration option redirecting parsing to
an array with the appropriate options.
Examples are programs that process commands in the style of shells,
parsing option files in the form of command line options.

    $opt_foo = Getopt::Object->new( { :ARGV => \@foo_argv }, ... );

The use of B<new>() is discouraged for capturing 
options from @ARGV
as other modules can not access command line options via B<singleton>.


=head2 $optobj->warn()

Returns warnings from object, as requested by the B<:WARN> option argument.

=head2 $optobj->getkeys()

Internal method not expected to be useful in normal use of Getopt::Object.

Returns array reference to a list containing all "option" keys 
identifying all command line option keys,
the order they were processed,
and how they are processed.

=head2 $optobj->config()

Internal method not expected to be useful in normal use of Getopt::Object.

Returns a reference to the Getopt::Long configuration object
Getopt::Object uses to control option parsing.

=head1 CONSTRUCTOR CONFIGURATION

The first argument to a constructor may be a hash reference 
defining options to the constructor itself
rather than command line options.
The hash keys control the options being set and tend to start with colons (":").

These ':' options may also be mixed in with the regular options.

=over 2

=over 8

=item :ARGV

Provides an alternate array reference that option parsing 
is to capture options from.
B<@ARGV> itself is left undisturbed.

As with @ARGV options are removed from this array as they are processed.

Restriction: avoid using C<(:ARGV =E<gt> \@ARGV)> 
as it can produce undefined results.

=item :BEGIN

C<:BEGIN> defaults to TRUE for B<singleton>() calls and 
FALSE for B<new>() calls.

If the option value is true then the call to the constructor 
does not need to be aware of all options the program requires.
Any C<use Getopt::Object> requests within modules compiled
I<before the B<singleton> call>
may add additional options to be used on the initial constructor call.

    package Foo::Bar;
    use Getopt::Object ( 'Foo_Bar_debug+' => 0 );

The principle restrictions are:

=over 2

=over 3

=item * 

these C<use> statements must compile before the 
first call to the singleton constructor, and

=item * 

the options do not clash with any prior options.

=back

=back

Normally only the B<singleton> constructor uses this feature.

Reminder: by default incoming option names are not case sensitive.

See ADVANCED FEATURES for more details.

=item :config

Provides an array reference to
Getopt::Long configuration options to apply to
the creation of the underlying Getopt::Long::Parser objects used by
Getopt::Long.

The Getopt::Object documentation contains an overview of options 
more likely to prove useful to callers of Getopt::Object.
Those who care can search for ::Parser in Getopt::Long documentation
for all available options,
just avoid any that seem to clash with Getopt::Object.

=item :FILE

Points to a file name that contains additional options.
These options are processed ahead of C<@ARGV> allowing 
local defaults to be established.

B<:FILE> lines,
stripped of leading spaces and the trailing new line,
are prepended to @ARGV before options are processed.

Each option should start with the hyphen in the first column of a line.

Options taking arguments must either use the C<=> notation or
provide the argument on a following line,
which should be intended by white space.
Nothing is to be quoted unless the quotes are part of an argument value

=over

Hint: the file lines are not parsed,
just prepended to the options to be parsed by Getopt::Object.

=back

Blank and comment lines are ignored.
Comments are lines where the first character is a sharp sign (#).
Embedded sharp signs in options are significant.

Note: leading or trailing white space in file names is ignored.

Note: any blanks or tabs at the end of the lines are significant.

Note: embedded white space is significant.

    #default options for foo program
    --verbose
    --first=foo-value 
    --second 
       bar-value

    # like --spaces=" hello world" on command line
    --spaces= hello world
    
    # like unshift( @ARGV, '--beware_the_quotes="hello world"' ),
    #  which is not likely what you want.
    --beware_the_quotes="hello world"

    # like unshift( @ARGV, '--wrong=not a comment   #this # would... )
    --wrong=not a comment   #this # would badly go into @ARGV

    # Add a double-hyphen if you don't want any @ARGV values 
    # from the command line to be processed by C<Getopt::Object>.
    # Such must be the last :FILE line.
    --

Restriction: things can go very bad if these options are wrong
or have syntax errors in them.
In particular extra words without leading hyphens 
can stop option processing leaving everything in @ARGV alone
(subject to change so do not rely on it).

Restriction: file names may not use characters that can provide
security violations, such as "|" in the first or last characters.

Restriction: file names must contain some character other than a digit.

Advanced: A reference to any object
supporting a C<$o->getline()> method 
may be used in place of a file name.
This includes most object oriented file handles.

=item :WARN

Provides an array reference that
constructors push warning and fatal messages into
rather than writing messages to standard error via carp.

Each array member is a string prefixed
with S<"warn "> for warnings that allowed constructors to return an object
and S<"die "> for conditions causing constructors to return false.

=back

=back

Tip: lower case keys apply to the underlying Getopt::Long objects.
Upper case keys apply to Getopt::Object.


=head1 COMMAND LINE OPTIONS

By default the names of command line options are not case sensitive. 
The case sensitivity of everything else tends to depend on the 
local operating system and program being run.

=head1 ADVANCED FEATURES

This section describes the advanced features
or features differing from normal Getopt::Long conventions.

=head2 Singleton Constructor

The first call to the singleton constructor
is intended only for capturing command line arguments
for the main executable.

The options captured by the original singleton are made available to
all subsequent callers, regardless of when loaded,
by calling this constructor again.

If the main executable does not use singleton then 
undef is returned for all subsequent singleton calls from modules.

The singleton object remains available for the duration of the execution.

Modules calling the singleton constructor with arguments can produce
undefined results.
Don't.

=head2 use Getopt::Config :config 

(Hint: C<use Getopt::Long I<class options>;> is a nifty,
if little known, feature of Getopt::Long, 
that C<Getopt::Object> twists into its own style.)

While C<use Getopt::Object> statements accept the normal C<:config> 
feature of C<use Getopt::Long>,
any options preceding C<:config> do not set exports as
Getopt::Object is a well behaved class and has no exports at all.
Rather such allow modules to define additional options,
and associated default values,
to be added to
the command line options in a limited type of late binding.

    package MyPack;
    use Getopt::Object ( "MyPack_debug:1" => 0 );

To access these options the first Getopt::Object->singleton() or
new() call 
I<must include a configuration option of C<:BEGIN =E<gt> 1>>.
This is the default only for B<singleton>.

Restriction: setting B<:config> in use statements
is discouraged in any file but the main executable.
B<:config> is beyond the scope of this document...
set B<Getopt::Long> for details.

Restriction: adding ':config' options outside of ".pm" modules read in
when the main program is compiled is discouraged, and may not work.
Use ':config' in the constructor call.

Restriction: Getopt::Object ":" configuration options 
(e.g., C<:ARGV>) 
can not be given here.

Restriction: These "late binding" options must be well defined
before the first call to the constructor.
Failure to observe this requirements produces a "too late" warning.

=head2 Getopt::Long::Parser

Under the hood Getopt::Object uses Getopt::Long::Parser-E<gt>new()
to create an appropriate object that is 
saved as a member of the returned object.
While a $optobj->config() accessor provides 
access this object for completeness,
it is not expected to have any meaningful value to typical callers.
Getopt::Object objects are not Getopt::Long::Parser objects.

Typically any options to Getopt::Object::Parser 
are be passed down by use of a B<:config> option to
the Getopt::Object constructor.

   Getopt::Object->singleton( { :config => [ qw( bundling ) ] }, 
			'foo=s' => 1, ... 

The array reference value of B<:config> contains
options in the native format of Getopt::Long::Parser.

=head1 DEFINITIONS

A few definitions may help reduce confusion

=over +6

=item Command line options:

"-" or "--" I<options> captured by Getopt::Object
that usually modifies the program behavior.

These are typically provided on the command line but
can also be defined in files via C<:FILE>.

=item Command line arguments:

Any settings on command lines following all "-" or "--" options
providing additional information to the program 
that is not captured by Getopt::Object.

=item Option Arguments:

Some command line options take I<arguments> providing values
to the command line option.
A typical example is C<--outfile=target.txt>, 
where <I>target.txt</I> is the option argument.

=item Option configuration:

Settings defined in keys
controlling how command line options are processed 
(e.g., the C<=s> of C<outfile=s>).

=item Object Configuration:

configurations applying to the object itself.
These are typically provided by the developer in the constructor call.

=back

=head1 EXAMPLES

=head2 Advanced Tricks

     command --array_arg=hello --array_arg world 
     command --hash_arg=hello=world  --hash_arg foo=bar

 use Getopt::Object;
  . . .
 my $optobj = Getopt::Object->singleton(
 			'array_arg=s' => [],	#array collects all
 			'hash_arg=s'  => {},	#hash collects all
 			'array_must==s' => [],	#values must be defined
 			'hash_must==s'  => {},	#values and keys defined
                );

When B<==> is used with arrays or hashes at least one member must be
present and all values well defined.
With hashes all keys must be well defined as well.

=head2 User-Defined Subroutines

     command --user_sub=s

 use Getopt::Object;
  . . .
 my $optobj = Getopt::Object->singleton(

        'do_not_try_this_at_home=s' => sub 
               {  #demonstration of a bug... do not do this!
                 our $getopt_obj_hash;  #preobject from Getopt::Object
                 &{$getopt_obj_hash->{'very_wrong'}}($self, @_);  #BAD!
                  # calls via object members is bad!
               },

        'very_wrong=s' => sub 
               { #calling Getopt::Object subs is bad
                 # (user_sub is in callers package, 
                 #  not in Getopt::Object)
                 our $getopt_obj_hash;
                 $getopt_obj_hash->user_sub(@_);  
               },

        'this_is_just_fine=s' => sub 
               {  #demonstration of good code
                 our $getopt_obj_hash;             #object under construction
                 my ( $option_name, $value ) = @_;
                 $getopt_obj_hash->{"_$option_name"} = $value;
               },
        );

C<Getopt::Object> honors C<Getopt::Long>'s support of
user-defined subroutines to process options, but with a small twist.
User-defined subroutines are called as before with the addition of
a temporary C<$getopt_obj_hash> hash reference variable 
in the package the constructor call is in that points to the object
being constructed before all arguments have been captured.

The default value provides a reference to a
user-defined subroutine that processes the option.
Where the final value is actually saved is up to the called subroutine,
but using C<$getopt_obj_hash> is likely best 
using an appropriate key slightly different from the option's key.
C<$getopt_obj_hash> points to a currently incomplete object hash 
I<so using the same key name will dangerously overwrite the default value>.
The above code fragment saves values under a key starting with a "_" prefix.

Avoid use of C<==> to assure well defined values with 
user provided subroutines
as the subroutine reference is always well defined.

Restriction: 
user-defined subs can not call other user-defined subs
through references in the preobject.
The C<do_not_try_this_at_home> option in the sample code
demonstrates this problem.
Directly calling other user-defined subs by name is fine,
but using object references will fail due to internal housekeeping
during constructor calls.
How this works is very much subject to change without notice so 
depending on it is a bug.

=head1 ALSO SEE

The documentation for B<Getopt::Long> for the many variations, options,
and all of the obscure and advanced behaviors available to callers
of B<Getopt::Object> that are not covered herein.

B<Getopt::ObjectSimple> provides a much simpler, and smaller,
interface to Getopt::Long.
If both B<Getopt::Object> and B<Getopt::ObjectSimple> are used in
the same program than B<Getopt::Object> will be used even for
calls to B<Getopt::ObjectSimple> constructors.
The only practical way to maintain state sanity is for both 'use'
statements to be made before the first constructor call to either class.

=head1 RESTRICTIONS

Direct mixing of Getopt::Long and Getopt::Object classes is to be avoided.

Callers should use the :ARGV option rather than C<local @ARGV> to 
process alternate arguments.

The singleton constructor has several restrictions.
See singleton documentation for details.

The :BEGIN object configuration option has several restrictions.
See it's documentation for details.

=head1 NOTES

As Getopt::Object->new() objects are independent from each other
callers may have multiple objects at the same time without problems,
aside from clashes over C<@ARGV>,
which can be resolved by using the C<:ARGV> option
(but not always by callers providing a C<local @ARGV> for the override).

Getopt::Object also has private internal members in the object 
in addition to command line arguments.
The keys for such internal members always start with a colon (:),
which must be ignored by callers as these keys are subject to change
without notice.

=head1 COPYRIGHT AND LICENSE

This program is Copyright 2011 to 2012 by Gilbert Healton
S<E<lt>B<gilbert@healton.net>E<gt>>.
This program is free software; you can redistribute it and/or
modify it under the terms of the Perl Artistic License or the
GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

If you do not have a copy of the GNU General Public License write to
the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,
MA 02139, USA.

This module is free software; you can redistribute it and/or 
modify it under the same terms as Perl 5.8.10, or later.
For more details, see the full text of the licenses at
<http://www.perlfoundation.org/artistic_license_1_0>,
and <http://www.gnu.org/licenses/gpl-2.0.html>.

=head1 REPOSITORY

https://github.com/GilbertsHub/CPAN and see Getopt-Object therein.

=head1 ACKNOLDGEMENTS

To S<Johan Vromans E<lt>jvromansE<64>squirrelE<46>nlE<gt>>,
author of the B<Getopt::Long> module,
which is the base class for B<Getopt::Object>.

=cut

0;              #do not allow 'use Getopt::ObjectPod;';
