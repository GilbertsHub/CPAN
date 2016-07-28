# CPAN
Perl packages in the style of CPAN, perhaps on CPAN

Status: reasonably complete for typical use

## Getopt-Object
Getopt::Object and Getopt::ObjectSimple provide command line parsing 
in true object format adding additional features to Getopt::Long this
author finds useful. Getopt::ObjectSimple provides a minimalist
approach with Getopt::Object providing the most features for
larger applications where more complex options can be very useful. 

* Maintenance tends to be a lot easier.
* Mandatory options: options can be marked as mandatory. Constructor fail if such options are not sufficiently defined.
* Once the main object has been created subsequent code can request singleton objects to obtain access to all arguments. 
   * The main start code no longer needs to publish options to other parts of the program.
* Each option is defined as it's own self-contained object. 
   * All option aliases, short or long, are given once in the constructor call.
   * No more parallel updates of options of old ([1] once in a getopt call, and [2] once again in on in *given/switch* type test).
   * Any module compiled ("use"d) before the main Getopt::Object object is created may define it's own options without any need for extra code in the main call.

## Random-BestTiny
High quality random numbers for low volume use. 
Module uses native perl with a a small code footprint.

Supports most POSIX/UNIX/Linux systems (anything with /dev/u?random devices) as well as currently supported Windows sytems.


