// $Revision: 1.11 $$Date: 2005-03-16 14:04:22 -0500 (Wed, 16 Mar 2005) $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example "null" module
//
// Copyright 2001-2005 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.

#sp interface
#include <systemperl.h>
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {

    // Pull all I/Os from ExMod
    /*AUTOINOUT_MODULE(ExMod)*/

  private:
    /*AUTOSUBCELL_DECL*/
    /*AUTOSIGNAL*/

  public:
    /*AUTOMETHODS*/
};

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__) /*AUTOCTOR*/
{
#ifdef NEVER
    out.write(0);
#endif
}

/*AUTOTRACE(__MODULE__)*/
