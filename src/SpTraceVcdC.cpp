// $Id: SpTraceVcdC.cpp 55129 2008-05-28 19:44:59Z wsnyder $ -*- SystemC -*-
//=============================================================================
//
// THIS MODULE IS PUBLICLY LICENSED
//
// Copyright 2001-2008 by Wilson Snyder.  This program is free software;
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

#include <ctime>
#include <iostream>
#include <fstream>
#include <cassert>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#if defined(_WIN32) && !defined(__MINGW32__) && !defined(__CYGWIN__)
# include <io.h>
#else
# include <unistd.h>
#endif
#include <cerrno>
#include <cstdio>

// Note cannot include systemperl.h, or we won't work with non-SystemC compiles
#include "SpCommon.h"
#include "SpTraceVcdC.h"

#ifndef O_LARGEFILE
# define O_LARGEFILE 0
#endif

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
    SpTraceCallback_t	m_initcb;	///< Initialization Callback function
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
    if (isOpen()) return;

    // Assertions, as we cast enum to uint32_t pointers in AutoTrace.pm
    enum SpTraceVcd_enumtest { FOO = 1 };
    if (sizeof(SpTraceVcd_enumtest) != sizeof(uint32_t)) {
	SP_ABORT("%Error: SpTraceVcd::open cast assumption violated\n");
    }

    // Set member variables
    m_filename = filename;
    s_vcdVecp.push_back(this);

    openNext (m_rolloverMB!=0);
    if (!isOpen()) return;

    dumpHeader();

    // Allocate space now we know the number of codes
    if (!m_sigs_oldvalp) {
	m_sigs_oldvalp = new uint32_t [m_nextCode+10];
    }

    if (m_rolloverMB) {
	openNext(true);
	if (!isOpen()) return;
    }
}

void SpTraceVcd::openNext (bool incFilename) {
    // Open next filename in concat sequence, mangle filename if
    // incFilename is true.
    closePrev(); // Close existing
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
    if (m_filename[0]=='|') {
	assert(0);	// Not supported yet.
    } else {
	m_fd = ::open (m_filename.c_str(), O_CREAT|O_WRONLY|O_TRUNC|O_LARGEFILE, 0666);
	if (m_fd<0) {
	    // User code can check isOpen()
	    m_isOpen = false;
	    return;
	}
    }
    m_isOpen = true;
    m_fullDump = true;	// First dump must be full
    m_wroteBytes = 0;
}

SpTraceVcd::~SpTraceVcd() {
    closePrev();
    if (m_wrBufp) { delete[] m_wrBufp; m_wrBufp=NULL; }
    if (m_sigs_oldvalp) { delete[] m_sigs_oldvalp; m_sigs_oldvalp=NULL; }
    // Remove from list of traces
    vector<SpTraceVcd*>::iterator pos = find(s_vcdVecp.begin(), s_vcdVecp.end(), this);
    if (pos != s_vcdVecp.end()) { s_vcdVecp.erase(pos); }
}

void SpTraceVcd::closePrev () {
    if (!isOpen()) return;

    bufferFlush();
    m_isOpen = false;
    ::close(m_fd);
}

void SpTraceVcd::closeErr () {
    // Close due to an error.  We might abort before even getting here,
    // depending on the definition of SP_ABORT.
    if (!isOpen()) return;

    // No buffer flush, just fclose
    m_isOpen = false;
    ::close(m_fd);  // May get error, just ignore it
}

void SpTraceVcd::close() {
    if (!isOpen()) return;
    if (m_evcd) {
	printStr("$vcdclose ");
	printTime(m_timeLastDump);
	printStr(" $end\n");
    }
    closePrev();
}

void SpTraceVcd::printStr (const char* str) {
    // Not fast...
    while (*str) {
	*m_writep++ = *str++;
	bufferCheck();
    }
}

void SpTraceVcd::printQuad (uint64_t n) {
    char buf [100];
    sprintf(buf,"%llu",(long long unsigned)n);
    printStr(buf);
}

void SpTraceVcd::printTime (uint64_t timeui) {
    // VCD file format specification does not allow non-integers for timestamps
    // Dinotrace doesn't mind, but Cadence vvision seems to choke
    if (timeui < m_timeLastDump) {
	timeui = m_timeLastDump;
	static bool backTime = false;
	if (!backTime) {
	    backTime = true;
	    SP_NOTICE_LN(__FILE__,__LINE__, "VCD time is moving backwards, wave file may be incorrect.\n");
	}
    }
    m_timeLastDump = timeui;
    printQuad(timeui);
}

