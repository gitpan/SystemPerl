// $Id: SpTraceVcd.cpp,v 1.13 2002/02/26 15:50:58 wsnyder Exp $ -*- SystemC -*-
//=============================================================================
//
// THIS MODULE IS PUBLICLY LICENSED
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of either the GNU General Public License or the
// Perl Artistic License, with the exception that it cannot be placed
// on a CD-ROM or similar media for commercial distribution without the
// prior approval of the author.
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
// DESCRIPTION: Tracing in vcd Format
//
//=============================================================================

#include <time.h>

#include <iostream>
#include <fstream>
#include <assert.h>
#include "SpTraceVcd.h"

//=============================================================================
// SpTraceCallback

class SpTraceCallInfo {
protected:
    friend class SpTraceVcd;
    SpTraceCallback_t	m_initcb;	// Initalization Callback function
    SpTraceCallback_t	m_dumpcb;	// Dumping Callback function
    void*		m_userthis;	// Fake "this" for caller
    uint32_t		m_code;		// Starting code number
    SpTraceCallInfo (SpTraceCallback_t icb, SpTraceCallback_t dcb,
		     void* ut, uint32_t code)
	: m_initcb(icb), m_dumpcb(dcb), m_userthis(ut), m_code(code) {};
};

//=============================================================================
//=============================================================================
//=============================================================================
// Opening/Closing

void SpTraceVcd::open (const char* filename) {
    if (m_isOpen) return;
    m_filename = filename;
    openNext (m_rolloverMB!=0);

    m_fp << "$version Generated by SpTraceVcd $end" <<endl;
    time_t time_str = time(NULL);
    m_fp << "$date " << ctime(&time_str) << " $end" <<endl;
    m_fp << "$timescale 1ns/1ns $end" <<endl;
    
    definitions();
    for (uint32_t ent = 0; ent< m_callbacks.size(); ent++) {
	SpTraceCallInfo *cip = m_callbacks[ent];
	cip->m_code = nextCode();
	(cip->m_initcb) (this, cip->m_userthis, cip->m_code);
    }
    enddefinitions ();

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
	m_fp.open (m_filename.c_str());
    }
    m_fullDump = true;	// First dump must be full
}

void SpTraceVcd::close () {
    if (!m_isOpen) return;

    m_isOpen = false;
    m_fp.close();
}

void SpTraceVcd::printIndent (int level_change) {
    if (level_change<0) m_modDepth += level_change;
    assert(m_modDepth>=0);
    for (int i=0; i<m_modDepth; i++) m_fp<<" ";
    if (level_change>0) m_modDepth += level_change;
}

//=============================================================================
// Definitions

void SpTraceVcd::definitions () {
    assert (m_modDepth==0);
    printIndent(1);
    m_fp << "\n";
}

void SpTraceVcd::module (string name) {
    const char* curName = m_modName.c_str();
    const char* newName = name.c_str();

    // We detect the .'s in module names to determine
    // hiearchy.  This allows name() to be used inside
    // the module call.

    const char* cp = curName;
    const char* np = newName;
    for (; *np && (*np == *cp); np++, cp++) {
    }

    // Only allow split at hiearchy character
    while (np!=newName && *np && *np!='.') { np--; cp--; }
    if (*np=='.') np++;
    if (*cp=='.') cp++;

    for (; *cp; cp++) {
	if (cp[1]=='\0' || cp[1]=='.') {
	    printIndent(-1);
	    m_fp << "$upscope $end\n";
	}
    }

    while (*np) {
	printIndent(1);
	m_fp << "$scope module ";
	for (; *np && *np!='.'; np++) {
	    if (*np=='[') m_fp.put('(');
	    else if (*np==']') m_fp.put(')');
	    else m_fp.put(*np);
	}
	if (*np=='.') np++;
	m_fp << " $end\n";
    }

    m_modName = name;
}

//void SpTraceVcd::endmodule ()
//{
//}

