%option noyywrap align never-interactive prefix="sclex"
%{
/* $Id: sclex.l,v 1.12 2001/04/03 21:26:05 wsnyder Exp $
 ******************************************************************************
 * DESCRIPTION: SystemC lexer
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

#include "scparse.h"
#include "scgrammer.h"

YYSTYPE scgrammerlval;
#define yylval scgrammerlval

#define LINENO (ScParserLex.lineno)
#define StashPrefix { scparser_PrefixCat (yytext, yyleng); }

extern void sclex_ppline (const char *line);

/**********************************************************************/
%}

%x AUTOMODE
%x CMTMODE
%x STRMODE

WHITESPACE	[ \t\r\f]
NEWLINE		[\n]
QUOTE		["]
SYMBOL		[a-zA-Z_][a-zA-Z0-9_$]*
DECNUM		[0-9]+U?L?L?
BASENUM		0x[0-9a-fA-F_]+U?L?L?
FLOATNUM	[0-9]+"."*[0-9]*[eE][0-9]+

	/**************************************************************/
%%

"#line".*\n	{ scparser_EmitPrefix(); sclex_ppline(yytext); }
"#sp".*\n	{ LINENO++; return(SP); }
"#include"	{ return(PP); }

	/* Special macros we recognise */
"SC_MODULE"	{ return(SC_MODULE); }
[S][PC]"_CELL"	{ return(SP_CELL); }
[S][PC]"_PIN"	{ return(SP_PIN); }
"SC_CTOR"	{ return(SC_CTOR); }
"enum"		{ return(ENUM); }

"sc_signal"	|
"sc_in"		|
"sc_out"	|
"sc_inout"	{ yylval.string = strdup(yytext); return(SC_SIGNAL); }

"sc_in_clk"	|
"sc_out_clk"	|
"sc_inout_clk"	{ yylval.string = strdup(yytext); return(SC_INOUT_CLK); }

"sc_clock"	{ yylval.string = strdup(yytext); return(SC_SIGNAL_CLK); }

	/* Automatic comments */
{WHITESPACE}+"// Beginning of SystemPerl automatic".*\n	{
	if (ScParserLex.stripAutos) {BEGIN(AUTOMODE); scparser_EmitPrefix();}
	else { StashPrefix; }
	LINENO++;}
{WHITESPACE}+"/*AUTO"[^*]+"*/"	{ return(AUTO); }
<<EOF>>			{ yyleng=0; yyterminate(); }/*else get null added to EOF*/

	/* Generics */
{NEWLINE}      	{ StashPrefix; LINENO++; }
{WHITESPACE}+	{ StashPrefix; }
"//".*[\n]     	{ StashPrefix; LINENO++; }
{QUOTE}		{ BEGIN(STRMODE); yymore(); }
"/*"	       	{ BEGIN(CMTMODE); StashPrefix; }

{SYMBOL}      		{ yylval.string = strdup(yytext); return(SYMBOL); }
{DECNUM}|{BASENUM}|{FLOATNUM}  	{ return(NUMBER); }
.	       		{ return(yytext[yyleng-1]); }

	/************/
	/* Comment */
<CMTMODE>"*"+[^*/\n]* 	{ StashPrefix; }
<CMTMODE>\n		{ StashPrefix; LINENO++; }
<CMTMODE>"*"+"/"	{ StashPrefix; BEGIN(INITIAL); }
<CMTMODE>. 		{ StashPrefix; }

	/************/
	/* Strings */
<STRMODE>\n		{ LINENO++; yymore(); /* Unterminated error */ }
<STRMODE>\\.		{ yymore(); }
<STRMODE>[^"\\\n]*	{ yymore(); }
<STRMODE>{QUOTE}	{ BEGIN(INITIAL); if (0) yy_c_buf_p--; return STRING; }

	/************/
	/* In Automatic */
<AUTOMODE>\n		{ LINENO++; yymore(); }
<AUTOMODE>"// End of SystemPerl automatic".*\n	{LINENO++; BEGIN(INITIAL); }
<AUTOMODE>.	 	{ yymore(); }

	/**************************************************************/
%%

void sclex_ppline (const char *line) {
    /* Passed string which looks like #line {##} "{filename}" */
    if (0==strncmp ("#line",line,5)) { line += 5; }
    while (*line && isspace(*line)) line++;

    if (isdigit (*line)) {
	ScParserLex.lineno = atoi(line);
	while (*line && isdigit(*line)) line++;
	while (*line && isspace(*line)) line++;
	if (*line == '"') {
	    char *cp;
	    line++;
	    free((void*)ScParserLex.filename);
	    ScParserLex.filename = strdup(line);
	    if (NULL!=(cp=strchr(ScParserLex.filename, '"'))) *cp = '\0';
	}
    }
}

/*###################################################################
 * Local Variables:
 * mode: C
 * End:
 */
