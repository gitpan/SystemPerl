// $Revision: #12 $$Date: 2002/11/03 $$Author: wsnyder $ -*- SystemC -*-
//=============================================================================
//
// THIS MODULE IS PUBLICLY LICENSED
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of either the GNU General Public License or the
// Perl Artistic License.
//
// This is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License
// along with this module; see the file COPYING.  If not, write to
// the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
// Boston, MA 02111-1307, USA.
//
//=============================================================================
//
// AUTHOR:  Wilson Snyder
//
// DESCRIPTION: Tracing in SpTraceVcd Format
//
//=============================================================================

#ifndef _VLTRACEVCD_H_
#define _VLTRACEVCD_H_ 1

#include <sys/types.h>	// uint32_t
#include <stdint.h>	// uint32_t
#include <iostream>
#include <fstream>
#include <string>
#include <algorithm>
#include <vector>
#ifndef SPTRACEVCD_TEST
# include <systemperl.h>
#endif

//=============================================================================
// SpTraceVcdSig

class SpTraceVcdSig {
protected:
    friend class SpTraceVcd;
    uint32_t		m_code;		// Code number
    const uint32_t*	m_valp;		// Pointer to where value comes from
    int			m_bits;		// Size of value
    SpTraceVcdSig (uint32_t code, const uint32_t* valp, int bits)
	: m_code(code), m_valp(valp), m_bits(bits) {}
};

//=============================================================================
// SpTraceVcdSig

typedef void (*SpTraceCallback_t)(SpTraceVcd* vcdp, void* userthis, uint32_t code);
class SpTraceCallInfo;

class SpTraceVcd {
private:
    bool 		m_isOpen;	// True indicates open file
    std::ofstream	m_fp;		// File we're writing to
    string		m_filename;	// Filename we're writing to (if open)
    size_t		m_rolloverMB;	// MB of file size to rollover at
    int			m_modDepth;	// Depth of module hiearchy
    bool		m_fullDump;	// True indicates dump ignoring if changed
    uint32_t		m_nextCode;	// Next code number to assign
    string		m_modName;	// Module name being traced now

    vector<SpTraceVcdSig>	m_sigs;		// Pointer to signal information
    vector<uint32_t>		m_sigs_oldval;	// Pointer to old signal values
    vector<SpTraceCallInfo*>	m_callbacks;	// Routines to perform dumping

    static const char* genId ();
    void openNext();
    void printIndent (int levelchange);
    void declare (uint32_t code, const char* name, int arraynum,
		  const uint32_t* valp,
		  int msb, int lsb, bool isBit);
    void dumpPrep (double timestamp);
    void dumpDone ();
    inline void printCode (uint32_t code) {
	if (code>=(94*94*94)) m_fp.put((char)((code/94/94/94)%94+33));
	if (code>=(94*94)) m_fp.put((char)((code/94/94)%94+33));
	if (code>=(94)) m_fp.put((char)((code/94)%94+33));
	m_fp.put((char)((code)%94+33));
    }

public:
    // CREATORS
    SpTraceVcd () : m_isOpen(false), m_rolloverMB(0), m_modDepth(0), m_nextCode(0) {}

    // ACCESSORS
    uint32_t nextCode() const {return m_nextCode;}
    void rolloverMB(size_t rolloverMB) { m_rolloverMB=rolloverMB; };

    // METHODS
    void open (const char* filename);	// Open the file
    void openNext (bool incFilename);	// Open next data-only file
    void close ();			// Close the file

    void addCallback (SpTraceCallback_t init, SpTraceCallback_t dump,
		      void* userthis);

    void init ();
    void definitions ();
    void module (const string name);
    void declBit   (uint32_t code, const char* name, int arraynum, const uint32_t* valp);
    void declBit   (uint32_t code, const char* name, int arraynum, const bool* valp);
    void declBus   (uint32_t code, const char* name, int arraynum, const uint32_t* valp, int msb, int lsb);
    void declArray (uint32_t code, const char* name, int arraynum, const uint32_t* valp, int msb, int lsb);
    //	... other module_start for submodules (based on cell name)
    void enddefinitions ();

    // Regular dumping
    void dump     (double timestamp);
    void dumpFull (double timestamp);

    // Quick dumping
    inline void dumpValueBit (uint32_t code, const uint32_t& newval) {
	m_sigs_oldval[code] = newval;
	m_fp.put(newval?'1':'0'); printCode(code); m_fp.put('\n');
    }
    inline void dumpValueBus (uint32_t code, const uint32_t& newval, int bits) {
	m_sigs_oldval[code] = newval;
	m_fp.put('b');
	for (int bit=bits-1; bit>=0; --bit) {
	    m_fp.put((newval&(1L<<bit))?'1':'0');
	}
	m_fp.put(' '); printCode(code); m_fp.put('\n');
    }
    inline void dumpValueArray (uint32_t code, const uint32_t* newval, int bits) {
	for (int word=0; word<((bits/32)+1); ++word) {
	    m_sigs_oldval[code+word] = newval[word];
	}
	m_fp.put('b');
	for (int bit=bits-1; bit>=0; --bit) {
	    m_fp.put((newval[(bit/32)]&(1L<<(bit&0x1f)))?'1':'0');
	}
	m_fp.put(' '); printCode(code); m_fp.put('\n');
    }

    inline void dumpBit (uint32_t code, const uint32_t& newval) {
	if (m_sigs_oldval[code] != newval) { dumpValueBit (code, newval); }
    }
    inline void dumpBus (uint32_t code, const uint32_t& newval, int bits) {
	if (m_sigs_oldval[code] != newval) { dumpValueBus (code, newval, bits); }
    }
    inline void dumpArray (uint32_t code, const uint32_t* newval, int bits) {
	for (int word=0; word<((bits/32)+1); ++word) {
	    if (m_sigs_oldval[code+word] != newval[word]) {
		dumpValueArray (code,newval,bits);
		return;
	    }
	}
    }
};

//=============================================================================
// SpTraceHelper
// This class is passed to the SystemC simulation kernal to make it look like
// a sc_trace_file

#ifndef SPTRACEVCD_TEST
class SpTraceFile : sc_trace_file {
    SpTraceVcd		m_sptrace;
public:
    SpTraceFile() {
	sc_get_curr_simcontext()->add_trace_file(this);
    }
    void open (const char* filename) { m_sptrace.open(filename); }
    void openNext (bool incFilename=true) { m_sptrace.openNext(incFilename); }
    void rolloverMB(size_t rolloverMB) { m_sptrace.rolloverMB(rolloverMB); };
    void close () { m_sptrace.close(); }
    // Called by SystemC simulate()
#if (SYSTEMC_VERSION>20011000)
    virtual void cycle (bool) { m_sptrace.dump(sc_time_stamp().to_double()); }
#else
    virtual void cycle (bool) { m_sptrace.dump(sc_time_stamp()); }
#endif
    inline SpTraceVcd* spTrace () { return &m_sptrace; };

private:
    // Fake outs for linker
    virtual void write_comment (const sc_string &);
    virtual void trace (const unsigned int &, const sc_string &, const char **);

#define DECL_TRACE_METHOD_A(tp) \
    virtual void trace( const tp& object, const sc_string& name );
#define DECL_TRACE_METHOD_B(tp) \
    virtual void trace( const tp& object, const sc_string& name, int width );

#if (SYSTEMC_VERSION>20011000)
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

};
#endif

#endif // guard
