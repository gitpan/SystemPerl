// $Id: ex_mod_sub.sp,v 1.1 2001/04/03 14:49:35 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example source module

#sp interface
SC_MODULE (__MODULE__) {
    sc_in_clk		clk;		  // **** System Inputs
    sc_in<bool>		in;
    sc_out<bool>	out;

    void clock (void);

    SC_CTOR(__MODULE__) {
	SC_METHOD(clock);
	sensitive_pos << clk;
    };
};

#sp implementation
void __MODULE__::clock (void) {
    out.write(in.read());
}