void SpTraceVcd::declBit (uint32_t code, const char* name, int arraynum,
			  const uint32_t* valp)
{  declare (code, name, arraynum, valp, 0, 0, true); }
void SpTraceVcd::declBit (uint32_t code, const char* name, int arraynum,
			  const bool* valp)
{  declare (code, name, arraynum, (uint32_t*)valp, 0, 0, true); }
void SpTraceVcd::declBus (uint32_t code, const char* name, int arraynum,
			  const uint32_t* valp, int msb, int lsb)
{  declare (code, name, arraynum, valp, msb, lsb, false); }
void SpTraceVcd::declArray (uint32_t code, const char* name, int arraynum,
			    const uint32_t* valp, int msb, int lsb)
{  declare (code, name, arraynum, valp, msb, lsb, false); }

void SpTraceVcd::declare (uint32_t code, const char* name,
			  int arraynum,
			  const uint32_t* valp,
			  int msb, int lsb,
			  bool isBit)
{
    printIndent(0);

    // Stash info
    if (m_sigs.capacity() <= code
	|| m_sigs_oldval.capacity() <= code) {
	m_sigs.reserve(code*2);	// Power-of-2 allocation speeds things up
	m_sigs_oldval.reserve(code*2);
    }
    SpTraceVcdSig sig = SpTraceVcdSig(code, valp, (msb-lsb+1));
    m_sigs.push_back(sig);

    // Print reference
    m_fp << "$var wire "<<(msb-lsb+1)<<" ";
    printCode(code);
    m_fp << " " << name;
    if (arraynum>=0) {
	m_fp << "(" << arraynum << ")";
    }
    if (isBit) {
	m_fp << " $end\n";
    } else {
	m_fp << " ["<<msb<<":"<<lsb<<"] $end\n";
    }

    m_nextCode = max(nextCode(), code+1+int((msb-lsb+1)/32));
}

void SpTraceVcd::enddefinitions () {
    module("");

    printIndent(-1);
    m_fp << "$enddefinitions $end\n\n\n";
    assert (m_modDepth==0);
}

//=============================================================================
// Callbacks

void SpTraceVcd::addCallback (
    SpTraceCallback_t initcb, SpTraceCallback_t dumpcb,
    void* userthis)
{
    if (m_isOpen) {
	cerr << "%Error: SpTraceVcd::"<<__FUNCTION__<<" called with already open file\n";
	abort();
    }
    SpTraceCallInfo* vci = new SpTraceCallInfo(initcb, dumpcb, userthis, nextCode());
    m_callbacks.push_back(vci);
}

//=============================================================================
// Dumping

