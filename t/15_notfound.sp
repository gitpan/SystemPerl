// $Id: 15_notfound.sp 4305 2005-08-02 13:21:57Z wsnyder $
// DESCRIPTION: SystemPerl: Example source module
//
// Copyright 2001-2005 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.

#sp interface
#include <systemperl.h>
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {
  private:
    /*AUTOSUBCELL_DECL*/
    /*AUTOSIGNAL*/
  public:
    /*AUTOMETHODS*/
};

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__) {
    SP_CELL (missingcell, NotFoundSub);
}
