// $Revision: #16 $$Date: 2004/07/19 $$Author: ws150726 $
// DESCRIPTION: SystemPerl: Example main()
//
// Copyright 2001-2004 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.

#include <sys/stat.h>
#include <sys/types.h>

#include <systemperl.h>
#include "sp_log.h"
#include "ExBench.h"
#include "SpTraceVcd.h"
#include "SpCoverage.h"

int sc_main (int argc, char *argv[]) {
    // Simulation logfile
    sp_log_file splog;
    splog.open ("sim.log");
    splog.redirect_cout();

    // Pins
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
    SpTraceVcd::flush_all();

    // Coverage
    mkdir("logs", 0777);
    SpCoverage::write();  // Writes logs/coverage.pl

    return (0);
}
