// $Id: SpCoverage.cpp 4305 2005-08-02 13:21:57Z wsnyder $ -*- SystemC -*-
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
/// \brief SystemPerl Coverage analysis
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================

#include <stdio.h>
#include "systemperl.h"
#include "SpCoverage.h"
#include "SpFunctor.h"

static FILE* sp_Coverage_Fp = NULL;	///< Internal file pointer being written to

//=============================================================================
// SpFunctorNamed

void SpCoverage::write (const char* filename) {
    sp_Coverage_Fp = fopen(filename,"w");
    if (!sp_Coverage_Fp) { SP_ABORT("%Error: Can't Write "<<filename<<endl); }
    fprintf(sp_Coverage_Fp,"use SystemC::Coverage;\n\n");
    // Body
    SpFunctorNamed::call("coverageWrite");
    // coverageWrite functions will call SpCoverage::data on all SP_COVERAGE statements
    // End
    fprintf(sp_Coverage_Fp,"\n1;\n");	// OK exit status for perl
    fclose(sp_Coverage_Fp);
}

void SpCoverage::data (const char* hier, const char* what, const char* file, int lineno,
		       const char* cmt, uint32_t data) {
    // Called by coverageWrite functions
    if (!hier[0]) hier = "NONE";
    fprintf(sp_Coverage_Fp,"covline('%s','%s','%s',%d,'%s',%6d);\n",
	    what,hier,file,lineno,cmt,data);
}

