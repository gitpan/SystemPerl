// $Id: ex_main.cpp,v 1.4 2001/04/03 17:08:07 wsnyder Exp $
// DESCRIPTION: SystemPerl: Example main()

#include <systemperl.h>
#include "ex_bench.h"

int sc_main (int argc, char *argv[])
{
    ex_bench *bench;

    sc_clock clk("clk",10);

    SP_CELL (bench,ex_bench);
    SP_PIN  (bench,clk,clk);

    sc_trace_file *tf = sc_create_vcd_trace_file("sim" );
    // Should need, but sysC bug breaks:
    //((vcd_trace_file *)tf)->sc_set_vcd_time_unit(-9);
	
    sc_trace(tf, clk, "clk");
    sc_trace(tf, bench->in, "in");
    sc_trace(tf, bench->out, "out");
	
    cout << "Starting\n";
    sc_start(-1);
    cout << "Done\n";

    sc_close_vcd_trace_file(tf);
    return (0);
}
