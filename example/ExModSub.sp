// $Revision: #7 $$Date: 2002/07/16 $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example source module

#sp interface
#include <systemperl.h>
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {
    sc_in_clk		clk;		  // **** System Inputs
    sc_in<bool>		in;
    sc_out<bool>	out;

  private:
    /*AUTOSUBCELL_DECL*/
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
    sensitive_pos(clk);
}

void __MODULE__::clock (void) {
    SP_AUTO_COVER("clocking");
    out.write(in.read());
}

/*AUTOTRACE(__MODULE__)*/
