// $Id: ExModNull.sp 4305 2005-08-02 13:21:57Z wsnyder $
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
    SP_AUTO_CTOR;

#ifdef NEVER
    out.write(0);
#endif
}

/*AUTOTRACE(__MODULE__)*/
