// $Id: ExModNull.sp,v 1.5 2001/10/05 15:46:41 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example "null" module

#sp interface
#include <systemperl.h>
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {

    // Pull all I/Os from ExMod
    /*AUTOINOUT_MODULE(ExMod)*/

  private:
    /*AUTOSUBCELLS*/
    /*AUTOSIGNAL*/

  public:
    /*AUTOMETHODS*/
};

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__)
{
}

/*AUTOTRACE(__MODULE__)*/
