#/* SystemC.xs -- SystemC Booter  -*- Mode: C -*-
#* $Id: Parser.xs,v 1.14 2001/09/27 17:41:34 wsnyder Exp $
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
#* This program is free software; you can redistribute it and/or modify
#* it under the terms of either the GNU General Public License or the
#* Perl Artistic License, with the exception that it cannot be placed
#* on a CD-ROM or similar media for commercial distribution without the
#* prior approval of the author.
#* 
#* This program is distributed in the hope that it will be useful,
#* but WITHOUT ANY WARRANTY; without even the implied warranty of
#* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#* GNU General Public License for more details.
#* 
#* You should have received a copy of the Perl Artistic License
#* along with this module; see the file COPYING.  If not, see
#* www.cpan.org
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

    sclextext = "";  /* In case we get a error in the open */
}

void scparse_set_filename (const char *filename, int lineno)
{
    ScParserLex.filename = strdup(filename);
    ScParserLex.lineno = lineno;
    scparser_set_line (lineno);
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
    static int/*bool*/ in_parser = 0;

    if (!SvROK(CLASS)) {
	in_parser = 0;
	croak ("SystemC::Parser::read() not called as class member");
    }

    if (!filename) {
	in_parser = 0;
	croak ("SystemC::Parser::read() filename=> parameter not passed");
    }

    if (in_parser) {
	croak ("SystemC::Parser::read() called recursively");
    }
    in_parser = 1;

    scparse_init (CLASS, filename, strip_autos);
    if (!sclex_open (filename)) {
	in_parser = 0;
	croak ("SystemC::Parser::read() file not found");
    }
    scgrammerparse();
    fclose (sclexin);

    /* Emit final tokens */
    scparser_EmitPrefix ();

    if (ScParserState.Errors) {
	in_parser = 0;
	croak ("SystemC::Parser::read() detected parse errors");
    }
    in_parser = 0;
    RETVAL = 1;
}
OUTPUT: RETVAL

#/**********************************************************************/
#/* self->read_include (filename) */

int 
_read_include_xs (CLASS, filename)
SV *CLASS
char *filename
PROTOTYPE: $$
CODE:
{
    if (!SvROK(CLASS)) {
	croak ("SystemC::Parser::read_include() not called as class member");
    }
    if (!filename) {
	croak ("SystemC::Parser::read_include() filename=> parameter not passed");
    }
    sclex_include (filename);
    RETVAL = 1;
}
OUTPUT: RETVAL

