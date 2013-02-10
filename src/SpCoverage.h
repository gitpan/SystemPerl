// -*- mode: C++; c-file-style: "cc-mode" -*-
//=============================================================================
//
// THIS MODULE IS PUBLICLY LICENSED
//
// Copyright 2001-2013 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.
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

// Note cannot include systemperl.h, or we won't work with non-SystemC compiles
#include "SpCommon.h"
#include <iostream>
#include <sstream>
#include <string>

#define SPCOVERAGE_VERSION 1341	// Version number of this file AS_AN_INTEGER
using namespace std;

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

#define _SP_STRINGIFY(x) (# x)
#define _SP_STRINGIFY2(x) (_SP_STRINGIFY(x))
#define SP_COVER_INSERT(countp,args...) \
    SP_IF_COVER(SpCoverage::_inserti(countp);	\
		SpCoverage::_insertf(__FILE__,__LINE__);	\
		SpCoverage::_insertp("hier", name(), args))

//=============================================================================
/// Convert SP_COVER_INSERT value arguments to strings

template< class T> std::string spCvtToStr (const T& t) {
    ostringstream os; os<<t; return os.str();
}

/// Usage: something(SpCvtToCStr(i))
/// Note the pointer will only be valid for as long as the object remains
/// in scope!
struct SpCvtToCStr {
    string m_str;
    // Casters
    template< class T> SpCvtToCStr (const T& t) {
	ostringstream os; os<<t; m_str=os.str();
    }
    ~SpCvtToCStr() {}
    operator const char* () const { return m_str.c_str(); };
};

//=============================================================================
//  SpCoverage
///  SystemPerl coverage global class
////
/// Global class with methods affecting all coverage data.

class SpCoverage {
public:
    // GLOBAL METHODS
    /// Write all coverage data to a file
    static void write (const char* filenamep = "logs/coverage.pl");
    /// Insert a coverage item
    /// We accept from 1-30 key/value pairs, all as strings.
    /// Call _insert1, followed by _insert2 and _insert3
    /// Do not call directly; use SP_COVER_INSERT or higher level macros instead
    // _insert1: Remember item pointer with count.  (Not const, as may add zeroing function)
    static void _inserti (uint32_t* itemp);
    static void _inserti (uint64_t* itemp);
    // _insert1 Zeroed: We can ignore the fact that it is a pre-zeroed class; same layout as base type
    static void _inserti (SpZeroed<uint32_t>* itemp) { _inserti((uint32_t*)itemp); }
    static void _inserti (SpZeroed<uint64_t>* itemp) { _inserti((uint64_t*)itemp); }
    // _insert2: Set default filename and line number
    static void _insertf (const char* filename, int lineno);
    // _insert3: Set parameters
    // We could have just the maximum argument version, but this compiles
    // much slower (nearly 2x) than having smaller versions also.  However
    // there's not much more gain in having a version for each number of args.
#define K(n) const char* key ## n
#define A(n) const char* key ## n, const char* valp ## n	// Argument list
#define D(n) const char* key ## n = NULL, const char* valp ## n = NULL	// Argument list
    static void _insertp (D(0),D(1),D(2),D(3),D(4),D(5),D(6),D(7),D(8),D(9));
    static void _insertp (A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9)
			  ,A(10),D(11),D(12),D(13),D(14),D(15),D(16),D(17),D(18),D(19));
    static void _insertp (A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9)
			  ,A(10),A(11),A(12),A(13),A(14),A(15),A(16),A(17),A(18),A(19)
			  ,A(20),D(21),D(22),D(23),D(24),D(25),D(26),D(27),D(28),D(29));
    // Backward compatibility for Verilator
    static void _insertp (A(0), A(1),  K(2),int val2,  K(3),int val3,
			  K(4),const string& val4,  A(5),A(6));

#undef K
#undef A
#undef D
    /// Clear coverage points (and call delete on all items)
    static void clear();
    /// Clear items not matching the provided string
    static void clearNonMatch (const char* matchp);
    /// Zero coverage points
    static void zero();
};

#endif // guard
