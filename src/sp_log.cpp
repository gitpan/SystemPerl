/* $Revision: #12 $$Date: 2002/11/06 $$Author: wsnyder $
 ************************************************************************
 *
 * THIS MODULE IS PUBLICLY LICENSED
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of either the GNU General Public License or the
 * Perl Artistic License.
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

void sp_log_file::open (const char *filename, int append) {
    // Open main logfile
    m_filename = filename;
    m_splitNum = 0;
    open_int(filename, append);
}

void sp_log_file::open_int (string filename, int append) {
    // Internal open, used also for split
    this->close();
    std::ofstream::open (filename.c_str(), append);
    m_isOpen = true;
}

//**********************************************************************
// Closing

void sp_log_file::close() {
    end_redirect();
    close_int();
}

void sp_log_file::close_int() {
    if (m_isOpen) {
	std::ofstream::close();
	m_isOpen = false;
    }
}

//**********************************************************************
// Split

void sp_log_file::split_now () {
    close_int();

    // We rename the first file, so it will be obvious we rolled.
    // This also has the nice effect of insuring downstream tools notice all revs.
    if (m_splitNum==0) {
	string newname = split_name(0);
	rename (m_filename.c_str(), newname.c_str());
	// We'll just ignore if there's an error with the rename
    }
    m_splitNum++;

    open_int(split_name(m_splitNum));
}

string sp_log_file::split_name (unsigned suffixNum) {
    string filename = m_filename;
    char rollnum[10];
    sprintf(rollnum, "_%03d", suffixNum);
    unsigned pos = filename.rfind(".log");
    if (pos == filename.length()-4) {
	// Foo.log -> Foo_###.log
	filename.erase(pos);
	filename = filename + rollnum + ".log";
    } else {
	// Foo -> Foo_###
	filename += rollnum;
    }
    return filename;
}

void sp_log_file::split_check () {
    if (isOpen() && m_splitSize && (tellp() > m_splitSize)) {
	split_now();
    }
}

//**********************************************************************
// Redirection

void sp_log_file::redirect_cout() {
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

void sp_log_file::end_redirect() {
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

extern "C" void sp_log_printf(const char *format, ...) {
    va_list ap;
    va_start (ap, format);
    std::cout.vform (format, ap);
}

//**********************************************************************

#ifdef SP_LOG_MAIN
//make -k stream && ./stream && echo "----" && cat sim.log
int main () {
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
