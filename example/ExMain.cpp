// $Revision: #10 $$Date: 2002/07/16 $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example main()

#include <systemperl.h>
#include "ExBench.h"
#include "SpTraceVcd.h"

void sp_coverage_data (const char *hier, const char *what, const char *file, int lineno, uint32_t data) {
    // Needed if any SP_COVERAGE statements in the model
}

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
#ifndef _SC_LITE_
    sc_trace(tf, clk, "clk");
#endif

    // SystemPerl traces
    SpTraceFile* stp = new SpTraceFile;
    bench->trace(stp,999);
    stp->open("sim_sp.dump");

    // Alternative SystemPerl traces, allowing rollover
    // After running, concat the two files to make the vcd file.
    SpTraceFile* stp2 = new SpTraceFile;
    stp2->rolloverMB(1);	// Rollover logfiles when size > 1MB
    bench->trace(stp2,999);
    stp2->open("sim_sp2.dump");

    cout << "Starting\n";
    sc_start(-1);
    cout << "Done\n";

    sc_close_vcd_trace_file(tf);
    return (0);
}
