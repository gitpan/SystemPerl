// $Id: ex_bench.sp,v 1.3 2001/05/07 15:40:18 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example main()

#sp interface

#include <systemperl.h>
#include "ex_mod.h"

SC_MODULE (__MODULE__) {

    sc_in_clk clk;

    sc_signal<bool> in;
    sc_signal<bool> out;

    /*AUTOSUBCELLS*/
    /*AUTODECLS*/

    void clock (void);

    SC_CTOR(__MODULE__);
};

#sp implementation
SP_CTOR_IMP(__MODULE__)
{
    SC_METHOD(clock);
    sensitive_pos << clk;
    
    SP_CELL (mod,ex_mod);
    SP_PIN (mod,in,in);
    SP_PIN (mod,out,out);
    SP_PIN (mod,clk,clk);
}

void __MODULE__::clock (void) {
    static int cyclenum = 0;
    static int next_toggle_cycle = 0;
    // Trivial toggling for now

    cout << "[" << sc_time_stamp() << "] Clock\n";

    if (cyclenum==0) {
	in = 0;
    } else if (cyclenum>=70) {
	sc_stop();
    } else if (cyclenum>=next_toggle_cycle) {
	in = !in;
	next_toggle_cycle <<= 1;
    }
    cyclenum++;
}

/*AUTOTRACE(__MODULE__)*/
