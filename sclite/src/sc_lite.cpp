// $Id: sc_lite.cpp,v 1.3 2001/11/14 03:57:10 wsnyder Exp $
//********************************************************************
//
// This program is Copyright 2001 by Wilson Snyder.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of either the GNU General Public License or the
// Perl Artistic License, with the exception that it cannot be placed
// on a CD-ROM or similar media for commercial distribution without the
// prior approval of the author.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// If you do not have a copy of the GNU General Public License write to
// the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,
// MA 02139, USA.
//
//********************************************************************
// DESCRIPTION: SystemPerl: SystemC-like library with only most-trivial functions.
//	This allows for testing of this package without the real SC library.
//********************************************************************

#include <deque>
#include "sc_lite.h"

// extern's declared
double scl_time_stamp = 0;
//sc_method_t sc_method_being_sensitized = NULL;

//********************************************************************
typedef deque<sc_clock*>	SclClkList;
SclClkList	scl_clk_list;
typedef deque<sc_trace_file*>	SclTfList;
SclTfList	scl_tf_list;

class SclContext {
private:
    static void step();
    
public:
    static void start(double time);
};
void sc_start (double time) { SclContext::start(time); }

//********************************************************************
// Setup

void sc_simcontext::add_trace_file (sc_trace_file* tf) {
    scl_tf_list.push_back(tf);
}

sc_clock::sc_clock(const char* name, double period) {
    m_period=period; m_high=false; m_next_edge = period/2;
    scl_clk_list.push_back(this);
}

void scl_add_method (SclFunctor cbp) {
    cout<<"Add method "<<endl;
}

//********************************************************************
// Initialization

int main(int argc, char* argv[]) {
    sc_main(argc,argv);
}

void sc_initialize() {
    cout << "SystemC-Lite\n";
}

//********************************************************************
// Running

void SclContext::start (double for_time) {
    // If for_time==-1, execute forever
    cout << "sc_start("<<for_time<<")\n";
    if (for_time!=-1) for_time += scl_time_stamp;
    while (1) {
	// Find next clock
	double next_edge = scl_time_stamp;
	for (SclClkList::iterator iter=scl_clk_list.begin();
	     iter!=scl_clk_list.end(); ++iter) {
	    sc_clock* scp = *iter;
	    if (scp->m_next_edge < next_edge) {
		next_edge = scp->m_next_edge;
	    }
	}
	if (next_edge <= scl_time_stamp) {
	    cerr << "%Error: Clock has a period of 0\n";
	    abort();
	}

	// Done?
	if (for_time!=-1 && (next_edge > for_time)) {
	    scl_time_stamp = for_time;
	    break;
	}

	// Advance simulation to next edge
	scl_time_stamp = next_edge;
	step();
    }
}

void SclContext::step () {
    // Simulate one time delta

    // Clock changes
    for (SclClkList::iterator iter=scl_clk_list.begin();
	 iter!=scl_clk_list.end(); ++iter) {
	sc_clock* scp = *iter;
	if (scp->m_next_edge == scl_time_stamp) {
	    scp->toggle();
	    cerr << "["<<sc_time_stamp()<<"]  Toggling clk\n";
	}
    }

    // Invoke clock methods
    //FIX
    // Invoke all other methods
    //FIX
    // Copy new values to old values
    //FIX

    // Trace variables
    for (SclTfList::iterator iter=scl_tf_list.begin();
	 iter!=scl_tf_list.end(); ++iter) {
	sc_trace_file* tf = *iter;
	tf->cycle(true);
    }
}

