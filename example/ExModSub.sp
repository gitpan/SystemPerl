// $Id: ExModSub.sp,v 1.3 2001/10/05 15:46:41 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example source module

#sp interface
#include <systemperl.h>
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {
    sc_in_clk		clk;		  // **** System Inputs
    sc_in<bool>		in;
    sc_out<bool>	out;

  private:
    /*AUTOSUBCELLS*/
    /*AUTOSIGNAL*/
    void clock (void);

  public:
    /*AUTOMETHODS*/
};

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__)
{
    SC_METHOD(clock);
    sensitive_pos << clk;
}

void __MODULE__::clock (void) {
    out.write(in.read());
}

/*AUTOTRACE(__MODULE__)*/
