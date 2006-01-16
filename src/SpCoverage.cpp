// $Id: SpCoverage.cpp 11992 2006-01-16 18:59:58Z wsnyder $ -*- SystemC -*-
//=============================================================================
//
// THIS MODULE IS PUBLICLY LICENSED
//
// Copyright 2001-2006 by Wilson Snyder.  This program is free software;
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

#include <stdio.h>
#include <stdarg.h>
#include <assert.h>
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
    enum { MAX_KEYS = 10 };	/// Maximum user arguments
    enum { KEY_UNDEF=0 };		/// Magic key # for unspecified values
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
    ~SpCoverageImp() {}
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
public:
    // PUBLIC METHODS
    void insert (const SpCoverItem* itemp,
		 const string* keyps[MAX_KEYS],
		 const string* valps[MAX_KEYS]) {
	SpCoverageImpItem item (itemp);

	// Zero out empty keys and discover if there's a column field
	string empty;
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
	    }
	}

	m_items.push_back(item);
    }
    void write (const char* filename) {

	ofstream os (filename);
	if (os.fail()) {
	    SP_ABORT("%Error: Can't Write "<<filename<<endl);
	    return;
	}
	os << "use SystemC::Coverage;\n\n";

	// Body
	for (ItemList::iterator it=m_items.begin(); it!=m_items.end(); ++it) {
	    os<<"inc("<<dec;
	    SpCoverageImpItem& item = *(it);
	    for (int i=0; i<MAX_KEYS; i++) {
		if (item.m_keys[i] != KEY_UNDEF) {
		    string key = m_indexValues[item.m_keys[i]];
		    // Shorten keys so we get much smaller dumps
		    if (key == "filename")	key = "f";
		    else if (key == "hier")	key = "h";
		    else if (key == "lineno")	key = "l";
		    else if (key == "column")	key = "n";
		    else if (key == "comment")	key = "o";
		    else if (key == "type")	key = "t";
		    else if (key == "threash")	key = "s";
		    else key = "'"+key+"'";
		    // Print it
		    os<<key;
		    os<<"=>'"<<m_indexValues[item.m_vals[i]]<<"',";
		}
	    }
	    os<<"c=>"; item.m_itemp->dumpCount(os);
	    os<<");"<<endl;
	}

	// End
	os << "\n1;\n";	// OK exit status for perl
    }
};

//=============================================================================
// SpCoverage

void SpCoverage::write (const char* filename) {
    SpCoverageImp::imp().write(filename);
}

#define A(n) const SpCoverKey& key ## n, const SpCoverValue& val ## n	// Argument list
#define C(n) key ## n, val ## n	// Calling argument list
void SpCoverage::insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9)) {
    // We add one extra slot to the below so we can insert a string for the column number
    string empty;
    const string* keyps[SpCoverageImpBase::MAX_KEYS]
	= {&key0,&key1,&key2,&key3,&key4,&key5,&key6,&key7,&key8,&key9};
    const string* valps[SpCoverageImpBase::MAX_KEYS]
	= {val0.sp(),val1.sp(),val2.sp(),val3.sp(),val4.sp(),val5.sp(),val6.sp(),val7.sp(),val8.sp(),val9.sp()};
    SpCoverageImp::imp().insert(itemp, keyps, valps);
}
#undef A
#undef C
