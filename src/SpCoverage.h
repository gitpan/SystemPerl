// $Revision: #6 $$Date: 2004/07/19 $$Author: ws150726 $ -*- SystemC -*-
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
// DESCRIPTION: Coverage analysis
//
//=============================================================================

#ifndef _VLCOVERAGE_H_
#define _VLCOVERAGE_H_ 1

#include <sys/types.h>	// uint32_t
#include <stdint.h>	// uint32_t

#include "SpFunctor.h"

//=============================================================================
// SpCoverage

class SpCoverage {
public:
    // GLOBAL METHODS
    // Write all coverage data to a file
    static void write (const char* filename = "logs/coverage.pl");
    // Called by write lower-level routines to log a single coverage statistic
    static void data (const char* hier, const char* what, const char* file, int lineno, const char* cmt, uint32_t data);
};

#endif // guard
