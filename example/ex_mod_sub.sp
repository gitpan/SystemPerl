// $Id: ex_mod_sub.sp,v 1.3 2001/06/21 21:10:02 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example source module

#sp interface
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {
    sc_in_clk		clk;		  // **** System Inputs
    sc_in<bool>		in;
    sc_out<bool>	out;

    /*AUTOSUBCELLS*/
    /*AUTODECLS*/
    /*AUTOSIGNAL*/

    void clock (void);

    SC_CTOR(__MODULE__);
};

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
