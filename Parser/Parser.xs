#/* SystemC.xs -- SystemC Booter  -*- Mode: C -*-
#* $Id: Parser.xs,v 1.10 2001/04/03 21:26:05 wsnyder Exp $
#*********************************************************************
#*
#* Vl SystemC perl utility library
#* 
#* Author: Wilson Snyder <wsnyder@wsnyder.org> or <wsnyder@iname.com>
#* 
#* Code available from: http://veripool.com/vl
#* 
#*********************************************************************
#* 
#* This file is covered by the GNU public licence.
#* 
#* Vl is free software; you can redistribute it and/or modify
#* it under the terms of the GNU General Public License as published by
#* the Free Software Foundation; either version 2, or (at your option)
#* any later version.
#* 
#* Vl is distributed in the hope that it will be useful,
#* but WITHOUT ANY WARRANTY; without even the implied warranty of
#* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#* GNU General Public License for more details.
#* 
#* You should have received a copy of the GNU General Public License
#* along with Vl; see the file COPYING.  If not, write to
#* the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#* Boston, MA 02111-1307, USA.
#* 
#***********************************************************************/

/* Mine: */
#define SCPARSE_C
#include "scparse.h"

/* Perl */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#/**********************************************************************/

static struct {		/*Eventually a C++ class?? */
    SV* self;		/* Class called from */
    int Errors;		/* Number of errors encountered */

    struct {
	SV* SVPrefix;	/* Commentary before the next token */
	int lineno;	/* Starting linenumber of above text */
    } Prefix;

    int LastLineno;	/* Linenumber of last tolken sent to call back */
} ScParserState;


#/**********************************************************************/

void scparser_set_line (int lineno) {
    ScParserState.LastLineno = lineno;
}

void scparser_PrefixCat (char *text, int len)
{
    /* Add comments and other stuff to text that we can just save for later */
    if (!ScParserState.Prefix.SVPrefix) {
	ScParserState.Prefix.SVPrefix = newSVpvn (text, len);
	ScParserState.Prefix.lineno = ScParserLex.lineno;
    } else {
	sv_catpvn (ScParserState.Prefix.SVPrefix, text, len);
    }
}

void scparser_EmitPrefix (void)
{
    /* Call $self->text(text_received) */
    scparser_set_line (ScParserState.Prefix.lineno);
    if (ScParserState.Prefix.SVPrefix) {
	/* Emit text in prefix */
	{
	    dSP;			/* Initialize stack pointer */
	    ENTER;			/* everything created after here */
	    SAVETMPS;			/* ...is a temporary variable. */
	    PUSHMARK(SP);		/* remember the stack pointer */
	    XPUSHs(ScParserState.self);	/* $self-> */
	    XPUSHs(ScParserState.Prefix.SVPrefix);	/* prefix */
	    PUTBACK;			/* make local stack pointer global */
	    perl_call_method ("text", G_DISCARD | G_VOID);
	    FREETMPS;			/* free that return value */
	    LEAVE;			/* ...and the XPUSHed "mortal" args.*/
	}
	/* Not a memory leak; perl will free the SV when done with it */
	ScParserState.Prefix.SVPrefix = NULL;
    }
}

void scparser_call (
    int params,		/* Number of parameters.  Negative frees the parameters */
    const char *method,	/* Name of method to call */
    ...)		/* Arguments to pass to method's @_ */
{
    /* Call $self->auto (passedparam1, parsedparam2) */
    int free_them = 0;
    va_list ap;

    if (params<0) {
	params = -params;
	free_them = 1;
    }

    scparser_EmitPrefix();
    scparser_set_line (ScParserLex.lineno);
    va_start(ap, method);
    {
	dSP;				/* Initialize stack pointer */
	ENTER;				/* everything created after here */
	SAVETMPS;			/* ...is a temporary variable. */
	PUSHMARK(SP);			/* remember the stack pointer */
	XPUSHs(ScParserState.self);	/* $self-> */

	while (params--) {
	    char *text;
	    SV *sv;
	    text = va_arg(ap, char *);
	    sv = newSVpv (text, 0);
	    XPUSHs(sv);			/* token */
	    if (free_them) free (text);
	}

	PUTBACK;			/* make local stack pointer global */
	perl_call_method (method, G_DISCARD | G_VOID);
	FREETMPS;			/* free that return value */
	LEAVE;				/* ...and the XPUSHed "mortal" args.*/
    }
    va_end(ap);
}

/**********************************************************************/

void scgrammererror (const char *s)
{
    scparser_EmitPrefix ();	/* Dump previous stuff, so error location is obvious */
    scparser_set_line (ScParserLex.lineno);
    scparser_call (2,"error", s, sclextext);
    ScParserState.Errors++;
}

void scparse_init (SV *CLASS, const char *filename, int strip)
{
    ScParserState.self = CLASS;
    ScParserState.Errors = 0;
    ScParserLex.stripAutos = strip;

    ScParserLex.filename = strdup(filename);
    ScParserLex.lineno = 1;
    scparser_set_line (1);

    sclextext = "";  /* In case we get a error in the open */
}

#/**********************************************************************/
#/**********************************************************************/

MODULE = SystemC::Parser  PACKAGE = SystemC::Parser

#/**********************************************************************/
#/* self->lineno() */

int
lineno (CLASS)
SV *CLASS
PROTOTYPE: $
CODE:
{
    RETVAL = ScParserState.LastLineno;
}
OUTPUT: RETVAL

#/**********************************************************************/
#/* self->filename() */

const char *
filename (CLASS)
SV *CLASS
PROTOTYPE: $
CODE:
{
    RETVAL = ScParserLex.filename;
}
OUTPUT: RETVAL

#/**********************************************************************/
#/* self->read (filename) */

int 
_read_xs (CLASS, filename, strip_autos)
SV *CLASS
char *filename
int strip_autos
PROTOTYPE: $$$
CODE:
{
    if (!SvROK(CLASS)) {
	croak ("SystemC::Parser::read() not called as class member");
    }

    if (!filename) {
	croak ("SystemC::Parser::read() filename=> parameter not passed");
    }

    scparse_init (CLASS, filename, strip_autos);
    sclexin = fopen (filename, "r");
    if (!sclexin) {
	/* Presume user does -r before calling us */
	croak ("SystemC::Parser::read() file not found");
    }
    scgrammerparse();
    fclose (sclexin);

    /* Emit final tokens */
    scparser_EmitPrefix ();

    if (ScParserState.Errors) {
	croak ("SystemC::Parser::read() detected parse errors");
    }
    RETVAL = 1;
}
OUTPUT: RETVAL

