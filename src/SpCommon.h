// $Revision: #1 $$Date: 2004/07/19 $$Author: ws150726 $ -*- SystemC -*-
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
// DESCRIPTION: SystemC common simple utilities, not requiring SystemC
//
//=============================================================================

#ifndef _SPCOMMON_H_
#define _SPCOMMON_H_ 1

// Utilities here must NOT require SystemC headers!
//=============================================================================

#if defined(UERROR) && defined(UERROR_NLN)
# define SP_ABORT(msg) { UERROR(msg); }
#else
# define SP_ABORT(msg) { cerr<<msg; abort(); }
#endif

//=============================================================================

#endif // guard
