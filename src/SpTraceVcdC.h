// $Id: SpTraceVcdC.h 43369 2007-08-16 13:59:01Z wsnyder $ -*- SystemC -*-
//=============================================================================
//
// THIS MODULE IS PUBLICLY LICENSED
//
// Copyright 2001-2007 by Wilson Snyder.  This program is free software;
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
/// \brief C++ Tracing in VCD Format
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================

#ifndef _SPTRACEVCDC_H_
#define _SPTRACEVCDC_H_ 1

#include <sys/types.h>	// uint32_t
#include <stdint.h>	// uint32_t
#include <iostream>
#include <fstream>
#include <string>
#include <algorithm>
#include <vector>
#include <map>
using namespace std;

// Note cannot include systemperl.h, or we won't work with non-SystemC compiles
#include "SpCommon.h"

class SpTraceVcd;
class SpTraceCallInfo;

//=============================================================================
// SpTraceVcdSig
/// Internal data on one signal being traced.

class SpTraceVcdSig {
protected:
    friend class SpTraceVcd;
    uint32_t		m_code;		///< VCD file code number
    int			m_bits;		///< Size of value in bits
    SpTraceVcdSig (uint32_t code, int bits)
	: m_code(code), m_bits(bits) {}
public:
    ~SpTraceVcdSig() {}
};

//=============================================================================

typedef void (*SpTraceCallback_t)(SpTraceVcd* vcdp, void* userthis, uint32_t code);

//=============================================================================
// SpTraceVcd
/// Create a SystemPerl VCD dump

class SpTraceVcd {
private:
    bool 		m_isOpen;	///< True indicates open file
    bool		m_evcd;		///< True for evcd format
    int			m_fd;		///< File descriptor we're writing to
    string		m_filename;	///< Filename we're writing to (if open)
    uint64_t		m_rolloverMB;	///< MB of file size to rollover at
    int			m_modDepth;	///< Depth of module hierarchy
    bool		m_fullDump;	///< True indicates dump ignoring if changed
    uint32_t		m_nextCode;	///< Next code number to assign
    string		m_modName;	///< Module name being traced now
    double		m_timeRes;	///< Time resolution (ns/ms etc)
    double		m_timeUnit;	///< Time units (ns/ms etc)
    uint64_t		m_timeLastDump;	///< Last time we did a dump

    char*		m_wrBufp;	///< Output buffer
    char*		m_writep;	///< Write pointer into output buffer
    uint64_t		m_wroteBytes;	///< Number of bytes written to this file

    uint32_t*			m_sigs_oldvalp;	///< Pointer to old signal values
    vector<SpTraceVcdSig>	m_sigs;		///< Pointer to signal information
    vector<SpTraceCallInfo*>	m_callbacks;	///< Routines to perform dumping
    typedef map<string,string>	NameMap;
    NameMap*			m_namemapp;	///< List of names for the header
    static vector<SpTraceVcd*>	s_vcdVecp;	///< List of all created traces

    size_t	bufferSize() { return 256*1024; }  // See below for slack calculation
    void bufferFlush();
    void bufferCheck() {
	// Flush the write buffer if there's not enough space left for new information
	// We only call this once per vector, so we need enough slop for a very wide "b###" line
	if (m_writep > (m_wrBufp+(bufferSize()-16*1024))) {
	    bufferFlush();
	}
    }
    void closePrev();
    void openNext();
    void printIndent (int levelchange);
    void printStr (const char* str);
    void printQuad (uint64_t n);
    void printTime (uint64_t timeui);
    void declare (uint32_t code, const char* name, int arraynum, int msb, int lsb);

