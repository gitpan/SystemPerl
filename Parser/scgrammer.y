%{
/* $Id: scgrammer.y,v 1.22 2001/04/26 14:45:40 wsnyder Exp $
 ******************************************************************************
 * DESCRIPTION: SystemC bison parser
 *
 * This file is part of SystemC-Perl.
 *
 * Author: Wilson Snyder <wsnyder@wsnyder.org>
 *
 * Code available from: http://veripool.com/systemperl
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
#define YYERROR_VERBOSE
#define SCFree(p) {if (p) free(p); p=NULL;}

extern /*const*/ char *sclextext;
int scgrammerdebug = 0;
extern int sclexleng;

/* Join two strings, return result */
char *scstrjoin (char *a, char *b)
{
    int len = strlen(a)+strlen(b);
    char *cp=malloc(len+5);
    strcpy (cp,a); strcat(cp,b);
    SCFree (a); SCFree (b);
    return (cp);
}

/* Emit all text including this parsed token */

int scgrammerlex() {
    int toke;
    toke = sclexlex();
    if (toke != SP) {
	scparser_PrefixCat(sclextext,sclexleng);
    }
    /*
      printf ("ln%d: GOT %d: '%s'\n", ScParserLex.lineno, toke,
      DENULL(sclextext));
    */
    return (toke);
};

%}

/*%pure_parser*/
%token_table
/* #%union {
 #  char *string;
 #  Vp_Node *node;
 #  Vp_SubType sub;
 #  Vp_Flag flag;
 #} */
%union {
  char *string;
}

%token	 	STRING
%token<string>	SYMBOL
%token<string>	NUMBER
%token		PP
%token		SP

%token		SC_MODULE
%token<string>	SC_SIGNAL
%token<string>	SC_INOUT_CLK
%token<string>	SC_CLOCK
%token		SC_CTOR
%token		SC_MAIN
%token		SP_CELL
%token		SP_CELL_DECL
%token		SP_PIN
%token		CLASS
%token		ENUM
%token		AUTO

%type<string>	cellname
%type<string>	vectors_bra
%type<string>	vector_bra
%type<string>	vector
%type<string>	vectorNum
%type<string>	declType

%%
//************************************
// Top Rule:
sourceText:	expList
		{ /*clean up!*/
     		scparser_EmitPrefix();
		}
;

//************************************
// Aliases and such

symbol:		  '!' | '"' | '#' | '$' | '%' | '&'
		| ''' | '(' | ')' | '*' | '+' | ','
		| '-' | '.' | '/' | ':' | ';' | '<'
		| '=' | '>' | '?' | '@'	| '\\' | '['
		| ']' | '^' | '`' | '|' | '{' | '}'
		| '~'
;

//************************************

expList:	exp
		| expList exp
;

exp:		auto
		| module
		| ctor
		| cell
		| cell_decl
		| pin
		| decl
		| inout
		| inout_clk
		| inst_clk
		| sp
		| class
		| enum
		| STRING	{ }
		| SYMBOL	{ SCFree($1); }
		| NUMBER	{ SCFree($1); }
		| PP		{ }
		| symbol
;

auto:		AUTO
			{ scparser_call(1,"auto",sclextext);}

module:		SC_MODULE '(' SYMBOL ')'
			{ scparser_call(-1,"module",$3); }
		| SC_MAIN
			{ scparser_call(1,"module","sc_main"); }

class:		CLASS SYMBOL
			{ scparser_call(-1,"class",$2); }

ctor:		SC_CTOR '(' SYMBOL ')'
			{ scparser_call(-1,"ctor",$3); }
// SP_CELL ignores trailing ')' so SP_CELL_FORM is happy
cell:		SP_CELL '(' cellname ',' SYMBOL
			{ scparser_call(-2,"cell",$3,$5); }
cell_decl:	SP_CELL_DECL '(' SYMBOL ',' cellname ')' ';'
			{ scparser_call(-2,"cell_decl",$3,$5); }
pin:		SP_PIN '(' cellname ',' SYMBOL vector ',' SYMBOL vector ')' ';'
			{ scparser_call(-5,"pin",$3,$5,$6,$8,$9); }
decl:		SC_SIGNAL '<' declType '>' SYMBOL vector ';'
			{ scparser_call(-4,"signal",$1,$3,$5,$6); }

//		uint32_t | sc_bit<4> | unsigned int
declType:	SYMBOL
		| SYMBOL '<' vectorNum '>'
			{ char *cp=malloc(strlen($1)+strlen($3)+5);
			  strcpy (cp,$1); strcat(cp,"<");strcat(cp,$3);strcat(cp,">");
			  SCFree ($1); SCFree ($3);
			  $$=cp; }

//		sc_in_clk SYMBOL
inout:		SC_INOUT_CLK SYMBOL
			{
			  {char *cp = strrchr($1,'_'); if (cp) *cp='\0';} /* Drop _clk */
			  scparser_call(3,"signal",$1,"sc_clock",$2);
 			  SCFree($1); SCFree($2);}
//		sc_clock SYMBOL ;
inout_clk:	SC_CLOCK SYMBOL ';'
			{
			  scparser_call(3,"signal",$1,"sc_clock",$2);
 			  SCFree($1); SCFree($2);}

		// foo = sc_clk (bar)
inst_clk:	SC_CLOCK '(' { SCFree($1); }
		| SC_CLOCK SYMBOL '(' { SCFree($1); SCFree($2);}

sp:		SP	{ scparser_call(1,"preproc_sp",sclextext);}
enum:		ENUM enumSymbol '{' enumValList '}'
  			{ SCFree (ScParserLex.enumname); }

enumSymbol:	SYMBOL	{ ScParserLex.enumname = $1; }
		|	{ ScParserLex.enumname = NULL; }
enumValList:	enumVal
 		| enumValList ',' enumVal ;
enumVal:	SYMBOL	enumAssign  {
			if (ScParserLex.enumname) scparser_call(2,"enum_value",ScParserLex.enumname,$1);
			SCFree ($1); }
enumAssign:	'=' NUMBER	{ SCFree ($2); }
 		| ;

//************************************

cellname:	SYMBOL
		| SYMBOL vectors_bra		{ $$=scstrjoin($1,$2); }

vectors_bra:	vector_bra
		| vectors_bra vector_bra	{ $$=scstrjoin($1,$2); }

vector_bra:	'[' vectorNum ']'	{ char *cp=malloc(strlen($2)+5);
			  strcpy (cp,"["); strcat(cp,$2);strcat(cp,"]");
			  SCFree ($2);
			  $$=cp; }

vector:		'[' vectorNum ']'	{ $$ = $2; }
		|	{ $$ = strdup(""); }	/* Horrid */

vectorNum:	SYMBOL | NUMBER

%%

const char *vlgrammer_tokename (int toke) {
    return (yytname[toke]);
}
