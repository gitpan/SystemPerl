// $Id: sc_lite.h 49154 2008-01-02 14:22:02Z wsnyder $ -*- C++ -*-
//********************************************************************
//
// Copyright 2001-2008 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
//********************************************************************
///
/// \file
/// \brief SystemPerl: SystemC-like library with only most-trivial functions.
///
/// AUTHOR:  Wilson Snyder
///
/// This allows for testing of this package without the real SC library.
/// It is NOT for any production use.
///
//********************************************************************

#ifndef _SC_LITE_H
#define _SC_LITE_H
#define _SC_LITE_

// Standard includes
#include <string.h>
#include <stdio.h>
#include <string>
#include <iostream>
using namespace std;

//=== Basic types
typedef string sc_string;
typedef sc_string sc_module_name;

//=== Globals
extern void sc_initialize();
extern void sc_start(double time);

inline double sc_time_stamp() { extern double scl_time_stamp; return scl_time_stamp; }
inline void sc_stop(void) { exit(0); }

//=== Tracing
struct sc_trace_file {
    virtual void cycle (bool) {};
};
inline sc_trace_file* sc_create_vcd_trace_file(const char*) {
    return new sc_trace_file();
}
inline void sc_close_vcd_trace_file(sc_trace_file*) {}

//=== Simulation info
struct sc_simcontext {
    void add_trace_file (sc_trace_file* tf);
};
inline sc_simcontext* sc_get_curr_simcontext() { return new sc_simcontext; }

//=== Defined by the user
extern int sc_main(int argc, char* argv[]);

//=== Bit vector class
// For our purposes, this can be just a container, fortunately no math is needed!
template <int T>
class sc_bv {
    const static int SIZE = T;
    unsigned long m_data[(SIZE+31)/32];
  public:
    unsigned long* get_datap() const { return m_data; }
    inline sc_bv<T>& operator= (const char* val) {return *this;};
};

//=== Clocks
class sc_clock {
    double	m_period;
  protected:
    friend class SclContext;
    bool	m_high;
    double	m_next_edge;
    void toggle() {m_high = !m_high; m_next_edge = sc_time_stamp() + m_period/2; }
  public:
    sc_clock() {m_period=0; m_next_edge=0;};	// For sc_signal()
    sc_clock(const char* name, double period);
    inline operator const bool& () const { return m_high; };
};

//=== Signals/in/outs, all declared identically
class SclSignalBase {};
template <class T>
 class sc_signal : SclSignalBase {
    T*	old_valuep;
    T*	new_valuep;
    T	old_value_r;
    T	new_value_r;
   public:
    sc_signal() : old_valuep(&old_value_r), new_valuep(&new_value_r) {};
    void operator () (T& val) {
	old_value_r = new_value_r = val;
    };
    void operator () (sc_signal<T>& net) {
	old_valuep = net.old_valuep;
	new_valuep = net.new_valuep;
    };
    template <class U>
	inline sc_signal<T>& operator= (const U& v) { *new_valuep = v; return *this; };
    template <class U>
	inline void write (const U& v) { *new_valuep = v; };
    inline T& read () const { return *new_valuep; }
    inline operator const T& () const { return *old_valuep; };
};
template <class T>
inline ostream& operator<< (ostream& lhs, const sc_signal<T>& rhs) { return lhs; }

#define sc_in sc_signal
#define sc_out sc_signal
#define sc_inout sc_signal
typedef sc_in<bool> sc_in_clk;

//=== Methods
class SclFunctor {
  public:
    virtual void call() {};
};
template <class T> class SclFunctorSpec : public SclFunctor {
    void (T::*m_cb)();	// Pointer to method function
    T*	m_obj;		// Module object to invoke on
  public:
    SclFunctorSpec(T* obj, void (T::*cb)()) : m_cb(cb), m_obj(obj) {}
    virtual void call() { (*m_obj.*m_cb)(); } 
};
//Usage:
//    SC_METHOD(clock);
//    sensitive_pos << clk;
#define SC_METHOD(func) scl_add_method(SclFunctorSpec<SC_CURRENT_USER_MODULE>(this,&SC_CURRENT_USER_MODULE::func))
extern void scl_add_method (SclFunctor ftr);

//=== Sensitivity
#define SCL_EDGE_POS    1
#define SCL_EDGE_NEG    2
#define SCL_EDGE_EITHER 3
#define sensitive(sig)       scl_add_sensitive(SCL_EDGE_EITHER,sig)
#define sensitive_pos(sig)   scl_add_sensitive(SCL_EDGE_POS,sig)
#define sensitive_neg(sig)   scl_add_sensitive(SCL_EDGE_NEG,sig)

//=== Modules
#define SC_MODULE(mod) struct mod : public sc_module
#define SC_CTOR(name)  typedef name SC_CURRENT_USER_MODULE; name(sc_module_name)
class sc_module {
    sc_string m_name;
  protected:
    template <class T>
	static void scl_add_sensitive(int direction, T);
  public:
    const char* name() const { return m_name.c_str(); }
    // FIX passing name from cell
    sc_module () : m_name("") {}
};

#endif // guard
