// $Id: ex_mod_sub.sp,v 1.2 2001/05/07 15:40:18 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example source module

#sp interface
SC_MODULE (__MODULE__) {
    sc_in_clk		clk;		  // **** System Inputs
    sc_in<bool>		in;
    sc_out<bool>	out;

    /*AUTODECLS*/

    void clock (void);

    SC_CTOR(__MODULE__);
};

#sp implementation
SP_CTOR_IMP(__MODULE__)
{
    SC_METHOD(clock);
    sensitive_pos << clk;
}

void __MODULE__::clock (void) {
    out.write(in.read());
}

/*AUTOTRACE(__MODULE__)*/