void SpTraceVcd::dumpFull (double timestamp) {
    dumpPrep (timestamp);
    for (uint32_t ent = 0; ent< m_sigs.size(); ent++) {
	uint32_t code = m_sigs[ent].m_code;
	int bits = m_sigs[ent].m_bits;
	const uint32_t* valp = m_sigs[ent].m_valp;
	if (bits==1) {
	    dumpValueBit  (code, *valp);
	} else if (bits<=32) {
	    dumpValueBus  (code, *valp, bits);
	} else {
	    dumpValueArray(code, valp, bits);
	}
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
    if (m_rolloverMB && (m_fp.tellp()/1e6 >= this->m_rolloverMB)) this->openNext(true);
    dumpPrep (timestamp);
    for (uint32_t ent = 0; ent< m_callbacks.size(); ent++) {
	SpTraceCallInfo *cip = m_callbacks[ent];
	(cip->m_dumpcb) (this, cip->m_userthis, cip->m_code);
    }
    dumpDone();
}

void SpTraceVcd::dumpPrep (double timestamp) {
    m_fp <<"#"<<((int)(timestamp))<<"\n";
}

void SpTraceVcd::dumpDone () {
}

//=============================================================================
// SpTraceVcd

const char* genId () {
    static char vcd_var_id_number[4] = {1,0,0,0};   /* one number for each ascii character */
    static char pistr[5];

    for(int i=0;i<4;i++){
	if (vcd_var_id_number[i]==0) pistr[i] = 0;
	else pistr[i] = (vcd_var_id_number[i]+32);
    }
    pistr[4] = 0;
    
    /* valid character from decimal 33 to 126 (space=32)*/
    vcd_var_id_number[0]++;
    for(int i=0;i<3;i++){
	if (vcd_var_id_number[i]>126){
	    vcd_var_id_number[i+1]++;
	    vcd_var_id_number[i] = 1;
	}
    }
    assert(vcd_var_id_number[3]<127);

    return (pistr);
}

//======================================================================
// Helper
#ifndef SPTRACEVCD_TEST
void SpTraceFile::write_comment (const sc_string &) {}
void SpTraceFile::trace (const bool &, const sc_string &) {}
void SpTraceFile::trace (const unsigned char &, const sc_string &, int) {}
void SpTraceFile::trace (const short unsigned int &, const sc_string &, int) {}
void SpTraceFile::trace (const unsigned int &, const sc_string &, int) {}
void SpTraceFile::trace (const long unsigned int &, const sc_string &, int) {}
void SpTraceFile::trace (const char &, const sc_string &, int) {}
void SpTraceFile::trace (const short int &, const sc_string &, int) {}
void SpTraceFile::trace (const int &, const sc_string &, int) {}
void SpTraceFile::trace (const long int &, const sc_string &, int) {}
void SpTraceFile::trace (const float &, const sc_string &) {}
void SpTraceFile::trace (const double &, const sc_string &) {}
void SpTraceFile::trace (const unsigned int &, const sc_string &, const char **) {}
#ifndef _SC_LITE_
void SpTraceFile::trace (const sc_bit &, const sc_string &) {}
void SpTraceFile::trace (const sc_logic &, const sc_string &) {}
void SpTraceFile::trace (const sc_bool_vector &, const sc_string &) {}
void SpTraceFile::trace (const sc_logic_vector &, const sc_string &) {}
void SpTraceFile::trace (const sc_signal_bool_vector &, const sc_string &) {}
void SpTraceFile::trace (const sc_signal_logic_vector &, const sc_string &) {}
void SpTraceFile::trace (const sc_uint_base &, const sc_string &) {}
void SpTraceFile::trace (const sc_int_base &, const sc_string &) {}
void SpTraceFile::trace (const sc_unsigned &, const sc_string &) {}
void SpTraceFile::trace (const sc_signed &, const sc_string &) {}
void SpTraceFile::trace (const sc_signal_resolved &, const sc_string &) {}
void SpTraceFile::trace (const sc_signal_resolved_vector &, const sc_string &) {}
void SpTraceFile::trace (const sc_bv_ns::sc_bv_base &, const sc_string &) {}
void SpTraceFile::trace (const sc_bv_ns::sc_lv_base &, const sc_string &) {}
#endif
#endif

//======================================================================

#if SPTRACEVCD_TEST
uint32_t v1, v2, s1, s2[3];
double timestamp = 1;

void dump (SpTraceVcd* vcdp, void* userthis, uint32_t code) {
    vcdp->dumpBus  (0x2, v1,5);
    vcdp->dumpBus  (0x3, v2,7);
    vcdp->dumpBit  (0x4, s1);
    vcdp->dumpArray(0x5, &s2[0], 38);
    // Note need to add 3 for next code.
}

void init (SpTraceVcd* vcdp, void* userthis, uint32_t code) {
    vcdp->module ("top");
     vcdp->declBus (0x2, "v1",-1,&v1, 5,1);
     vcdp->declBus (0x3, "v2",-1,&v2, 6,0);
     vcdp->module ("top.sub1");
      vcdp->declBit (0x4, "s1",-1,&s1);
     vcdp->module ("top.sub2");
      vcdp->declArray (0x5, "s2",-1,&s2[0], 40,3);
}

main() {
    v1 = v2 = s1 = 0;
    s2[0] = s2[1] = s2[2] = 0;
  
    SpTraceVcd* vcdp = new SpTraceVcd;
    vcdp->addCallback (&init, &dump, 0);
    vcdp->open ("test.dump");
  
    // Dumping
    vcdp->dump(timestamp++);
    v1 = 0xfff;
    vcdp->dump(timestamp++);
    v2 = 0x1;
    s2[1] = 2;
    vcdp->dump(timestamp++);
    vcdp->dump(timestamp++);
    vcdp->close();
}
#endif

//********************************************************************
// Local Variables:
// compile-command: "cd ../test_dir && g++ -DSPTRACEVCD_TEST ../src/SpTraceVcd.cpp -o SpTraceVcd && ./SpTraceVcd && cat test.dump"
// End:
