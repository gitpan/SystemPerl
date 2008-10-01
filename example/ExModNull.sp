// $Id: ExModNull.sp 60993 2008-09-17 16:58:23Z wsnyder $
// DESCRIPTION: SystemPerl: Example "null" module
//
// Copyright 2001-2008 by Wilson Snyder.  This program is free software;
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
#sp slow
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__) /*AUTOINIT*/ {
    SP_AUTO_CTOR;

#ifdef NEVER
    out.write(0);
    /*AUTOTIEOFF*/
#endif
}

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

/*AUTOTRACE(__MODULE__)*/
