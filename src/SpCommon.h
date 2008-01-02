// $Id: SpCommon.h 49154 2008-01-02 14:22:02Z wsnyder $ -*- SystemC -*-
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
/// \brief SystemPerl common simple utilities, not requiring SystemC
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================

#ifndef _SPCOMMON_H_
#define _SPCOMMON_H_ 1

// Utilities here must NOT require SystemC headers!

//=============================================================================
// Compiler pragma abstraction

#ifdef __GNUC__
# define SP_ATTR_PRINTF(fmtArgNum) __attribute__ ((format (printf, fmtArgNum, fmtArgNum+1)))
# define SP_ATTR_ALIGNED(alignment) __attribute__ ((aligned (alignment)))
# define SP_ATTR_NORETURN __attribute__ ((noreturn))
# define SP_ATTR_UNUSED __attribute__ ((unused))
# define SP_LIKELY(x)	__builtin_expect(!!(x), 1)
# define SP_UNLIKELY(x)	__builtin_expect(!!(x), 0)
#else
# define SP_ATTR_PRINTF(fmtArgNum)	///< Function with printf format checking
# define SP_ATTR_ALIGNED(alignment)	///< Align structure to specified byte alignment
# define SP_ATTR_NORETURN		///< Function does not ever return
# define SP_ATTR_UNUSED			///< Function that may be never used
# define SP_LIKELY(x)	(!!(x))		///< Boolean expression more often true than false
# define SP_UNLIKELY(x)	(!!(x))		///< Boolean expression more often false than true
#endif

//=============================================================================
/// Report SystemPerl internal error message and abort
#if defined(UERROR) && defined(UERROR_NL)
# define SP_ABORT(msg) { UERROR(msg); }
#else
# define SP_ABORT(msg) { cerr<<msg; abort(); }
#endif

#ifndef SP_ERROR_LN
/// Print error message and exit, redefine if you want something else...
# define SP_ERROR_LN(file,line,stmsg) { cout<<"%Error:"<<file<<":"<<dec<<line<<": "<<stmsg<<endl; abort();}
#endif
#ifndef SP_NOTICE_LN
/// Print notice message and non-exit, redefine if you want something else...
# define SP_NOTICE_LN(file,line,stmsg) { cout<<"%Notice:"<<file<<":"<<dec<<line<<": "<<stmsg<<endl; }
#endif

//=============================================================================

#endif // guard
