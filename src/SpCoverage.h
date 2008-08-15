// $Id: SpCoverage.h 55774 2008-06-12 14:15:21Z wsnyder $ -*- SystemC -*-
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

#ifndef _SPCOVERAGE_H_
#define _SPCOVERAGE_H_ 1

#include <sys/types.h>	// uint32_t
#include <stdint.h>	// uint32_t
#include <iostream>
#include <sstream>
#include <string>

//=============================================================================
/// Insert a item for coverage analysis.
/// The first argument is a pointer to the count to be dumped.
/// The remaining arguments occur in pairs: A string key, and a value.
/// The value may be a string, or another type which will be auto-converted to a string.
///
/// Some typical keys:
///	filename	File the recording occurs in.  Defaults to __FILE__
///	lineno		Line number the recording occurs in.  Defaults to __LINE__
///	column		Column number (or occurrence# for dup file/lines).  Defaults to undef.
///	hier		Hierarchical name.  Defaults to name()
///	type		Type of coverage.  Defaults to "user"
///			Other types are 'block', 'fsm', 'toggle'.
///	comment		Description of the coverage event.  Should be set by the user.
///			Comments for type==block: 'if', 'else', 'elsif', 'case'
///	thresh		Threshold to consider fully covered.
///			If unspecified, downstream tools will determine it.
///
/// Examples:
///
///	SpZeroed<uint32_t> m_cases[10];
///	for (int i=0; i<10; i++) {
///		SP_COVER_INSERT(&m_cases[i], "comment", "Coverage Case", "i", cvtToNumStr(i));
///	}
#define SP_COVER_INSERT(countptr,args...) \
	SpCoverage::insert(spCoverItemCreate(countptr), "filename",__FILE__,  "lineno",__LINE__, \
			   "hier", name(), args)

//=============================================================================
//  SpCoverItem
///  SystemPerl coverage item base class
////
/// A single coverage statistic; template base class.
/// Users may derived from this, but it is generally used only by the SpCoverItem class.

class SpCoverageImpItem;

class SpCoverItem {
public:
    // METHODS
    virtual void dumpCount(std::ostream& os) const = 0;
protected:
    friend class SpCoverageImpItem;
    // CONSTRUCTORS
    SpCoverItem() {}
    virtual ~SpCoverItem() {}
};

/// SpCoverItem templated for a specific class
/// Creates a new coverage item for the specified type.
/// Generally, you'd use the SP_COVER_INSERT macro below, instead.
template <class T> class SpCoverItemSpec : public SpCoverItem {
private:
    // MEMBERS
    const T*	m_countp;	///< Count value
public:
    // METHODS
    virtual void dumpCount(std::ostream& os) const { os<<*m_countp; }
    // CONSRUCTORS
    SpCoverItemSpec(const T* countp) : m_countp(countp) {}
    virtual ~SpCoverItemSpec() {}
};

/// Template class to auto-construct SpCoverItem for passed type
template <class T>
inline const SpCoverItem* spCoverItemCreate(T* value) { return new SpCoverItemSpec<T>(value); }

//=============================================================================
//  SpCoverValue
/// Auto-convert SP_COVER_INSERT value arguments to strings

class SpCoverValue {
private:
    std::string m_s;
public:
    // Implicit conversion operators:
    template <class T> inline SpCoverValue (const T& t) {
	ostringstream os; os<<t; m_s = os.str();
    };
    inline SpCoverValue (const string& t) : m_s(t) {}
    inline SpCoverValue (const char* t) : m_s(t) {}
    ~SpCoverValue() {}
    // ACCESSORS
    const string* sp() const { return &m_s; }
};

typedef std::string SpCoverKey;

//=============================================================================
//  SpCoverage
///  SystemPerl coverage global class
////
/// Global class with methods affecting all coverage data.

class SpCoverage {
public:
    // GLOBAL METHODS
    /// Write all coverage data to a file
    static void write (const char* filename = "logs/coverage.pl");
#define A(n) const SpCoverKey& key ## n, const SpCoverValue& val ## n	// Argument list
#define C(n) key ## n, val ## n		// Calling argument list
#define N(n) "",SpCoverValue("")	// Null argument list
    /// Insert a coverage item
    /// We accept from 1-10 key/value pairs, all as strings.
    static void insert (const SpCoverItem* itemp, A(0))							{ insert(itemp,C(0),N(1),N(2),N(3),N(4),N(5),N(6),N(7),N(8),N(9)); }
    static void insert (const SpCoverItem* itemp, A(0),A(1))					  	{ insert(itemp,C(0),C(1),N(2),N(3),N(4),N(5),N(6),N(7),N(8),N(9)); }
    static void insert (const SpCoverItem* itemp, A(0),A(1),A(2))					{ insert(itemp,C(0),C(1),C(2),N(3),N(4),N(5),N(6),N(7),N(8),N(9)); }
    static void insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3))				  	{ insert(itemp,C(0),C(1),C(2),C(3),N(4),N(5),N(6),N(7),N(8),N(9)); }
    static void insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4))				{ insert(itemp,C(0),C(1),C(2),C(3),C(4),N(5),N(6),N(7),N(8),N(9)); }
    static void insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5))			{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),N(6),N(7),N(8),N(9)); }
    static void insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6))		  	{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),N(7),N(8),N(9)); }
    static void insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7))		{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),N(8),N(9)); }
    static void insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8))	 	{ insert(itemp,C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),N(9)); }
    static void insert (const SpCoverItem* itemp, A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9));
#undef A
#undef C
#undef N
    /// Clear coverage points (and call delete on all items)
    static void clear();
};

#endif // guard
