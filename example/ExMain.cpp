// $Revision: 1.17 $$Date: 2005-03-11 16:38:41 -0500 (Fri, 11 Mar 2005) $$Author: wsnyder $
// DESCRIPTION: SystemPerl: Example main()
//
// Copyright 2001-2005 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.

#include <sys/stat.h>
#include <sys/types.h>

#include <systemperl.h>
#include "ExBench.h"

#ifndef NC_SYSTEMC
# include "sp_log.h"
# include "SpTraceVcd.h"
#endif
#include "SpCoverage.h"

int sc_main (int argc, char *argv[]) {

#ifndef NC_SYSTEMC
    // Simulation logfile
    sp_log_file splog;
    splog.open ("sim.log");
    splog.redirect_cout();
#endif

    // Pins
    sc_clock clk("clk",10);

    ExBench* bench;
    SP_CELL (bench,ExBench);
    SP_PIN  (bench,clk,clk);
    bench->configure();	// Verify the #sp include worked

#ifndef NC_SYSTEMC
    sc_initialize();
#endif

    // Example enumeration usage
    MyENumClass enval = MyENumClass::ONE;
    cout << "enval = "<<enval<<endl;	// Prints "ONE"

#ifndef NC_SYSTEMC
    // SystemC traces are flawed, you can't even trace ports
    sc_trace_file *tf = sc_create_vcd_trace_file("sim_sc" );
# ifndef _SC_LITE_
    sc_trace(tf, clk, "clk");
# endif

    // SystemPerl traces
    SpTraceFile* stp = new SpTraceFile;
    bench->trace(stp,999);
    stp->open("sim_sp.vcd");

    // Alternative SystemPerl traces, allowing rollover
    // After running, concat the two files to make the vcd file.
    SpTraceFile* stp2 = new SpTraceFile;
    stp2->rolloverMB(1);	// Rollover logfiles when size > 1MB
    bench->trace(stp2,999);
    stp2->open("sim_sp2.vcd");
#endif

    cout << "Starting\n";
    sc_start(-1);
    cout << "Done\n";

#ifndef NC_SYSTEMC
    sc_close_vcd_trace_file(tf);
    SpTraceVcd::flush_all();
#endif

    // Coverage
    mkdir("logs", 0777);
    SpCoverage::write();  // Writes logs/coverage.pl

    return (0);
}