    void dumpHeader();
    void dumpPrep (uint64_t timeui);
    void dumpFull (uint64_t timeui);
    void dumpDone ();
    inline void printCode (uint32_t code) {
	if (code>=(94*94*94)) *m_writep++ = ((char)((code/94/94/94)%94+33));
	if (code>=(94*94))    *m_writep++ = ((char)((code/94/94)%94+33));
	if (code>=(94))       *m_writep++ = ((char)((code/94)%94+33));
	*m_writep++ = ((char)((code)%94+33));
    }
    string stringCode (uint32_t code) {
	string out;
	if (code>=(94*94*94)) out += ((char)((code/94/94/94)%94+33));
	if (code>=(94*94))    out += ((char)((code/94/94)%94+33));
	if (code>=(94))       out += ((char)((code/94)%94+33));
	return out + ((char)((code)%94+33));
    }

protected:
    // METHODS
    void evcd(bool flag) { m_evcd = flag; }

public:
    // CREATORS
    SpTraceVcd () : m_isOpen(false), m_rolloverMB(0), m_modDepth(0), m_nextCode(1) {
	m_wrBufp = new char [bufferSize()];
	m_writep = m_wrBufp;
	m_namemapp = NULL;
	m_timeRes = m_timeUnit = 1e-9;
	m_timeLastDump = 0;
	m_sigs_oldvalp = NULL;
	m_evcd = false;
	m_wroteBytes = 0;
    }
    ~SpTraceVcd();

    // ACCESSORS
    /// Inside dumping routines, return next VCD signal code
    uint32_t nextCode() const {return m_nextCode;}
    /// Set size in megabytes after which new file should be created
    void rolloverMB(uint64_t rolloverMB) { m_rolloverMB=rolloverMB; };
    /// Is file open?
    bool isOpen() const { return m_isOpen; }

    // METHODS
    void open (const char* filename);	///< Open the file; call isOpen() to see if errors
    void openNext (bool incFilename);	///< Open next data-only file
    void flush() { bufferFlush(); }	///< Flush any remaining data
    static void flush_all();		///< Flush any remaining data from all files
    void close ();			///< Close the file

    void set_time_unit (const char* unit); ///< Set time units (s/ms, defaults to ns)
    void set_time_unit (const string& unit) { set_time_unit(unit.c_str()); }

    void set_time_resolution (const char* unit); ///< Set time resolution (s/ms, defaults to ns)
    void set_time_resolution (const string& unit) { set_time_resolution(unit.c_str()); }

    double timescaleToDouble (const char* unitp);
    string doubleToTimescale (double value);

    /// Inside dumping routines, called each cycle to make the dump
    void dump     (uint64_t timeui);
    /// Call dump with a absolute unscaled time in seconds
    void dumpSeconds (double secs) { dump((uint64_t)(secs * m_timeRes)); }

    /// Inside dumping routines, declare callbacks for tracings
    void addCallback (SpTraceCallback_t init, SpTraceCallback_t full, SpTraceCallback_t change,
		      void* userthis);

