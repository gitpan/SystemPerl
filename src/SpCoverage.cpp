// $Id: SpCoverage.cpp 61600 2008-09-24 13:36:36Z wsnyder $ -*- SystemC -*-
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
/// \brief SystemPerl Coverage analysis
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================

#include <cstdio>
#include <cstdarg>
#include <cstring>
#include <cassert>
#include "systemperl.h"
#include "SpCoverage.h"
#include "SpFunctor.h"

#include <map>
#include <deque>
#include <fstream>

//=============================================================================
// SpCoverageImplBase
/// Implementation base class for constants

struct SpCoverageImpBase {
    // TYPES
    enum { MAX_KEYS = 20 };		/// Maximum user arguments
    enum { KEY_UNDEF = 0 };		/// Magic key # for unspecified values
};

//=============================================================================
// SpCoverageImplItem
/// Implementation class for a SpCoverage item

class SpCoverageImpItem : SpCoverageImpBase {
public:
    // MEMBERS
    const SpCoverItem* m_itemp; 	///< Item containing count value
    int	m_keys[MAX_KEYS];		///< Key
    int	m_vals[MAX_KEYS];		///< Value for specified key
    // CONSTRUCTORS
    SpCoverageImpItem(const SpCoverItem* itemp) : m_itemp(itemp) {
	for (int i=0; i<MAX_KEYS; i++) m_keys[i]=KEY_UNDEF;
    }
    ~SpCoverageImpItem() {}
    void deleteItem() { if (m_itemp) { delete m_itemp; m_itemp=NULL; } }
};

//=============================================================================
// SpCoverageImp
/// Implementation class for SpCoverage.  See that class for public method information.
/// All value and keys are indexed into a unique number.  Thus we can greatly reduce
/// the storage requirements for otherwise identical keys.

class SpCoverageImp : SpCoverageImpBase {
private:
    // TYPES
    typedef map<string,int> ValueIndexMap;
    typedef map<int,string> IndexValueMap;
    typedef deque<SpCoverageImpItem> ItemList;

private:
    // MEMBERS
    ValueIndexMap	m_valueIndexes;		///< For each key/value a unique arbitrary index value
    IndexValueMap	m_indexValues;		///< For each key/value a unique arbitrary index value
    ItemList		m_items;		///< List of all items

    // CONSTRUCTORS
    SpCoverageImp() {}
public:
    ~SpCoverageImp() { clear(); }
    static SpCoverageImp& imp() {
	static SpCoverageImp s_singleton;
	return s_singleton;
    }

private:
    // PRIVATE METHODS
    int valueIndex(const string& value) {
	static int nextIndex = KEY_UNDEF+1;
	ValueIndexMap::iterator iter = m_valueIndexes.find(value);
	if (iter != m_valueIndexes.end()) return iter->second;
	nextIndex++;  assert(nextIndex>0);
	m_valueIndexes.insert(make_pair(value, nextIndex));
	m_indexValues.insert(make_pair(nextIndex, value));
	return nextIndex;
    }
    string dequote(const string& text) {
	// Remove any ' or newlines
	string rtn = text;
	for (string::iterator pos=rtn.begin(); pos!=rtn.end(); ++pos) {
	    if (*pos == '\'') *pos = '_';
	    if (*pos == '\n') *pos = '_';
	}
	return rtn;
    }
    bool numeric(const string& text) {
	// Remove any ' or newlines
	for (string::const_iterator pos=text.begin(); pos!=text.end(); ++pos) {
	    if (!isdigit(*pos)) return false;
	}
	return !text.empty();  // Empty string isn't numeric
    }
    bool legalKey(const string& key) {
	// Because we compress long keys to a single letter, and
	// don't want applications to either get confused if they use
	// a letter differently, nor want them to rely on our compression...
	// (Considered using numeric keys, but will remain back compatible.)
	if (key.length()<2) return false;
	if (key.length()==2 && isdigit(key[1])) return false;
	return true;
    }

