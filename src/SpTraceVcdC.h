// $Revision: #4 $$Date: 2004/08/12 $$Author: ws150726 $ -*- SystemC -*-
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
// DESCRIPTION: Tracing in SpTraceVcd Format
//
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

//=============================================================================
// SpTraceVcdSig

class SpTraceVcdSig {
protected:
    friend class SpTraceVcd;
    uint32_t		m_code;		// Code number
    int			m_bits;		// Size of value
    SpTraceVcdSig (uint32_t code, int bits)
	: m_code(code), m_bits(bits) {}
};

//=============================================================================
// SpTraceVcdSig

typedef void (*SpTraceCallback_t)(SpTraceVcd* vcdp, void* userthis, uint32_t code);
class SpTraceCallInfo;

class SpTraceVcd {
private:
    bool 		m_isOpen;	// True indicates open file
    int			m_fd;		// File descriptor we're writing to
    string		m_filename;	// Filename we're writing to (if open)
    size_t		m_rolloverMB;	// MB of file size to rollover at
    int			m_modDepth;	// Depth of module hiearchy
    bool		m_fullDump;	// True indicates dump ignoring if changed
    uint32_t		m_nextCode;	// Next code number to assign
    string		m_modName;	// Module name being traced now
    char*		m_wrBufp;	// Output buffer
    char*		m_writep;	// Write pointer into output buffer

    vector<SpTraceVcdSig>	m_sigs;		// Pointer to signal information
    vector<uint32_t>		m_sigs_oldval;	// Pointer to old signal values
    vector<SpTraceCallInfo*>	m_callbacks;	// Routines to perform dumping
    typedef map<string,string>	NameMap;
    NameMap*			m_namemapp;	// List of names for the header
    static vector<SpTraceVcd*>	s_vcdVecp;	// List of all created traces

    size_t	bufferSize() { return 256*1024; }  // See below for slack calculation
    void bufferFlush();
    void bufferCheck() {
	// Flush the write buffer if there's not enough space left for new information
	// We only call this once per vector, so we need enough slop for a very wide "b###" line
	if (m_writep > (m_wrBufp+(bufferSize()-16*1024))) {
	    bufferFlush();
	}
    }
    void openNext();
    void printIndent (int levelchange);
    void printStr (const char* str);
    void printInt (int n);
    void declare (uint32_t code, const char* name, int arraynum, int msb, int lsb);

    void dumpHeader();
    void dumpPrep (double timestamp);
    void dumpFull (double timestamp);
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

public:
    // CREATORS
    SpTraceVcd () : m_isOpen(false), m_rolloverMB(0), m_modDepth(0), m_nextCode(1) {
	m_wrBufp = new char [bufferSize()];
	m_writep = m_wrBufp;
	m_namemapp = NULL;
    }
    ~SpTraceVcd();

    // ACCESSORS
    uint32_t nextCode() const {return m_nextCode;}
    void rolloverMB(size_t rolloverMB) { m_rolloverMB=rolloverMB; };

    // METHODS
    void open (const char* filename);	// Open the file
    void openNext (bool incFilename);	// Open next data-only file
    void flush() { bufferFlush(); }	// Flush any remaining data
    static void flush_all();		// Flush any remaining data from all files
    void close ();			// Close the file

    void addCallback (SpTraceCallback_t init, SpTraceCallback_t full, SpTraceCallback_t change,
		      void* userthis);

    void init ();
    void module (const string name);
    void declBit   (uint32_t code, const char* name, int arraynum);
    void declBus   (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    void declQuad  (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    void declArray (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    //	... other module_start for submodules (based on cell name)

    // Regular dumping
    void dump     (double timestamp);

    // Full dumping
    inline void fullBit (uint32_t code, const uint32_t newval) {
	// Note the &1, so we don't require clean input -- makes more common no change case faster
	m_sigs_oldval[code] = newval;
	*m_writep++=('0'+(newval&1)); printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    inline void fullBus (uint32_t code, const uint32_t newval, int bits) {
	m_sigs_oldval[code] = newval;
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++=((newval&(1L<<bit))?'1':'0');
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    inline void fullQuad (uint32_t code, const uint64_t newval, int bits) {
	(*((uint64_t*)&m_sigs_oldval[code])) = newval;
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++=((newval&(1ULL<<bit))?'1':'0');
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    inline void fullArray (uint32_t code, const uint32_t* newval, int bits) {
	for (int word=0; word<(((bits-1)/32)+1); ++word) {
	    m_sigs_oldval[code+word] = newval[word];
	}
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++=((newval[(bit/32)]&(1L<<(bit&0x1f)))?'1':'0');
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }

    // Incremental dumpings
    inline void chgBit (uint32_t code, const uint32_t newval) {
	if (m_sigs_oldval[code] != newval) { fullBit (code, newval); }
    }
    inline void chgBus (uint32_t code, const uint32_t newval, int bits) {
	if (m_sigs_oldval[code] != newval) { fullBus (code, newval, bits); }
    }
    inline void chgQuad (uint32_t code, const uint64_t newval, int bits) {
	if ((*((uint64_t*)&m_sigs_oldval[code])) != newval) { fullQuad(code, newval, bits); }
    }
    inline void chgArray (uint32_t code, const uint32_t* newval, int bits) {
	for (int word=0; word<(((bits-1)/32)+1); ++word) {
	    if (m_sigs_oldval[code+word] != newval[word]) {
		fullArray (code,newval,bits);
		return;
	    }
	}
    }
};

//=============================================================================
// SpTraceVcdCFile
// This class is used by C standalone simulations

class SpTraceVcdCFile {
    SpTraceVcd		m_sptrace;
public:
    SpTraceVcdCFile() {}
    ~SpTraceVcdCFile() {}
    void open (const char* filename) { m_sptrace.open(filename); }
    void openNext (bool incFilename=true) { m_sptrace.openNext(incFilename); }
    void rolloverMB(size_t rolloverMB) { m_sptrace.rolloverMB(rolloverMB); };
    void close() { m_sptrace.close(); }
    void flush() { m_sptrace.flush(); }
    void dump (double timestamp) { m_sptrace.dump(timestamp); }
    inline SpTraceVcd* spTrace () { return &m_sptrace; };
};

#endif // guard
