// $Revision: 1.30 $$Date: 2005-03-01 17:59:56 -0500 (Tue, 01 Mar 2005) $$Author: wsnyder $ -*- SystemC -*-
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
/// \brief SystemPerl Tracing in VCD Format
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================

#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>

#include <systemperl.h>

#include "SpTraceVcd.h"

//======================================================================
//======================================================================

void SpTraceFile::write_comment (const sc_string &) {}
void SpTraceFile::trace (const unsigned int &, const sc_string &, const char **) {}

#define DECL_TRACE_METHOD_A(tp) \
    void SpTraceFile::trace( const tp& object, const sc_string& name ) {}
#define DECL_TRACE_METHOD_B(tp) \
    void SpTraceFile::trace( const tp& object, const sc_string& name, int width ) {}

#if (SYSTEMC_VERSION>20011000)
    // SystemC 2.0.1
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
#else
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
# ifndef _SC_LITE_
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
# endif
#endif

#undef DECL_TRACE_METHOD_A
#undef DECL_TRACE_METHOD_B

//********************************************************************
