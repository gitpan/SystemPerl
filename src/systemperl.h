/* $Id: systemperl.h,v 1.9 2001/05/18 17:25:03 wsnyder Exp $
 ************************************************************************
 *
 * THIS MODULE IS PUBLICLY LICENSED
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of either the GNU General Public License or the
 * Perl Artistic License, with the exception that it cannot be placed
 * on a CD-ROM or similar media for commercial distribution without the
 * prior approval of the author.
 *
 * This is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this module; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 **********************************************************************
 * DESCRIPTION: SystemPerl: Overall header file
 **********************************************************************
 */

#ifndef _SYSTEMPERL_H_
#define _SYSTEMPERL_H_

/* Necessary includes */
#include <ostream.h>	// For AUTOENUM
#ifdef SYSTEMC_LESSER
#include <systemc_lesser.h>
#else
#include <systemc.h>
#endif

/**********************************************************************/
/* Macros */

// Allows constructor to be in implementation rather then the header
#define SP_CTOR_IMP(name) name::name(sc_module_name)

// Declaration cell that SP can understand
#define SP_CELL_DECL(type,instname) type *instname

// Instantiation of a cell that SP can understand
#define SP_CELL(instname,type) (instname = new type (# instname))

// Instantiation of a cell that SP can understand
// Allocate using a formatted name
#define SP_CELL_FORM(instname,type,format...) \
	(instname = new type (sp_cell_sprintf(format)))

// Connection of a pin that SP can understand
#define SP_PIN(instname,port,net) (instname->port(net))

/**********************************************************************/
// Functions
// We'll ask systemC to have a sc_string creator to avoid this:
// Note there is a mem leak here.  As only used for instance names, we'll live.
inline const char *sp_cell_sprintf(const char *fmt...) {
    char* buf = new char[strlen(fmt) + 20];
    va_list ap; va_start(ap,fmt); vsprintf(buf,fmt,ap); va_end(ap);
    return(buf);
}

/**********************************************************************/
/* sp_log.h has whole thing... This one function may be used everywhere */

#ifndef UTIL_ATTR_PRINTF
# ifdef __GNUC__
#  define UTIL_ATTR_PRINTF(fmtArgNum) __attribute__ ((format (printf, fmtArgNum, fmtArgNum+1)))
# else
#  define UTIL_ATTR_PRINTF(fmtArgNum) 
# endif
#endif

extern "C" {
    /* Print to cout, but with C style arguments */
    extern void sp_log_printf(const char *format, ...) UTIL_ATTR_PRINTF(1);
}

/**********************************************************************/

#endif /*_SYSTEMPERL_H_*/
