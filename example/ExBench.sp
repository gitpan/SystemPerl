// $Id: ExBench.sp,v 1.4 2001/09/26 14:51:01 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example main()

#sp interface

#include <systemperl.h>
#include "ExMod.h"
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {
    static const int ARRAYSIZE = 3;

    sc_in_clk clk;

    sc_signal<bool> in;
    sc_signal<bool> out;
    sc_signal<uint32_t> out_array[ARRAYSIZE];

    // These types declare a signal and also mark it for tracing.
    SP_TRACED uint32_t m_cyclenum;
    SP_TRACED uint32_t m_array[ARRAYSIZE];
    VL_SIG(m_unusedok1,  5,1);		// From Verilator: reg [5:1]  m_unusedok1
    VL_SIGW(m_unusedok2, 35,1,2);	// From Verilator: reg [35:1] m_unusedok2
    VL_SIGW(m_unusedok3[10], 35,1,2);	// From Verilator: reg [35:1] m_unusedok3[10]

    /*AUTOSUBCELLS*/
    /*AUTOSIGNAL*/
    /*AUTOMETHODS*/

    void clock (void);
    void configure();
};
/*AUTOINTERFACE*/

#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__)
{
    SC_METHOD(clock);
    sensitive_pos << clk;
    
    SP_CELL (mod,ExMod);
    SP_PIN (mod,in,in);
    SP_PIN (mod,out,out);
    SP_PIN (mod,clk,clk);

    m_cyclenum = 0;

    for (int i=0; i<ARRAYSIZE; i++) m_array[i] = i;
}

void __MODULE__::clock (void) {
    static int next_toggle_cycle = 0;
    // Trivial toggling for now

    cout << "[" << sc_time_stamp() << "] Clock.. in="<<in<<"\n";

    if (m_cyclenum<2) {
	in = 0;
    } else if (m_cyclenum>=70) {
	sc_stop();
    } else if (m_cyclenum>=next_toggle_cycle) {
	in = !in;
	next_toggle_cycle <<= 1;
    }
    m_cyclenum++;
}

#sp include "ExInclude.spinc"

/*AUTOIMPLEMENTATION*/
/*AUTOTRACE(__MODULE__)*/
