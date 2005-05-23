// $Revision: 1.4 $$Date: 2005-04-12 15:02:31 -0400 (Tue, 12 Apr 2005) $$Author: wsnyder $ -*- SystemC -*-
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
/// \brief C++ Tracing in VCD Format
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================

#include <time.h>
#include <iostream>
#include <fstream>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>

// Note cannot include systemperl.h, or we won't work with non-SystemC compiles
#include "SpCommon.h"
#include "SpTraceVcdC.h"

//=============================================================================
// Global

vector<SpTraceVcd*>	SpTraceVcd::s_vcdVecp;	///< List of all created traces

//=============================================================================
// SpTraceCallback
/// Internal callback routines for each module being traced.
////
/// Each SystemPerl module that wishes to be traced registers a set of
/// callbacks stored in this class.  When the trace file is being
/// constructed, this class provides the callback routines to be executed.

class SpTraceCallInfo {
protected:
    friend class SpTraceVcd;
    SpTraceCallback_t	m_initcb;	///< Initalization Callback function
    SpTraceCallback_t	m_fullcb;	///< Full Dumping Callback function
    SpTraceCallback_t	m_changecb;	///< Incremental Dumping Callback function
    void*		m_userthis;	///< Fake "this" for caller
    uint32_t		m_code;		///< Starting code number
    // CREATORS
    SpTraceCallInfo (SpTraceCallback_t icb, SpTraceCallback_t fcb, SpTraceCallback_t changecb,
		     void* ut, uint32_t code)
	: m_initcb(icb), m_fullcb(fcb), m_changecb(changecb), m_userthis(ut), m_code(code) {};
};

//=============================================================================
//=============================================================================
//=============================================================================
// Opening/Closing

void SpTraceVcd::open (const char* filename) {
    if (m_isOpen) return;

    // Assertions, as we cast enum to uint32_t pointers in AutoTrace.pm
    enum SpTraceVcd_enumtest { FOO = 1 };
    if (sizeof(SpTraceVcd_enumtest) != sizeof(uint32_t)) {
	SP_ABORT("%Error: SpTraceVcd::open cast assumption violated\n");
    }

    // Set member variables
    m_filename = filename;
    s_vcdVecp.push_back(this);

    openNext (m_rolloverMB!=0);

    dumpHeader();

    if (m_rolloverMB) {
	this->openNext(true);
    }
}

void SpTraceVcd::openNext (bool incFilename) {
    // Open next filename in concat sequence, mangle filename if
    // incFilename is true.
    close(); // Close existing
    if (incFilename) {
	// Find _0000.{ext} in filename
	string name = m_filename;
	int pos=name.rfind(".");
	if (pos>8 && 0==strncmp("_cat",name.c_str()+pos-8,4)
	    && isdigit(name.c_str()[pos-4])
	    && isdigit(name.c_str()[pos-3])
	    && isdigit(name.c_str()[pos-2])
	    && isdigit(name.c_str()[pos-1])) {
	    // Increment code.
	    if ((++(name[pos-1])) > '9') {
		name[pos-1] = '0';
		if ((++(name[pos-2])) > '9') {
		    name[pos-2] = '0';
		    if ((++(name[pos-3])) > '9') {
			name[pos-3] = '0';
			if ((++(name[pos-4])) > '9') {
			    name[pos-4] = '0';
			}}}}
	} else {
	    // Append _cat0000
	    name.insert(pos,"_cat0000");
	}
	m_filename = name;
    }
    m_isOpen = true;
    if (m_filename[0]=='|') {
	assert(0);	// Not supported yet.
    } else {
	m_fd = ::open (m_filename.c_str(), O_CREAT|O_WRONLY|O_TRUNC, 0666);
    }
    m_fullDump = true;	// First dump must be full
}

SpTraceVcd::~SpTraceVcd() {
    close();
    if (m_wrBufp) { delete m_wrBufp; m_wrBufp=NULL; }
    // Remove from list of traces
    vector<SpTraceVcd*>::iterator pos = find(s_vcdVecp.begin(), s_vcdVecp.end(), this);
    if (pos != s_vcdVecp.end()) { s_vcdVecp.erase(pos); }
}

void SpTraceVcd::close () {
    if (!m_isOpen) return;

    bufferFlush();
    m_isOpen = false;
    ::close(m_fd);
}

void SpTraceVcd::printStr (const char* str) {
    // Not fast...
    while (*str) {
	*m_writep++ = *str++;
	bufferCheck();
    }
}

void SpTraceVcd::printInt (int n) {
    char buf [100];
    sprintf(buf,"%d",n);
    printStr(buf);
}

void SpTraceVcd::bufferFlush () {
    // We add output data to m_writep.
    // When it gets nearly full we dump it using this routine which calls write()
    // This is much faster then using buffered I/O
    if (!m_isOpen) return;
    char* wp = m_wrBufp;
    while (1) {
	size_t remaining = (m_writep - wp);
	if (remaining==0) break;
	errno = 0;
	int got = write (m_fd, wp, remaining);
	if (got>0) {
	    wp += got;
	} else if (got < 0) {
	    if (errno != EAGAIN && errno != EINTR) {
		/* write failed, presume error */
		perror("bin-write");
		break;
	    }
	}
    }

    // Reset buffer
    m_writep = m_wrBufp;
}

//=============================================================================
// Simple methods

void SpTraceVcd::set_time_unit (const char* unit) {
    string unitstr (unit);
    if (!isdigit(unitstr[0])) unitstr = "1"+unitstr;
    m_timeUnit = unitstr;
}

void SpTraceVcd::set_time_resolution (const char* unit) {
    string unitstr (unit);
    if (!isdigit(unitstr[0])) unitstr = "1"+unitstr;
    m_timeRes = unitstr;
}

//=============================================================================
// Definitions

void SpTraceVcd::printIndent (int level_change) {
    if (level_change<0) m_modDepth += level_change;
    assert(m_modDepth>=0);
    for (int i=0; i<m_modDepth; i++) printStr(" ");
    if (level_change>0) m_modDepth += level_change;
}

void SpTraceVcd::dumpHeader () {
    printStr("$version Generated by SpTraceVcd $end\n");
    time_t time_str = time(NULL);
    printStr("$date "); printStr(ctime(&time_str)); printStr(" $end\n");

    printStr("$timescale ");
    printStr(m_timeRes.c_str());
    printStr(" $end\n");

    // Take signal information from each module and build m_namemapp
    m_namemapp = new NameMap;
    for (uint32_t ent = 0; ent< m_callbacks.size(); ent++) {
	SpTraceCallInfo *cip = m_callbacks[ent];
	cip->m_code = nextCode();
	(cip->m_initcb) (this, cip->m_userthis, cip->m_code);
    }

    // Signal header
    assert (m_modDepth==0);
    printIndent(1);
    printStr("\n");

    // We detect the .'s in module names to determine hiearchy.  This
    // allows signals to be declared without fixed ordering, which is
    // required as Verilog signals might be seperately declared from
    // SP_TRACE signals.

    // Print the signal names
    const char* lastName = "";
    for (NameMap::iterator it=m_namemapp->begin(); it!=m_namemapp->end(); ++it) {
	const char* hiername = (*it).first.c_str();
	const char* decl     = (*it).second.c_str();

	// Determine difference between the old and new names
	const char* lp = lastName;
	const char* np = hiername;
	lastName = hiername;

	// Skip common prefix, it must break at a "." or space
	for (; *np && (*np == *lp); np++, lp++) {}
	while (np!=hiername && *np && *np!='.' && *np!=' ') { np--; lp--; }
	//cout <<"hier "<<hiername<<endl<<"  lp "<<lp<<endl<<"  np "<<np<<endl;

	// Any extra .'s in last name are scope ups we need to do
	for (; *lp; lp++) {
	    if (*lp=='.') {
		if (*(lp+1)=='.') break;  // ".." means signal name starts
		printIndent(-1);
		printStr("$upscope $end\n");
	    }
	}

	// Any new .'s are scope downs we need to do
	while (*np) {
	    if (*np=='.') np++;
	    if (*np==' ') break; // " " means signal name starts
	    printIndent(1);
	    printStr("$scope module ");
	    for (; *np && *np!='.' && *np!=' '; np++) {
		if (*np=='[') printStr("(");
		else if (*np==']') printStr(")");
		else *m_writep++=*np;
	    }
	    printStr(" $end\n");
	}

	printIndent(0);
	printStr(decl);
    }

    while (m_modDepth>1) {
	printIndent(-1);
	printStr("$upscope $end\n");
    }

    printIndent(-1);
    printStr("$enddefinitions $end\n\n\n");
    assert (m_modDepth==0);

    // Reclaim storage
    delete m_namemapp;
}

void SpTraceVcd::module (string name) {
    m_modName = name;
}

void SpTraceVcd::declare (uint32_t code, const char* name, int arraynum,
			  int msb, int lsb) {	// -1 = is boolean
    if (!code) { SP_ABORT("%Error: internal trace problem, code 0 is illegal\n"); }

    // Make sure array is large enough
    m_nextCode = max(nextCode(), code+1+int((msb-lsb+1)/32));
    if (m_sigs.capacity() <= m_nextCode
	|| m_sigs_oldval.capacity() <= m_nextCode) {
	m_sigs.reserve(m_nextCode*2);	// Power-of-2 allocation speeds things up
	m_sigs_oldval.reserve(m_nextCode*2);
    }

    // Save declaration info
    SpTraceVcdSig sig = SpTraceVcdSig(code, (msb-lsb+1));
    m_sigs.push_back(sig);

    // Split name into basename
    string hiername;	// space seperates scope from basename of signal
    const char* basename = name;
    if (char* dot = strrchr(basename,'.')) {
	int predotlen = dot - basename;
	string nameasstr = name;
	basename=dot+1;
	hiername = m_modName+"."+nameasstr.substr(0,predotlen)+" "+basename;
    } else {
	hiername = m_modName+" "+name;
    }

    // Print reference
    string decl = "$var wire ";
    char buf [1000];
    sprintf(buf, "%2d ", msb-lsb+1);
    decl += buf+stringCode(code)+" "+basename;
    if (arraynum>=0) {
	sprintf(buf, "(%d)", arraynum);
	decl += buf;
	hiername += buf;
    }
    if (msb<0) {
	decl += " $end\n";
    } else {
	sprintf(buf, " [%d:%d] $end\n", msb, lsb);
	decl += buf;
    }
    m_namemapp->insert(make_pair(hiername,decl));
}

void SpTraceVcd::declBit (uint32_t code, const char* name, int arraynum)
{  declare (code, name, arraynum, -1, -1); }
void SpTraceVcd::declBus (uint32_t code, const char* name, int arraynum, int msb, int lsb)
{  declare (code, name, arraynum, msb, lsb); }
void SpTraceVcd::declQuad  (uint32_t code, const char* name, int arraynum, int msb, int lsb)
{  declare (code, name, arraynum, msb, lsb); }
void SpTraceVcd::declArray (uint32_t code, const char* name, int arraynum, int msb, int lsb)
{  declare (code, name, arraynum, msb, lsb); }

//=============================================================================
// Callbacks

void SpTraceVcd::addCallback (
    SpTraceCallback_t initcb, SpTraceCallback_t fullcb, SpTraceCallback_t changecb,
    void* userthis)
{
    if (m_isOpen) {
	SP_ABORT("%Error: SpTraceVcd::"<<__FUNCTION__<<" called with already open file\n");
    }
    SpTraceCallInfo* vci = new SpTraceCallInfo(initcb, fullcb, changecb, userthis, nextCode());
    m_callbacks.push_back(vci);
}

//=============================================================================
// Dumping

