// $Revision: #13 $$Date: 2002/08/29 $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example main()

#sp interface

#include <systemperl.h>
#sp use  "ExEnum.h"
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {
    static const int ARRAYSIZE = 3;

    sc_in_clk clk;

  private:
    sc_signal<bool> in;
    sc_signal<bool> out;
    sc_signal<uint32_t> out_array[ARRAYSIZE];
    sc_signal<sc_bv<55> > m_bv55;

    // These types declare a signal and also mark it for tracing.
    SP_TRACED uint32_t  m_cyclenum;
    SP_TRACED uint32_t  m_array[ARRAYSIZE];
    VL_SIG(m_unusedok1,  5,1);		// From Verilator: reg [5:1]  m_unusedok1
    VL_SIGW(m_unusedok2, 35,1,2);	// From Verilator: reg [35:1] m_unusedok2
    VL_SIGW(m_unusedok3[10], 35,1,2);	// From Verilator: reg [35:1] m_unusedok3[10]

    /*AUTOSUBCELL_DECL*/
    /*AUTOSIGNAL*/
    void clock();

  public:
    /*AUTOMETHODS*/
    void configure();
};
/*AUTOINTERFACE*/

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__)
{
    SC_METHOD(clock);
    sensitive_pos(clk);
    
    SP_CELL (mod,ExMod);
     SP_PIN (mod,in,in);
     SP_PIN (mod,out,out);
     SP_PIN (mod,clk,clk);

    SP_CELL (parse,ExParse);
     SP_PIN (parse,clk,clk);
     SP_PIN (parse,inhLowerPin,in);
     SP_PIN (parse,inhModulePin,in);
     SP_PIN (parse,inhModule2Pin,in);

    m_cyclenum = 0;

    //m_bv55 = "101_1100_1011_1010_1001_1000__0111_0110_0101_0100__0011_0010_0001_0000";
    m_bv55 = "1011100101110101001100001110110010101000011001000010000";

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
