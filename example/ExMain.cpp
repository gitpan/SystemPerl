// $Id: ExMain.cpp,v 1.3 2001/09/26 14:51:01 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example main()

#include <systemperl.h>
#include "ExEnum.h"
#include "ExBench.h"
#include "SpTraceVcd.h"

int sc_main (int argc, char *argv[])
{
    sc_clock clk("clk",10);

    ExBench* bench;
    SP_CELL (bench,ExBench);
    SP_PIN  (bench,clk,clk);
    bench->configure();	// Verify the #sp include worked

    sc_initialize();

    // Example enumeration usage
    MyENumClass enval = MyENumClass::ONE;
    cout << "enval = "<<enval<<endl;	// Prints "ONE"

    // SystemC traces are flawed, you can't even trace ports
    sc_trace_file *tf = sc_create_vcd_trace_file("sim_sc" );
    sc_trace(tf, clk, "clk");

    // SystemPerl traces
    SpTraceFile* stp = new SpTraceFile;
    bench->trace(stp,999);
    stp->open("sim_sp.vcd");

    cout << "Starting\n";
    sc_start(-1);
    cout << "Done\n";

    sc_close_vcd_trace_file(tf);
    return (0);
}