    /// Inside dumping routines, declare a module
    void module (const string name);
    /// Inside dumping routines, declare a signal
    void declBit   (uint32_t code, const char* name, int arraynum);
    void declBus   (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    void declQuad  (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    void declArray (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    //	... other module_start for submodules (based on cell name)

    /// Inside dumping routines, dump one signal
    inline void fullBit (uint32_t code, const uint32_t newval) {
	// Note the &1, so we don't require clean input -- makes more common no change case faster
	m_sigs_oldvalp[code] = newval;
	*m_writep++=('0'+(newval&1)); printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    inline void fullBus (uint32_t code, const uint32_t newval, int bits) {
	m_sigs_oldvalp[code] = newval;
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++=((newval&(1L<<bit))?'1':'0');
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    inline void fullQuad (uint32_t code, const uint64_t newval, int bits) {
	(*((uint64_t*)&m_sigs_oldvalp[code])) = newval;
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++=((newval&(1ULL<<bit))?'1':'0');
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    inline void fullArray (uint32_t code, const uint32_t* newval, int bits) {
	for (int word=0; word<(((bits-1)/32)+1); ++word) {
	    m_sigs_oldvalp[code+word] = newval[word];
	}
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++=((newval[(bit/32)]&(1L<<(bit&0x1f)))?'1':'0');
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }

    /// Inside dumping routines, dump one signal as unknowns
    /// Presently this code doesn't change the oldval vector.
    /// Thus this is for special standalone applications that after calling
    /// fullBitX, must when then value goes non-X call fullBit.
    inline void fullBitX (uint32_t code) {
	*m_writep++='x'; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    inline void fullBusX (uint32_t code, int bits) {
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++='x';
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    inline void fullQuadX (uint32_t code, int bits) { fullBusX (code, bits); }
    inline void fullArrayX (uint32_t code, int bits) { fullBusX (code, bits); }

    /// Inside dumping routines, dump one signal if it has changed
    inline void chgBit (uint32_t code, const uint32_t newval) {
	uint32_t diff = m_sigs_oldvalp[code] ^ newval;
	if (SP_UNLIKELY(diff)) {
	    // Verilator 3.510 and newer provide clean input, so the below is only for back compatibility
	    if (SP_UNLIKELY(diff & 1)) {   // Change after clean?
		fullBit (code, newval);
	    }
	}
    }
    inline void chgBus (uint32_t code, const uint32_t newval, int bits) {
	uint32_t diff = m_sigs_oldvalp[code] ^ newval;
	if (SP_UNLIKELY(diff)) {
	    if (SP_UNLIKELY(bits==32 || (diff & ((1U<<bits)-1) ))) {
		fullBus (code, newval, bits);
	    }
	}
    }
    inline void chgQuad (uint32_t code, const uint64_t newval, int bits) {
	uint64_t diff = (*((uint64_t*)&m_sigs_oldvalp[code])) ^ newval;
	if (SP_UNLIKELY(diff)) {
	    if (SP_UNLIKELY(bits==64 || (diff & ((1ULL<<bits)-1) ))) {
		fullQuad(code, newval, bits);
	    }
	}
    }
    inline void chgArray (uint32_t code, const uint32_t* newval, int bits) {
	for (int word=0; word<(((bits-1)/32)+1); ++word) {
	    if (SP_UNLIKELY(m_sigs_oldvalp[code+word] ^ newval[word])) {
		fullArray (code,newval,bits);
		return;
	    }
	}
    }
};

//=============================================================================
// SpTraceVcdCFile
/// Create a VCD dump file in C standalone (no SystemC) simulations.

class SpTraceVcdCFile {
    SpTraceVcd		m_sptrace;	///< SystemPerl trace file being created
public:
    // CONSTRUCTORS
    SpTraceVcdCFile() {}
    ~SpTraceVcdCFile() {}
    // ACCESSORS
    /// Is file open?
    bool isOpen() const { return m_sptrace.isOpen(); }
    // METHODS
    /// Open a new VCD file
    void open (const char* filename) { m_sptrace.open(filename); }
    /// Continue a VCD dump by rotating to a new file name
    void openNext (bool incFilename=true) { m_sptrace.openNext(incFilename); }
    /// Set size in megabytes after which new file should be created
    void rolloverMB(size_t rolloverMB) { m_sptrace.rolloverMB(rolloverMB); };
    /// Close dump
    void close() { m_sptrace.close(); }
    /// Flush dump
    void flush() { m_sptrace.flush(); }
    /// Write one cycle of dump data
    void dump (uint64_t timeui) { m_sptrace.dump(timeui); }
    /// Write one cycle of dump data - backward compatible and to reduce
    /// conversion warnings.  It's better to use a uint64_t time instead.
    void dump (double timestamp) { dump((uint64_t)timestamp); }
    void dump (uint32_t timestamp) { dump((uint64_t)timestamp); }
    void dump (int timestamp) { dump((uint64_t)timestamp); }
    /// Internal class access
    inline SpTraceVcd* spTrace () { return &m_sptrace; };
};

#endif // guard
