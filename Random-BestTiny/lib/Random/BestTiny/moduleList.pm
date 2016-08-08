# Random::BestTiny::moduleList - random numbers 

use strict;

package Random::BestTiny::moduleList;

use vars qw( $VERSION @ISA );
our $VERSION = '0.2';

=pod

=head1 NAME

Random::BestTiny::modulelist package

=head1 USAGE

 use Random::BestTiny::modulelist;

 $module  = Random::BestTiny::moudleList->module_();
 %modules = Random::BestTiny::moudleList->module_list();

=head1 DESCRIPTION

This is an internal class not intended to be used by applications.

Random::BestTiny::moudleList->module_() uses module_list()
to return the best API name for the local operating system.

Random::BestTiny::moduleList->module_list() returns the master map 
to determine the best Random::BestTiny API for the local OS.

=head1 RETURNS

=head2 module_()

If the OS type matches one of the keys returned by B<module_list()> then
the corresponding module name is returned.
This does not normally include the "Unix" API.

Else if the local OS is not within B<module_list()> then a check for
a "/dev/urandom" file is found.
If found then a Unix style API is assumed.
Else a "Rand" API is the last ditch default.

=head2 module_list_()

Returns an array of name/value 
pairs in the form of a hash that shows the different APIs for 
different operating systems.

=head1 RESTRICTIONS

This class gives a view of the system highly warped to random number production
and should not be used for other purposes.

=head1 REPOSITORY

https://github.com/GilbertsHub/CPAN   Random-BestTiny

=head1 COPYRIGHT AND LICENSE

Copyright 2011, 2016 by Gilbert Healton.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 NOTES

If an application needs a new random number API but the developer can not,
or does not want to, add the module to the system library, 
the API module can be added to another directory that is placed earlier on 
the search path than native perl modules.
A custom Random::BestTiny::moduleList module can also be provided to redirect
BesOS to the desired module.

=cut

use File::Spec;

my %moduleList = (
	      # MacOS   => 'Mac',
	      MSWin32 => 'Win32',
	      # os2     => 'OS2',
	      # VMS     => 'VMS',
	      # epoc    => 'Epoc',
	      NetWare => 'Win32', # is Random::BestTiny::ApiWin32 OK on NetWare?
	      symbian => 'Win32', # is Random::BestTiny::ApiWin32 OK on symbian?
	      dos       => 'Rand', # native DOS is hopeless on good random numbers
	      # cygwin  => 'Cygwin'
	  );

sub moduleList_ { return %moduleList };

sub module_ 
{
    return ( exists($moduleList{$^O}) && $moduleList{$^O} ) ?
                    $moduleList{$^O}   :
                    -e File::Spec->catfile( "", qw( dev urandom ) )  ?
                       'Unix'            :      #UNIX style seems present
                       'Rand'            ;      #fall back to sure but stupid
}

1;
