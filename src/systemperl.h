// $Revision: #26 $$Date: 2003/09/22 $$Author: wsnyder $ -*- SystemC -*-
//********************************************************************
//
// THIS MODULE IS PUBLICLY LICENSED
//
// Copyright 2001-2003 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// General Public License or the Perl Artistic License.
//
// This is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
//********************************************************************
// DESCRIPTION: SystemPerl: Overall header file
//********************************************************************

#ifndef _SYSTEMPERL_H_
#define _SYSTEMPERL_H_

/* Necessary includes */
#include <sstream>	// For AUTOENUM
using namespace std;
#ifdef SYSTEMC_LESSER
# include <systemc_lesser.h>
#else
# include <systemc.h>
#endif
#include <stdint.h>      // uint32_t
#include <stdarg.h>      // ... vaargs

//********************************************************************
// Macros

// Like SC_MODULE but not managed as a module (for coverage, etc)
#define SP_CLASS(name) class name

// Allows constructor to be in implementation rather then the header
#define SP_CTOR_IMP(name) name::name(sc_module_name)

// Declaration of cell for interface
#define SP_CELL_DECL(type,instname) type *instname

// Instantiation of a cell in CTOR
#define SP_CELL(instname,type) (instname = new type (# instname))

// Instantiation of a cell in CTOR
// Allocate using a formatted name
#define SP_CELL_FORM(instname,type,format...) \
	(instname = new type (sp_cell_sprintf(format)))

// Connection of a pin to a SC_CELL
#define SP_PIN(instname,port,net) (instname->port(net))

// Tracing types
#define SP_TRACED	// Just a NOP; it simply marks a declaration
#ifndef VL_SIG
# define VL_SIG8(name, msb,lsb)		uint8_t  name
# define VL_SIG(name, msb,lsb)		uint32_t name
# define VL_SIGW(name, msb,lsb, words)	uint32_t name[words]
# define VL_IN8(name, msb,lsb)		uint8_t  name
# define VL_IN(name, msb,lsb)		uint32_t name
# define VL_INW(name, msb,lsb, words)	uint32_t name[words]
# define VL_INOUT8(name, msb,lsb)	uint8_t  name
# define VL_INOUT(name, msb,lsb)	uint32_t name
# define VL_INOUTW(name, msb,lsb, words) uint32_t name[words]
# define VL_OUT8(name, msb,lsb)		uint8_t  name
# define VL_OUT(name, msb,lsb)		uint32_t name
# define VL_OUTW(name, msb,lsb, words)	uint32_t name[words]
# define VL_PORT(name, msb,lsb)		uint32_t name		// Depreciated
# define VL_PORTW(name, msb,lsb, words)	uint32_t name[words]	// Depreciated
# define VL_PIN_NOP(instname,pin,port)
#endif

//********************************************************************
// Functions
// We'll ask systemC to have a sc_string creator to avoid this:
// Note there is a mem leak here.  As only used for instance names, we'll live.
inline const char *sp_cell_sprintf(const char *fmt...) {
    char* buf = new char[strlen(fmt) + 20];
    va_list ap; va_start(ap,fmt); vsprintf(buf,fmt,ap); va_end(ap);
    return(buf);
}

//********************************************************************
// Classes so we can sometimes avoid header inclusion

class SpTraceFile;
class SpTraceVcd;

//********************************************************************
// Simple classes.  If get bigger, move to optional include

class UInt32Zeroed { public:
    uint32_t m_l; 
    UInt32Zeroed(): m_l(0) {};
    inline operator const uint32_t () const { return m_l; };
};

//********************************************************************
// sp_log.h has whole thing... This one function may be used everywhere

#ifndef UTIL_ATTR_PRINTF
# ifdef __GNUC__
#  define UTIL_ATTR_PRINTF(fmtArgNum) __attribute__ ((format (printf, fmtArgNum, fmtArgNum+1)))
# else
#  define UTIL_ATTR_PRINTF(fmtArgNum) 
# endif
#endif

extern "C" {
    // Print to cout, but with C style arguments
    extern void sp_log_printf(const char *format, ...) UTIL_ATTR_PRINTF(1);
}

//********************************************************************
// SystemC Automatics

#define SP_AUTO_CTOR

// Multiple flavors as all compilers don't support variable define arguments
#define SP_AUTO_COVER()
#define SP_AUTO_COVER1(cmt)
#define SP_AUTO_COVER3(cmt,file,line)
#define SP_AUTO_COVER1_4(id,cmt,file,line) {this->_sp_coverage[(id)].m_l++;}
#define SP_AUTO_COVER4(id,cmt,file,line) {this->_sp_coverage[(id)].m_l++;}

//********************************************************************

#endif /*_SYSTEMPERL_H_*/