    string shortKey(const string& key) {
	// Shorten keys so we get much smaller dumps
	// Note extracted from and compared with SystemC::Coverage::ItemKey
	// AUTO_EDIT_BEGIN_SystemC::Coverage::ItemKey
	if (key == "col0") return "c0";
	if (key == "col0_name") return "C0";
	if (key == "col1") return "c1";
	if (key == "col1_name") return "C1";
	if (key == "col2") return "c2";
	if (key == "col2_name") return "C2";
	if (key == "col3") return "c3";
	if (key == "col3_name") return "C3";
	if (key == "column") return "n";
	if (key == "comment") return "o";
	if (key == "count") return "c";
	if (key == "filename") return "f";
	if (key == "groupdesc") return "d";
	if (key == "groupname") return "g";
	if (key == "hier") return "h";
	if (key == "lineno") return "l";
	if (key == "per_instance") return "P";
	if (key == "row0") return "r0";
	if (key == "row0_name") return "R0";
	if (key == "row1") return "r1";
	if (key == "row1_name") return "R1";
	if (key == "row2") return "r2";
	if (key == "row2_name") return "R2";
	if (key == "row3") return "r3";
	if (key == "row3_name") return "R3";
	if (key == "table") return "T";
	if (key == "thresh") return "s";
	if (key == "type") return "t";
#define SP_CIK_COL0 "c0"
#define SP_CIK_COL0_NAME "C0"
#define SP_CIK_COL1 "c1"
#define SP_CIK_COL1_NAME "C1"
#define SP_CIK_COL2 "c2"
#define SP_CIK_COL2_NAME "C2"
#define SP_CIK_COL3 "c3"
#define SP_CIK_COL3_NAME "C3"
#define SP_CIK_COLUMN "n"
#define SP_CIK_COMMENT "o"
#define SP_CIK_COUNT "c"
#define SP_CIK_FILENAME "f"
#define SP_CIK_GROUPDESC "d"
#define SP_CIK_GROUPNAME "g"
#define SP_CIK_HIER "h"
#define SP_CIK_LINENO "l"
#define SP_CIK_PER_INSTANCE "P"
#define SP_CIK_ROW0 "r0"
#define SP_CIK_ROW0_NAME "R0"
#define SP_CIK_ROW1 "r1"
#define SP_CIK_ROW1_NAME "R1"
#define SP_CIK_ROW2 "r2"
#define SP_CIK_ROW2_NAME "R2"
#define SP_CIK_ROW3 "r3"
#define SP_CIK_ROW3_NAME "R3"
#define SP_CIK_TABLE "T"
#define SP_CIK_THRESH "s"
#define SP_CIK_TYPE "t"
	// AUTO_EDIT_END_SystemC::Coverage::ItemKey
	return key;
    }

    string keyValueFormatter (const string& key, const string& value) {
	string name;
	if (key.length()==1 && isalpha(key[0])) {
	    name += key;
	} else {
	    name += string("'")+dequote(key)+"'";
	}
	if (numeric(value)) {
	    name += string("=>")+value+",";
	} else {
	    name += string("=>'")+dequote(value)+"',";
	}
	return name;
    }

    string combineHier (const string& old, const string& add) {
	// (foo.a.x, foo.b.x) => foo.*.x
	// (foo.a.x, foo.b.y) => foo.*
	// (foo.a.x, foo.b)   => foo.*
	if (old == add) return add;
	if (old == "") return add;
	if (add == "") return old;

	const char* a = old.c_str();
	const char* b = add.c_str();

	// Scan forward to first mismatch
	const char* apre = a;
	const char* bpre = b;
	while (*apre == *bpre) { apre++; bpre++; }

	// We used to backup and split on only .'s but it seems better to be verbose
	// and not assume . is the separator
	string prefix = string(a,apre-a);

	// Scan backward to last mismatch
	const char* apost = a+strlen(a)-1;
	const char* bpost = b+strlen(b)-1;
	while (*apost == *bpost
	       && apost>apre && bpost>bpre) { apost--; bpost--; }

	// Forward to . so we have a whole word
	string suffix = *bpost ? string(bpost+1) : "";

	string out = prefix+"*"+suffix;

	//cout << "\nch pre="<<prefix<<"  s="<<suffix<<"\nch a="<<old<<"\nch b="<<add<<"\nch o="<<out<<endl;
	return out;
    }