void SpTraceVcd::dumpFull (double timestamp) {
    dumpPrep (timestamp);
    for (uint32_t ent = 0; ent< m_callbacks.size(); ent++) {
	SpTraceCallInfo *cip = m_callbacks[ent];
	(cip->m_fullcb) (this, cip->m_userthis, cip->m_code);
    }
    dumpDone ();
}

void SpTraceVcd::dump (double timestamp) {
    if (!m_isOpen) return;
    if (m_fullDump) {
	m_fullDump = false;	// No need for more full dumps
	dumpFull(timestamp);
	return;
    }
    if (m_rolloverMB && (lseek(m_fd, 0, SEEK_CUR)/1e6 >= this->m_rolloverMB)) this->openNext(true);
    dumpPrep (timestamp);
    for (uint32_t ent = 0; ent< m_callbacks.size(); ent++) {
	SpTraceCallInfo *cip = m_callbacks[ent];
	(cip->m_changecb) (this, cip->m_userthis, cip->m_code);
    }
    dumpDone();
}

void SpTraceVcd::dumpPrep (double timestamp) {
    printStr("#");
    // VCD file format specification does not allow non-integers for timestamps
    // Dinotrace doesn't mind, but Cadence vvision seems to choke
    printInt((int)timestamp);
    printStr("\n");
}

void SpTraceVcd::dumpDone () {
}

//======================================================================
// Static members

void SpTraceVcd::flush_all() {
    for (uint32_t ent = 0; ent< s_vcdVecp.size(); ent++) {
	SpTraceVcd* vcdp = s_vcdVecp[ent];
	vcdp->flush();
    }
}

//======================================================================
//======================================================================
//======================================================================

#if SPTRACEVCD_TEST
uint32_t v1, v2, s1, s2[3];
uint8_t ch;
double timestamp = 1;

void init (SpTraceVcd* vcdp, void* userthis, uint32_t code) {
    vcdp->module ("top");
     vcdp->declBus (0x2, "v1",-1,5,1);
     vcdp->declBus (0x3, "v2",-1,6,0);
     vcdp->module ("top.sub1");
      vcdp->declBit (0x4, "s1",-1);
      vcdp->declBit (0x5, "ch",-1);
     vcdp->module ("top.sub2");
      vcdp->declArray (0x6, "s2",-1, 40,3);
}

void full (SpTraceVcd* vcdp, void* userthis, uint32_t code) {
    vcdp->fullBus  (0x2, v1,5);
    vcdp->fullBus  (0x3, v2,7);
    vcdp->fullBit  (0x4, s1);
    vcdp->fullBus  (0x5, ch,2);
    vcdp->fullArray(0x6, &s2[0], 38);
}

void change (SpTraceVcd* vcdp, void* userthis, uint32_t code) {
    vcdp->chgBus  (0x2, v1,5);
    vcdp->chgBus  (0x3, v2,7);
    vcdp->chgBit  (0x4, s1);
    vcdp->chgBus  (0x5, ch,2);
    vcdp->chgArray(0x6, &s2[0], 38);
    // Note need to add 3 for next code.
}

main() {
    v1 = v2 = s1 = 0;
    s2[0] = s2[1] = s2[2] = 0;
    ch = 0;

    SpTraceVcdCFile* vcdp = new SpTraceVcdCFile;
    vcdp->spTrace()->addCallback (&init, &full, &change, 0);
    vcdp->open ("test.vcd");

    // Dumping
    vcdp->dump(timestamp++);
    v1 = 0xfff;
    vcdp->dump(timestamp++);
    v2 = 0x1;
    s2[1] = 2;
    vcdp->dump(timestamp++);
    ch = 2;
    vcdp->dump(timestamp++);
    vcdp->close();
}
#endif

//********************************************************************
// Local Variables:
// compile-command: "mkdir -p ../test_dir && cd ../test_dir && g++ -DSPTRACEVCD_TEST ../src/SpTraceVcdC.cpp -o SpTraceVcdC && ./SpTraceVcdC && cat test.vcd"
// End:
