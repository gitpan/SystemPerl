// $Id: SpTraceVcd.h 4305 2005-08-02 13:21:57Z wsnyder $ -*- SystemC -*-
//=============================================================================
//
// THIS MODULE IS PUBLICLY LICENSED
//
// Copyright 2001-2005 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.
//
// This is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
//=============================================================================
///
/// \file
/// \brief SystemPerl tracing in VCD format
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================

#ifndef _SPTRACEVCD_H_
#define _SPTRACEVCD_H_ 1

#include "SpTraceVcdC.h"

#include "systemperl.h"

//=============================================================================
// SpTraceFile
///  SystemPerl VCD Trace class
////
/// This class is passed to the SystemC simulation kernel, just like a
/// documented SystemC trace format.

class SpTraceFile
    : sc_trace_file
    , public SpTraceVcdCFile
{
public:
    SpTraceFile() {
	sc_get_curr_simcontext()->add_trace_file(this);
# if (SYSTEMC_VERSION>20011000)
	spTrace()->set_time_resolution(sc_get_time_resolution().to_string());
	spTrace()->set_time_unit(sc_get_default_time_unit().to_string());
# endif
    }
    ~SpTraceFile() {}
    /// Called by SystemC simulate()
    virtual void cycle (bool delta_cycle) {
# if (SYSTEMC_VERSION>20011000)
	// VCD files must have integer timestamps, so we write all times in increments of time_resolution
	if (!delta_cycle) { spTrace()->dump(sc_time_stamp().to_double() / sc_get_time_resolution().to_double()); }
# else
	if (!delta_cycle) { spTrace()->dump(sc_time_stamp()); }
# endif
    }

private:
    /// Fake outs for linker
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
#ifdef SYSTEMC_64BIT_PATCHES
    DECL_TRACE_METHOD_B( unsigned long long)
#endif
#if (SYSTEMC_VERSION>20041000)
    DECL_TRACE_METHOD_B( unsigned long long)
    DECL_TRACE_METHOD_B( long long)
#endif
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