    void selftest() {
	// Little selftest
	if (combineHier ("a.b.c","a.b.c")	!="a.b.c") SP_ABORT("%Error: selftest\n");
	if (combineHier ("a.b.c","a.b")		!="a.b*") SP_ABORT("%Error: selftest\n");
	if (combineHier ("a.x.c","a.y.c")	!="a.*.c") SP_ABORT("%Error: selftest\n");
	if (combineHier ("a.z.z.z.c","a.b.c")	!="a.*.c") SP_ABORT("%Error: selftest\n");
	if (combineHier ("z","a")		!="*") SP_ABORT("%Error: selftest\n");
	if (combineHier ("q.a","q.b")		!="q.*") SP_ABORT("%Error: selftest\n");
	if (combineHier ("q.za","q.zb")		!="q.z*") SP_ABORT("%Error: selftest\n");
	if (combineHier ("1.2.3.a","9.8.7.a")	!="*.a") SP_ABORT("%Error: selftest\n");
    }

public:
    // PUBLIC METHODS
    void clear() {
	for (ItemList::iterator it=m_items.begin(); it!=m_items.end(); ++it) {
	    SpCoverageImpItem& item = *(it);
	    item.deleteItem();
	}
	m_items.clear();  // Also deletes m_itemp's via ~SpCoverageImpItem
	m_indexValues.clear();
	m_valueIndexes.clear();
    }

    void insert (const SpCoverItem* itemp,
		 const string* keyps[MAX_KEYS],
		 const string* valps[MAX_KEYS]) {
	SpCoverageImpItem item (itemp);

	// Zero out empty keys and discover if there's a column field
	string empty; // Note take pointer to this, though finished with it at end of function
	for (int i=0; i<MAX_KEYS; i++) {
	    const string& key = *keyps[i];
	    if (key!="") {
		for (int j=i+1; j<MAX_KEYS; j++) {
		    if (key == *keyps[j]) {  // Duplicate key.  Keep the last one
			keyps[i] = &empty;
			break;
		    }
		}
	    }
	}

	// Insert the values
	int addKeynum=0;
	for (int i=0; i<MAX_KEYS; i++) {
	    const string& key = *keyps[i];
	    const string& val = *valps[i];
	    if (key!="") {
		item.m_keys[addKeynum] = valueIndex(key);
		item.m_vals[addKeynum] = valueIndex(val);
		addKeynum++;
		if (!legalKey(key)) {
		    SP_ABORT("%Error: Coverage keys of one character, or letter+digit are illegal: "<<key);
		}
	    }
	}

	m_items.push_back(item);
    }

    void write (const char* filename) {
#ifndef SP_COVERAGE
	SP_ABORT("%Error: Called SpCoverage::write when SP_COVERAGE disabled\n");
#endif
	selftest();

	ofstream os (filename);
	if (os.fail()) {
	    SP_ABORT("%Error: Can't Write "<<filename<<endl);
	    return;
	}
	os << "# SystemC::Coverage-1 -*- Mode:perl -*-\n";

	// Build list of events; totalize if collapsing hierarchy
	typedef map<string,pair<string,uint64_t> >	EventMap;
	EventMap	eventCounts;
	for (ItemList::iterator it=m_items.begin(); it!=m_items.end(); ++it) {
	    SpCoverageImpItem& item = *(it);
	    string name;
	    string hier;
	    bool per_instance = false;

	    for (int i=0; i<MAX_KEYS; i++) {
		if (item.m_keys[i] != KEY_UNDEF) {
		    string key = shortKey(m_indexValues[item.m_keys[i]]);
		    string val = m_indexValues[item.m_vals[i]];
		    if (key == SP_CIK_PER_INSTANCE) {
			if (val != "0") per_instance = true;
		    }
		    if (key == SP_CIK_HIER) {
			hier = val;
		    } else {
			// Print it
			name += keyValueFormatter(key,val);
		    }
		}
	    }
	    if (per_instance) {  // Not collapsing hierarchies
		name += keyValueFormatter(SP_CIK_HIER,hier);
		hier = "";
	    }

	    // Group versus point labels don't matter here, downstream deals with it.
	    // Seems bad for sizing though and doesn't allow easy addition of new group codes (would be inefficient)

	    // Find or insert the named event
	    EventMap::iterator cit = eventCounts.find(name);
	    if (cit != eventCounts.end()) {
		const string& oldhier = cit->second.first;
		cit->second.second += item.m_itemp->count();
		cit->second.first  = combineHier(oldhier, hier);
	    } else {
		eventCounts.insert(make_pair(name, make_pair(hier,item.m_itemp->count())));
	    }
	}

	// Output body
	for (EventMap::iterator it=eventCounts.begin(); it!=eventCounts.end(); ++it) {
	    os<<"inc("<<dec;
	    os<<it->first;
	    if (it->second.first != "") os<<keyValueFormatter(SP_CIK_HIER,it->second.first);
	    os<<"c=>"<<it->second.second;
	    os<<");"<<endl;
	}

	// End
	os << "\n1;\n";	// OK exit status for perl
    }
};

