// $Revision: #29 $$Date: 2004/06/21 $$Author: ws150726 $ -*- SystemC -*-
//=============================================================================
//
// THIS MODULE IS PUBLICLY LICENSED
//
// Copyright 2001-2004 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.
//
// This is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
//=============================================================================
//
// AUTHOR:  Wilson Snyder
//
// DESCRIPTION: SystemC support for tracing SpTraceVcd format
//
//=============================================================================

#ifndef _VLTRACEVCD_H_
#define _VLTRACEVCD_H_ 1

#include "SpTraceVcdC.h"

#include "systemperl.h"

//=============================================================================
// SpTraceFile
// This class is passed to the SystemC simulation kernal to make it look like
// a sc_trace_file

class SpTraceFile
    : sc_trace_file
    , public SpTraceVcdCFile
{
public:
    SpTraceFile() {
	sc_get_curr_simcontext()->add_trace_file(this);
    }
    ~SpTraceFile() {}
    // Called by SystemC simulate()
# if (SYSTEMC_VERSION>20011000)
    virtual void cycle (bool) { spTrace()->dump(sc_time_stamp().to_double()); }
# else
    virtual void cycle (bool) { spTrace()->dump(sc_time_stamp()); }
# endif

private:
    // Fake outs for linker
    virtual void write_comment (const sc_string &);
    virtual void trace (const unsigned int &, const sc_string &, const char **);

# define DECL_TRACE_METHOD_A(tp) \
    virtual void trace( const tp& object, const sc_string& name );
# define DECL_TRACE_METHOD_B(tp) \
    virtual void trace( const tp& object, const sc_string& name, int width );

# if (SYSTEMC_VERSION>20011000)
    // SystemC 2.0.1
    virtual void delta_cycles (bool) {}
    virtual void space( int n ) {}
    
    DECL_TRACE_METHOD_A( bool )
    DECL_TRACE_METHOD_A( sc_bit )
    DECL_TRACE_METHOD_A( sc_logic )
    DECL_TRACE_METHOD_B( unsigned char )
    DECL_TRACE_METHOD_B( unsigned short )
    DECL_TRACE_METHOD_B( unsigned int )
    DECL_TRACE_METHOD_B( unsigned long )
    DECL_TRACE_METHOD_B( char )
    DECL_TRACE_METHOD_B( short )
    DECL_TRACE_METHOD_B( int )
    DECL_TRACE_METHOD_B( long )
    DECL_TRACE_METHOD_A( float )
    DECL_TRACE_METHOD_A( double )
    DECL_TRACE_METHOD_A( sc_int_base )
    DECL_TRACE_METHOD_A( sc_uint_base )
    DECL_TRACE_METHOD_A( sc_signed )
    DECL_TRACE_METHOD_A( sc_unsigned )
    DECL_TRACE_METHOD_A( sc_fxval )
    DECL_TRACE_METHOD_A( sc_fxval_fast )
    DECL_TRACE_METHOD_A( sc_fxnum )
    DECL_TRACE_METHOD_A( sc_fxnum_fast )
    DECL_TRACE_METHOD_A( sc_bv_base )
    DECL_TRACE_METHOD_A( sc_lv_base )

# else

    // SystemC 1.2.1beta
    DECL_TRACE_METHOD_A( bool )
    DECL_TRACE_METHOD_B( unsigned char )
    DECL_TRACE_METHOD_B( short unsigned int )
    DECL_TRACE_METHOD_B( unsigned int )
    DECL_TRACE_METHOD_B( long unsigned int )
    DECL_TRACE_METHOD_B( char )
    DECL_TRACE_METHOD_B( short int )
    DECL_TRACE_METHOD_B( int )
    DECL_TRACE_METHOD_B( long int )
    DECL_TRACE_METHOD_A( float )
    DECL_TRACE_METHOD_A( double )
#  ifndef _SC_LITE_
    DECL_TRACE_METHOD_A( sc_bit )
    DECL_TRACE_METHOD_A( sc_logic )
    DECL_TRACE_METHOD_A( sc_bool_vector )
    DECL_TRACE_METHOD_A( sc_logic_vector )
    DECL_TRACE_METHOD_A( sc_signal_bool_vector )
    DECL_TRACE_METHOD_A( sc_signal_logic_vector )
    DECL_TRACE_METHOD_A( sc_uint_base )
    DECL_TRACE_METHOD_A( sc_int_base )
    DECL_TRACE_METHOD_A( sc_unsigned )
    DECL_TRACE_METHOD_A( sc_signed )
    DECL_TRACE_METHOD_A( sc_signal_resolved )
    DECL_TRACE_METHOD_A( sc_signal_resolved_vector )
    DECL_TRACE_METHOD_A( sc_bv_ns::sc_bv_base )
    DECL_TRACE_METHOD_A( sc_bv_ns::sc_lv_base )
#  endif
# endif

# undef DECL_TRACE_METHOD_A
# undef DECL_TRACE_METHOD_B
};

#endif // guard
