/* $Id: scparse.h,v 1.6 2001/03/29 22:53:37 wsnyder Exp $
 ******************************************************************************
 * DESCRIPTION: SystemC parser header file
 * 
 * This file is part of SystemC-Perl.  
 * 
 * Author: Wilson Snyder <wsnyder@wsnyder.org>
 * 
 * Code available from: http://veripool.com/systemc-perl
 * 
 ******************************************************************************
 * 
 * This program is Copyright 2001 by Wilson Snyder.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of either the GNU General Public License or the
 * Perl Artistic License, with the exception that it cannot be placed
 * on a CD-ROM or similar media for commercial distribution without the
 * prior approval of the author.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * If you do not have a copy of the GNU General Public License write to
 * the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
 * MA 02139, USA.
 *									     
 *****************************************************************************/

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

/* Can't include perl... It's lexer will conflict */

/* Utilities */
#define DENULL(s) ((s)?(s):"NULL")

/* Common state between lex/yacc/scparser */
/* State only scparser needs is in ScParserState */
typedef struct {
    int lineno;
    const char *filename;
    int stripAutos;
    char *enumname;
} ScParserLex_t ;
extern ScParserLex_t ScParserLex;

/* Lexer */
extern FILE *sclexin;
extern int sclexlex();
extern char *sclextext;
#ifdef SCPARSE_C
ScParserLex_t ScParserLex;
#endif

/* Yacc */
extern void scgrammererror(const char *s);
extern int scgrammerlex();
extern int scgrammerparse(void);

/* Parser.xs */
extern int scparse (const char *filename);
extern void scparser_PrefixCat (char *text, int len);
extern void scparser_EmitPrefix (void);
extern void scparser_call (int params, const char *method, ...);