//=============================================================================
// SpCoverage

void SpCoverage::clear() {
    SpCoverageImp::imp().clear();
}

void SpCoverage::write (const char* filename) {
    SpCoverageImp::imp().write(filename);
}

#define A(n) const SpCoverKey& key ## n, const SpCoverValue& val ## n	// Argument list
#define C(n) key ## n, val ## n	// Calling argument list
#define N(n) "",SpCoverValue("")	// Null argument list
void SpCoverage::insert (const SpCoverItem* itemp,
			 A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),
			 A(10),A(11),A(12),A(13),A(14),A(15),A(16),A(17),A(18),A(19)) {
    // We add one extra slot to the below so we can insert a string for the column number
    string empty;
    const string* keyps[SpCoverageImpBase::MAX_KEYS]
	= {&key0,&key1,&key2,&key3,&key4,&key5,&key6,&key7,&key8,&key9,
	   &key10,&key11,&key12,&key13,&key14,&key15,&key16,&key17,&key18,&key19};
    const string* valps[SpCoverageImpBase::MAX_KEYS]
	= {val0.sp(),val1.sp(),val2.sp(),val3.sp(),val4.sp(),val5.sp(),val6.sp(),val7.sp(),val8.sp(),val9.sp(),
	   val10.sp(),val11.sp(),val12.sp(),val13.sp(),val14.sp(),val15.sp(),val16.sp(),val17.sp(),val18.sp(),val19.sp()};
    SpCoverageImp::imp().insert(itemp, keyps, valps);
}

// And versions with fewer arguments  (oh for a language with named parameters!)
void SpCoverage::insert (const SpCoverItem* itemp, A(0))
{ insert(itemp,C(0),N(1),N(2),N(3),N(4),N(5),N(6),N(7),N(8),N(9),
	 N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1))
{ insert(itemp,C(0),C(1),N(2),N(3),N(4),N(5),N(6),N(7),N(8),N(9),
	 N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2))
{ insert(itemp,C(0),C(1),C(2),N(3),N(4),N(5),N(6),N(7),N(8),N(9),
	 N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3))
{ insert(itemp,C(0),C(1),C(2),C(3),N(4),N(5),N(6),N(7),N(8),N(9),
	 N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),N(5),N(6),N(7),N(8),N(9),
	 N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),N(6),N(7),N(8),N(9),
	 N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),N(7),N(8),N(9),
	 N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),N(8),N(9),
	 N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),N(9),
	 N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	 N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),A(10))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	 C(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),A(10),A(11))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	 C(10),C(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),A(10),A(11),A(12))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	 C(10),C(11),C(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),A(10),A(11),A(12),A(13))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	 C(10),C(11),C(12),C(13),N(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),A(10),A(11),A(12),A(13),A(14))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	 C(10),C(11),C(12),C(13),C(14),N(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),A(10),A(11),A(12),A(13),A(14),A(15))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	 C(10),C(11),C(12),C(13),C(14),C(15),N(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),A(10),A(11),A(12),A(13),A(14),A(15),A(16))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	 C(10),C(11),C(12),C(13),C(14),C(15),C(16),N(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),A(10),A(11),A(12),A(13),A(14),A(15),A(16),A(17))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	 C(10),C(11),C(12),C(13),C(14),C(15),C(16),C(17),N(18),N(19)); }
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),A(10),A(11),A(12),A(13),A(14),A(15),A(16),A(17),A(18))
{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	 C(10),C(11),C(12),C(13),C(14),C(15),C(16),C(17),C(18),N(19)); }
#undef A
#undef C
#undef N
