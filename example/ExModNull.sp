// $Revision: #8 $$Date: 2002/07/16 $$Author: wsnyder $
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
