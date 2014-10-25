// $Id: ExMain.cpp 49154 2008-01-02 14:22:02Z wsnyder $
// DESCRIPTION: SystemPerl: Example main()
//
// Copyright 2001-2008 by Wilson Snyder.  This program is free software;
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

    cout << "SYSTEMC_VERSION="<<dec<<SYSTEMC_VERSION<<endl;

    // Timescale
#if (SYSTEMC_VERSION>20011000)
    sc_set_time_resolution(100.0, SC_FS);
    sc_set_default_time_unit(1.0, SC_NS);
    sc_report::make_warnings_errors(true);
#else
    sc_time dut(1.0, sc_ns);
    sc_set_default_time_unit(dut);
#endif

#ifndef NC_SYSTEMC
    // Simulation logfile
    sp_log_file splog;
    splog.open ("sim.log");
    splog.redirect_cout();
#endif

    // Pins
#if SYSTEMC_VERSION >= 20060505
    sc_clock clk("clk",5,SC_NS);  // We want a non-integer half period to prove VCD works
#else
    sc_clock clk("clk",5);
#endif

    ExBench* bench;
    SP_CELL (bench,ExBench);
    SP_PIN  (bench,clk,clk);
    bench->configure();	// Verify the #sp include worked

#ifndef NC_SYSTEMC
# if SYSTEMC_VERSION < 20060505
    sc_initialize();
# endif
#endif

    // Example enumeration usage
    MyENumClass enval = MyENumClass::ONE;
    cout << "Assigned to enumeration = "<<enval<<endl;	// Prints "ONE"
    cout << "Iterating an enumeration =";
    for (MyENumSimple::iterator it=MyENumSimple::begin();
	 it!=MyENumSimple::end(); ++it) {
	cout << " " << (*it).ascii();
    }
    cout << endl;

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
#if SYSTEMC_VERSION >= 20060505
    sc_start();
#else
    sc_start(-1);
#endif
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
