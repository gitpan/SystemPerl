// $Revision: #5 $$Date: 2004/01/27 $$Author: wsnyder $ -*- SystemC -*-
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

// The user is expected to declare this function's implementation themself
extern void sp_coverage_data (const char *hier, const char *what, const char *file, int lineno, uint32_t data);

#endif // guard