void SpTraceVcd::bufferFlush () {
    // We add output data to m_writep.
    // When it gets nearly full we dump it using this routine which calls write()
    // This is much faster than using buffered I/O
    if (!isOpen()) return;
    char* wp = m_wrBufp;
    while (1) {
	size_t remaining = (m_writep - wp);
	if (remaining==0) break;
	errno = 0;
	int got = write (m_fd, wp, remaining);
	if (got>0) {
	    wp += got;
	    m_wroteBytes += got;
	} else if (got < 0) {
	    if (errno != EAGAIN && errno != EINTR) {
		/* write failed, presume error (perhaps out of disk space) */
		SP_ABORT("%Error: SpTraceVcd::bufferFlush: "<<strerror(errno)<<endl);
		closeErr();
		break;
	    }
	}
    }

    // Reset buffer
    m_writep = m_wrBufp;
}

//=============================================================================
// Simple methods

void SpTraceVcd::set_time_unit (const char* unitp) {
    string unitstr (unitp);
    //cout<<" set_time_unit ("<<unitp<<") == "<<timescaleToDouble(unitp)<<" == "<<doubleToTimescale(timescaleToDouble(unitp))<<endl;
    m_timeUnit = timescaleToDouble(unitp);
}

void SpTraceVcd::set_time_resolution (const char* unitp) {
    string unitstr (unitp);
    //cout<<"set_time_resolution ("<<unitp<<") == "<<timescaleToDouble(unitp)<<" == "<<doubleToTimescale(timescaleToDouble(unitp))<<endl;
    m_timeRes = timescaleToDouble(unitp);
}

double SpTraceVcd::timescaleToDouble (const char* unitp) {
    char* endp;
    double value = strtod(unitp, &endp);
    if (!value) value=1;  // On error so we allow just "ns" to return 1e-9.
    unitp=endp;
    while (*unitp && isspace(*unitp)) unitp++;
    switch (*unitp) {
    case 's': value *= 1e1; break;
    case 'm': value *= 1e-3; break;
    case 'u': value *= 1e-6; break;
    case 'n': value *= 1e-9; break;
    case 'p': value *= 1e-12; break;
    case 'f': value *= 1e-15; break;
    case 'a': value *= 1e-18; break;
    }
    return value;
}

