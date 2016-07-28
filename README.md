# CPAN
Perl packages in the style of CPAN, perhaps on CPAN

##Getopt-Object
Getopt::Object and Getopt::ObjectSimple provide command line parsing 
in true object format with additional features to Getopt::Long this
author finds useful. Getopt::ObjectSimple provides a minimalist
approach with Getopt::Object providing the most features and 
focuses on larger applications where more complex options are useful. 

* Mandatory options: options can be marked as mandatory. The object will fail if such are not suffciently defined.
* Once the main object has been created subsequent code can request singleton objects to obtain access to all arguments. 
   * The main start code no longer needs to publish options to other parts of the program.
* Each option is defined as it's own self-contained object. 
   * No more parallel updates of options: one in a getopt call in on in *given/switch*.
   * All option aliases, short or long, are included in the "new" request.
   * Any module compiled before the main Getopt::Object object is created may define it's own options. 

## Random-BestTiny
High quality random numbers for low volume use and small, native perl, footprint.

