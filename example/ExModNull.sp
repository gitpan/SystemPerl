// $Id: ExModNull.sp,v 1.7 2001/11/27 13:56:52 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example "null" module

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

SP_CTOR_IMP(__MODULE__)
{
#ifdef NEVER
    out.write(0);
#endif
}

/*AUTOTRACE(__MODULE__)*/
