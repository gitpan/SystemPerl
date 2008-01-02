// $Id: ExModNull.sp 49154 2008-01-02 14:22:02Z wsnyder $
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
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__) /*AUTOINIT*/ {
    SP_AUTO_CTOR;

#ifdef NEVER
    out.write(0);
    /*AUTOTIEOFF*/
#endif
}

/*AUTOTRACE(__MODULE__)*/
