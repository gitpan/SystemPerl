/* $Id: sp_log.cpp,v 1.7 2001/05/29 19:19:34 wsnyder Exp $
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

#include <cstdarg>

#include "sp_log.h"

//**********************************************************************
// Opening

void sp_log_file::open (const char *filename)
    /* Open main logfile */
{
    this->close();
    std::ofstream::open (filename);
    if (0/*FIX*/) {
	//UTIL_FATAL("Can't write %s\n", filename);
	printf ("Can't write %s\n", filename);
	return;
    }
    m_isOpen = true;
}

//**********************************************************************
// Closing

void sp_log_file::close (void)
{
    if (m_isOpen) {
	end_redirect();
	std::ofstream::close();
	m_isOpen = false;
    }
}

//**********************************************************************
// Redirection

void sp_log_file::redirect_cout (void)
{
    if (m_strmOldCout) {
	end_redirect();
    }
    m_tee = new sp_log_teebuf (std::cout.rdbuf(), rdbuf());

    // Save old
    m_strmOldCout = std::cout.rdbuf();
    m_strmOldCerr = std::cerr.rdbuf();
    // Redirect
    std::cout.rdbuf (m_tee);
    std::cerr.rdbuf (m_tee);
}

void sp_log_file::end_redirect (void)
{
    if (m_strmOldCout) {
	std::cout.rdbuf (m_strmOldCout);
	std::cerr.rdbuf (m_strmOldCerr);
	m_strmOldCout = NULL;
	m_strmOldCerr = NULL;
	delete (m_tee);
    }
}

//**********************************************************************
// C compatibility

extern "C" void sp_log_printf(const char *format, ...)
{
    va_list ap;
    va_start (ap, format);
    std::cout.vform (format, ap);
}

//**********************************************************************

#ifdef SP_LOG_MAIN
//make -k stream && ./stream && echo "----" && cat sim.log
int main ()
{
    sp_log_file simlog ("sim.log");
//    sp_log_file simlog;
//    simlog.open ("sim.log");
    simlog << "Hello simlog!\n";

    simlog.redirect_cout ();
    sp_log_printf ("%s", "Hello C\n");
    cout << "Hello C++\n";
}
#endif

//g++ -DSP_LOG_MAIN sp_log.cpp ; ./a.out && cat sim.log
