/* $Id: sp_log.h,v 1.13 2001/07/03 16:00:58 wsnyder Exp $
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
 * DESCRIPTION: SystemPerl: File logging, redirection of cout,cerr
 **********************************************************************
 */

#ifndef _SP_LOG_H_
#define _SP_LOG_H_ 1

#ifndef UTIL_ATTR_PRINTF
# ifdef __GNUC__
#  define UTIL_ATTR_PRINTF(fmtArgNum) __attribute__ ((format (printf, fmtArgNum, fmtArgNum+1)))
# else
#  define UTIL_ATTR_PRINTF(fmtArgNum) 
# endif
#endif

#include <stdio.h>

/* Some functions may be used by generic C compilers! */

#ifdef __cplusplus
extern "C" {
#endif

    /* Print to cout, but with C style arguments */
    extern void sp_log_printf(const char *format, ...) UTIL_ATTR_PRINTF(1);

#ifdef __cplusplus
}
#endif

//**********************************************************************

#ifdef __cplusplus

#include <iostream>
#include <fstream>
#include <string>

//**********************************************************************
// Echo a stream to two output streams, one to screen and one to a logfile

class sp_log_teebuf : public std::streambuf {
public:
    typedef int int_type;
    sp_log_teebuf(std::streambuf* sb1, std::streambuf* sb2):
	m_sb1(sb1),
	m_sb2(sb2)
	{}
    int_type overflow(int_type c) {
	if (m_sb1->sputc(c) == -1 || m_sb2->sputc(c) == -1)
	    return -1;
	return c;
    }
private:
    std::streambuf* m_sb1;
    std::streambuf* m_sb2;
};

//**********************************************************************
// Create a log file
//    Usage:
//
//	sp_log_file foo;
//	foo.open ("sim.log");
// or	sp_log_file foo ("sim.log");
//
//	foo.redirect();
//	cout << "this goes to screen and sim.log";
//
//    Eventually this will do logfile rollover also

class sp_log_file : public std::ofstream {
public:
    sp_log_file (void) :
	m_strmOldCout(NULL),
	m_strmOldCerr(NULL),
	m_isOpen(false)
	{};
    sp_log_file (const char *filename) :
	m_strmOldCout(NULL),
	m_strmOldCerr(NULL),
	m_isOpen(true)
	{ open(filename);}
    ~sp_log_file () { close();};
    
    void	open (const char* filename);	// Open the file
    void	open (const string filename) { open(filename.c_str()); };
    void	close (void);		// Close the file
    void	redirect_cout (void);	// Redirect cout and cerr to logfile
    void	end_redirect (void);	// End redirection

    static void	flush_all(void) { streambuf::flush_all(); }

    bool	isOpen() { return(m_isOpen); }	// Is the log file open?

private:
    streambuf*	m_strmOldCout;		// Old cout value
    streambuf*	m_strmOldCerr;		// Old cerr value
    bool	m_isOpen;		// File has been opened
    sp_log_teebuf* m_tee;		// Teeing structure
};

#endif /*__cplusplus*/
#endif /*_SP_LOG_H_*/
