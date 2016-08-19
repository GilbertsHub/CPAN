# CPAN
Perl packages in the style of CPAN, perhaps on CPAN.

Status: reasonably complete for typical use.

## Getopt-Object
Getopt::Object and Getopt::ObjectSimple provide command line parsing 
in true object format adding additional features to Getopt::Long this
author finds useful. Getopt::ObjectSimple provides a minimalist
approach with Getopt::Object providing the most features for
larger applications where more complex, ane obscure, features have proved useful. 

* Maintenance of code capturing options tends to be much easier.
* Mandatory options: options can be marked as mandatory. Constructor fails if such options are not sufficiently defined.
* Once the main object has been created subsequent code can request singleton objects to obtain access to all arguments. 
   * The main start code no longer needs to publish options to other parts of the program.
* Each option is defined as it's own self-contained object. 
   * All option aliases, short or long, are given in one string in the constructor call.
   * No more parallel updates of options of old ([1] once in a getopt call, and [2] once again in on in *given/switch* type test).
   * Any module compiled ("use"d) before the main Getopt::Object object is created may define it's own options without any need for extra code in the main call.

## Random-BestTiny
High quality random numbers for low volume use. 
Module uses native perl with a small code footprint.

Supports most POSIX/UNIX/Linux systems (anything with /dev/u?random devices) as well as currently supported Windows sytems.


## Sys-Spec
This package provides a program, and supporting class, that 
provide details of frequently used characteristics of the
local host to developers analyzing execution, working build 
environments, or maintaining build numbers.

  sys-spec  shell script to create build numbers and related information.

  Sys::Spec supporting class for build_num.


# Interesting Resources About CPAN

* http://www.cpan.org/modules/04pause.html
  * perl -MExtUtils::MakeMaker -le 'print MM->parse_version(shift)' 'file'
* http://search.cpan.org/~dagolden/CPAN-Meta-2.150005/lib/CPAN/Meta/Spec.pm 
* http://neilb.org/2015/10/18/spotters-guide.html
* http://modernperlbooks.com/mt/2009/07/version-confusion.html
* http://stackoverflow.com/questions/1454202/how-can-i-automatically-update-perl-modules-version-with-git
* http://www.perl.com/pub/2005/04/14/cpan_guidelines.html