string SpTraceVcd::doubleToTimescale (double value) {
    const char* suffixp = "s";
    if	    (value>=1e0)   { suffixp="s"; value *= 1e0; }
    else if (value>=1e-3 ) { suffixp="ms"; value *= 1e3; }
    else if (value>=1e-6 ) { suffixp="us"; value *= 1e6; }
    else if (value>=1e-9 ) { suffixp="ns"; value *= 1e9; }
    else if (value>=1e-12) { suffixp="ps"; value *= 1e12; }
    else if (value>=1e-15) { suffixp="fs"; value *= 1e15; }
    else if (value>=1e-18) { suffixp="as"; value *= 1e18; }
    char valuestr[100]; sprintf(valuestr,"%d%s",(int)(value), suffixp);
    return valuestr;  // Gets converted to string, so no ref to stack
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
    printStr(doubleToTimescale(m_timeRes).c_str());
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

    // We detect the .'s in module names to determine hierarchy.  This
    // allows signals to be declared without fixed ordering, which is
    // required as Verilog signals might be separately declared from
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
	bool first = true;
	for (; *lp; lp++) {
	    if (*lp=='.' || (first && *lp!=' ')) {
		if (*(lp+1)=='.') break;  // ".." means signal name starts
		printIndent(-1);
		printStr("$upscope $end\n");
	    }
	    first = false;
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
    if (m_sigs.capacity() <= m_nextCode) {
	m_sigs.reserve(m_nextCode*2);	// Power-of-2 allocation speeds things up
    }

    // Save declaration info
    SpTraceVcdSig sig = SpTraceVcdSig(code, (msb-lsb+1));
    m_sigs.push_back(sig);

    // Split name into basename
    string hiername;	// space separates scope from basename of signal
    const char* basename = name;
    if (char* dot = (char*)strrchr(basename,'.')) {
	int predotlen = dot - basename;
	string nameasstr = name;
	basename=dot+1;
	if (m_modName!="") { hiername = m_modName+"."; }  // Make ->module calls optional
	hiername += nameasstr.substr(0,predotlen)+" "+basename;
    } else {
	if (m_modName!="") { hiername = m_modName+" "; }  // Make ->module calls optional
	hiername += name;
    }

    // Print reference
    string decl = (m_evcd?"$var port ":"$var wire ");
    char buf [1000];
    sprintf(buf, "%2d ", msb-lsb+1);
    decl += buf;
    if (m_evcd) {
	sprintf(buf, "<%d", code);
	decl += buf;
    } else {
	decl += stringCode(code);
    }
    decl += (string(" "))+basename;
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
    if (isOpen()) {
	SP_ABORT("%Error: SpTraceVcd::"<<__FUNCTION__<<" called with already open file\n");
    }
    SpTraceCallInfo* vci = new SpTraceCallInfo(initcb, fullcb, changecb, userthis, nextCode());
    m_callbacks.push_back(vci);
}

//=============================================================================
// Dumping

void SpTraceVcd::dumpFull (uint64_t timeui) {
    dumpPrep (timeui);
    for (uint32_t ent = 0; ent< m_callbacks.size(); ent++) {
	SpTraceCallInfo *cip = m_callbacks[ent];
	(cip->m_fullcb) (this, cip->m_userthis, cip->m_code);
    }
    dumpDone ();
}

void SpTraceVcd::dump (uint64_t timeui) {
    if (!isOpen()) return;
    if (m_fullDump) {
	m_fullDump = false;	// No need for more full dumps
	dumpFull(timeui);
	return;
    }
    if (m_rolloverMB && m_wroteBytes > this->m_rolloverMB) {
	openNext(true);
	if (!isOpen()) return;
    }
    dumpPrep (timeui);
    for (uint32_t ent = 0; ent< m_callbacks.size(); ent++) {
	SpTraceCallInfo *cip = m_callbacks[ent];
	(cip->m_changecb) (this, cip->m_userthis, cip->m_code);
    }
    dumpDone();
}

void SpTraceVcd::dumpPrep (uint64_t timeui) {
    printStr("#");
    printTime(timeui);
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
uint64_t timestamp = 1;

void vcdInit (SpTraceVcd* vcdp, void* userthis, uint32_t code) {
    vcdp->module ("top");
     vcdp->declBus (0x2, "v1",-1,5,1);
     vcdp->declBus (0x3, "v2",-1,6,0);
     vcdp->module ("top.sub1");
      vcdp->declBit (0x4, "s1",-1);
      vcdp->declBit (0x5, "ch",-1);
     vcdp->module ("top.sub2");
      vcdp->declArray (0x6, "s2",-1, 40,3);
    vcdp->module ("top2");
     vcdp->declBus (0x2, "t2v1",-1,5,1);
}

void vcdFull (SpTraceVcd* vcdp, void* userthis, uint32_t code) {
    vcdp->fullBus  (0x2, v1,5);
    vcdp->fullBus  (0x3, v2,7);
    vcdp->fullBit  (0x4, s1);
    vcdp->fullBus  (0x5, ch,2);
    vcdp->fullArray(0x6, &s2[0], 38);
}

void vcdChange (SpTraceVcd* vcdp, void* userthis, uint32_t code) {
    vcdp->chgBus  (0x2, v1,5);
    vcdp->chgBus  (0x3, v2,7);
    vcdp->chgBit  (0x4, s1);
    vcdp->chgBus  (0x5, ch,2);
    vcdp->chgArray(0x6, &s2[0], 38);
    // Note need to add 3 for next code.
}

main() {
    cout<<"test: O_LARGEFILE="<<O_LARGEFILE<<endl;

    v1 = v2 = s1 = 0;
    s2[0] = s2[1] = s2[2] = 0;
    ch = 0;
    {
	SpTraceVcdCFile* vcdp = new SpTraceVcdCFile;
	vcdp->spTrace()->addCallback (&vcdInit, &vcdFull, &vcdChange, 0);
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
# if SPTRACEVCD_TEST_64BIT
	uint64_t bytesPerDump = 15ULL;
	for (uint64_t i=0; i<((1ULL<<32) / bytesPerDump); i++) {
	    v1 = i;
	    vcdp->dump(timestamp++);
	}
# endif
	vcdp->close();
    }
}
#endif

//********************************************************************
// Local Variables:
// compile-command: "mkdir -p ../test_dir && cd ../test_dir && g++ -DSPTRACEVCD_TEST ../src/SpTraceVcdC.cpp -o SpTraceVcdC && ./SpTraceVcdC && cat test.vcd"
// End:
