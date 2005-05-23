// $Revision: 1.2 $$Date: 2005-04-15 09:40:20 -0400 (Fri, 15 Apr 2005) $$Author: wsnyder $ -*- SystemC -*-
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
/// \brief SystemPerl common simple utilities, not requiring SystemC
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================

#ifndef _SPCOMMON_H_
#define _SPCOMMON_H_ 1

// Utilities here must NOT require SystemC headers!
//=============================================================================

/// Report SystemPerl internal error message and abort
#if defined(UERROR) && defined(UERROR_NL)
# define SP_ABORT(msg) { UERROR(msg); }
#else
# define SP_ABORT(msg) { cerr<<msg; abort(); }
#endif

//=============================================================================

#endif // guard
