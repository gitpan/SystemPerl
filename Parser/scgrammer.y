%{
/* $Revision: #47 $$Date: 2003/09/22 $$Author: wsnyder $
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
 * Copyright 2001-2003 by Wilson Snyder.  This program is free software;
 * you can redistribute it and/or modify it under the terms of either the GNU
 * General Public License or the Perl Artistic License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 *****************************************************************************/

#include "scparse.h"
#define YYERROR_VERBOSE
#define SCFree(p) {if (p) free(p); p=NULL;}

extern /*const*/ char *sclextext;
int scgrammerdebug = 0;
extern int sclexleng;

/* Join two strings, return result */
char *scstrjoin2ss (char *a, char *b) {
    int len = strlen(a)+strlen(b);
    char *cp=malloc(len+5);
    strcpy (cp,a); strcat(cp,b);
    SCFree (a); SCFree (b);
    return (cp);
}

/* Join two strings, return result */
char *scstrjoin2si (char *a, const char *b) {
    int len = strlen(a)+strlen(b);
    char *cp=malloc(len+5);
    strcpy (cp,a); strcat(cp,b);
    SCFree (a); /*SCFree (b);*/
    return (cp);
}

/* Join three strings, middle one constant, return result */
char *scstrjoin3sis (char *a, const char *b, char *c) {
    int len = strlen(a)+strlen(b)+strlen(c);
    char *cp=malloc(len+5);
    strcpy (cp,a); strcat(cp,b); strcat(cp,c);
    SCFree (a); /*SCFree (b);*/ SCFree (c);
    return (cp);
}

char *scstrjoin4sisi (char *a, const char *b, char *c, const char* d) {
    int len = strlen(a)+strlen(b)+strlen(c)+strlen(d);
    char *cp=malloc(len+5);
    strcpy (cp,a); strcat(cp,b); strcat(cp,c); strcat(cp,d);
    SCFree (a); /*SCFree (b);*/ SCFree (c); /*ScFree(d)*/
    return (cp);
}

/* Emit all text including this parsed token */

int scgrammerlex() {
    int toke;
    sclex_include_switch ();
    toke = sclexlex();
    if (toke != SP && toke != AUTO) {	// Strip #sp.... from text sections, AUTOs do it separately
	scparser_PrefixCat(sclextext,sclexleng);
    }
#ifdef FLEX_DEBUG
    if (sclex_flex_debug) {
	fprintf(stderr,"ln%d: GOT %d: '%s'\n", scParserLex.lineno, toke,
		DENULL(sclextext));
    }
#endif
    return (toke);
};

%}

/*%pure_parser*/
%token_table
%union {
  char *string;
}

%token<string> 	STRING
%token<string>	SYMBOL
%token<string>	NUMBER
%token		PP
%token		SP

%token		COLONCOLON

%token		CLASS
%token		ENUM
%token		PUBLIC
%token		PRIVATE
%token		PROTECTED
%token		CONST

%token		AUTO

%token		SC_MODULE
%token<string>	SC_SIGNAL
%token<string>	SC_INOUT_CLK
%token<string>	SC_CLOCK
%token		SC_CTOR
%token		SC_MAIN
%token		SP_CELL
%token		SP_CELL_DECL
%token		SP_PIN
%token		SP_TRACED
%token		VL_SIG
%token		VL_SIGW
%token		VL_INOUT
%token		VL_INOUTW
%token		VL_IN
%token		VL_INW
%token		VL_OUT
%token		VL_OUTW

%type<string>	cellname
%type<string>	vectors_bra
%type<string>	vector_bra
%type<string>	vector
%type<string>	vectorNum
%type<string>	clSymAccess
%type<string>	clSymScoped
%type<string>	clSymParamed
%type<string>	clSymRef
%type<string>	clList
%type<string>	clColList
%type<string>	declType
%type<string>	declType1
%type<string>	declTypeBase

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
		| '\'' | '(' | ')' | '*' | '+' | ','
		| '-' | '.' | '/' | ':' | ';' | '<'
		| '=' | '>' | '?' | '@'	| '\\' | '['
		| ']' | '^' | '`' | '|' | '{' | '}'
		| '~' | COLONCOLON
		;

clAccess:	PUBLIC | PRIVATE | PROTECTED
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
		| traceable
		| inout
		| inout_clk
		| inst_clk
		| sp
		| class
		| enum
		| STRING	{ SCFree($1); }
		| SYMBOL	{ scparser_symbol($1); SCFree($1); }
		| NUMBER	{ SCFree($1); }
		| PP		{ }
		| CONST
		| symbol
		| clAccess
		;

auto:		AUTO
			{
			  scparser_EmitPrefix();
			  scparser_PrefixCat(sclextext,sclexleng);  /* Emit as independent TEXT */
			  scparser_call(1,"auto",sclextext);
			}
		;

module:		SC_MODULE '(' SYMBOL ')'
			{ scparser_call(-1,"module",$3); }
		| SC_MAIN
			{ scparser_call(1,"module","sc_main"); }
		;

class:		CLASS clSymScoped '{'	{ scparser_call(-1,"class",$2); }
		| CLASS clSymScoped ':' clColList '{'
			{ scparser_call(-2,"class",$2,$4); }
		| CLASS clSymScoped ';'	{ }	/* Fwd decl */
		| CLASS clSymScoped '>'	{ }	/* template <class SYMBOL> */
		| CLASS clSymScoped clSymScoped { }	/* struct SYM sym; */
		| CLASS clSymScoped '*'	{ }	/* (struct SYM*) */
		| CLASS clSymScoped ')'	{ }	/* (struct SYM) */
		| CLASS '{'		{ }	/* Anonymous struct */
		;

clColList:	clList				{ $$ = $1; }
		| clList ':' clColList		{ $$ = scstrjoin3sis ($1,":",$3); }
		;

clList:		clSymAccess			{ $$ = $1; }
		| clSymAccess ',' clList	{ $$ = scstrjoin3sis ($1,",",$3); }
		;

clSymAccess:	clSymParamed		{ $$ = $1; }
		| clAccess clSymParamed	{ $$ = $2; }
		;

clSymParamed:	clSymRef		{ $$ = $1; }
		| clSymRef '<' clList '>'	{ $$ = scstrjoin4sisi ($1,"<",$3,">"); }
		;

clSymScoped:	SYMBOL			{ $$ = $1; }
		| SYMBOL COLONCOLON SYMBOL	{ $$ = scstrjoin3sis ($1,"::",$3); }
		;

clSymRef:	clSymScoped		{ $$ = $1; }
		| clSymScoped '*'	{ $$ = scstrjoin2si ($1,"*"); }
		| CONST clSymScoped	{ $$ = $2; }
		| CONST clSymScoped '*'	{ $$ = scstrjoin2si ($2,"*"); }
		;

ctor:		SC_CTOR '(' SYMBOL ')'
			{ scparser_call(-1,"ctor",$3); }
		;
// SP_CELL ignores trailing ')' so SP_CELL_FORM is happy
cell:		SP_CELL '(' cellname ',' SYMBOL
			{ scparser_call(-2,"cell",$3,$5); }
		;
cell_decl:	SP_CELL_DECL '(' SYMBOL ',' cellname ')' ';'
			{ scparser_call(-2,"cell_decl",$3,$5); }
		;
pin:		SP_PIN '(' cellname ',' SYMBOL vector ',' SYMBOL vector ')' ';'
			{ scparser_call(-5,"pin",$3,$5,$6,$8,$9); }
		;
decl:		SC_SIGNAL '<' declType '>' SYMBOL vector ';'
			{ scparser_call(-4,"signal",$1,$3,$5,$6); }
		;

//		FOO or FOO::BAR*
declType:	declType1		{ $$ = $1; }
		| declType1 '*'	{ char *cp=malloc(strlen($1)+5);
			  strcpy (cp,$1); strcat(cp,"*");
			  SCFree ($1);
			  $$=cp; }
		;

declType1:	declTypeBase
		| SYMBOL COLONCOLON declType1
			{ $$ = scstrjoin3sis ($1,"::",$3); }
		;

//		uint32_t | sc_bit<4> | unsigned int
declTypeBase:	SYMBOL
		| SYMBOL '<' vectorNum '>'
			{ char *cp=malloc(strlen($1)+strlen($3)+5);
			  strcpy (cp,$1); strcat(cp,"<");strcat(cp,$3);strcat(cp,">");
			  SCFree ($1); SCFree ($3);
			  $$=cp; }
		;

//		sc_in_clk SYMBOL
inout:		SC_INOUT_CLK SYMBOL vector ';'
			{
			  {char *cp = strrchr($1,'_'); if (cp) *cp='\0';} /* Drop _clk */
			  scparser_call(4,"signal",$1,"sc_clock",$2,$3);
 			  SCFree($1); SCFree($2); SCFree($3);}
		;
//		sc_clock SYMBOL ;
inout_clk:	SC_CLOCK SYMBOL ';'
			{
			  scparser_call(3,"signal",$1,"sc_clock",$2);
 			  SCFree($1); SCFree($2);}
		;

		// foo = sc_clk (bar)
inst_clk:	SC_CLOCK '(' { SCFree($1); }
		| SC_CLOCK SYMBOL '(' { SCFree($1); SCFree($2);}
		;

sp:		SP	{ scparser_call(1,"preproc_sp",sclextext);}
		;

//************************************
// Tracables

traceable:	SP_TRACED SYMBOL SYMBOL vector ';'
 			{ scparser_call(4,"signal","sp_traced",$2,$3,$4);
 			  SCFree($2); SCFree($3); SCFree($4)}
		| VL_SIG '(' SYMBOL vector ',' NUMBER ',' NUMBER ')' ';'
 			{ scparser_call(6,"signal","sp_traced_vl","uint32_t",$3,$4,$6,$8);
 			  SCFree($3); SCFree($4); SCFree($6); SCFree($8);}
		| VL_SIGW '(' SYMBOL vector ',' NUMBER ',' NUMBER ',' vectorNum ')' ';'
 			{ scparser_call(6,"signal","sp_traced_vl","uint32_t",$3,$4,$6,$8);
 			  SCFree($3); SCFree($4); SCFree($6); SCFree($8); SCFree($10);}
		| VL_INOUT '(' SYMBOL vector ',' NUMBER ',' NUMBER ')' ';'
 			{ scparser_call(6,"signal","vl_inout","uint32_t",$3,$4,$6,$8);
 			  SCFree($3); SCFree($4); SCFree($6); SCFree($8);}
		| VL_INOUTW '(' SYMBOL vector ',' NUMBER ',' NUMBER ',' vectorNum ')' ';'
 			{ scparser_call(6,"signal","vl_inout","uint32_t",$3,$4,$6,$8);
 			  SCFree($3); SCFree($4); SCFree($6); SCFree($8); SCFree($10);}
		| VL_IN '(' SYMBOL vector ',' NUMBER ',' NUMBER ')' ';'
 			{ scparser_call(6,"signal","vl_in","uint32_t",$3,$4,$6,$8);
 			  SCFree($3); SCFree($4); SCFree($6); SCFree($8);}
		| VL_INW '(' SYMBOL vector ',' NUMBER ',' NUMBER ',' vectorNum ')' ';'
 			{ scparser_call(6,"signal","vl_in","uint32_t",$3,$4,$6,$8);
 			  SCFree($3); SCFree($4); SCFree($6); SCFree($8); SCFree($10);}
		| VL_OUT '(' SYMBOL vector ',' NUMBER ',' NUMBER ')' ';'
 			{ scparser_call(6,"signal","vl_out","uint32_t",$3,$4,$6,$8);
 			  SCFree($3); SCFree($4); SCFree($6); SCFree($8);}
		| VL_OUTW '(' SYMBOL vector ',' NUMBER ',' NUMBER ',' vectorNum ')' ';'
 			{ scparser_call(6,"signal","vl_out","uint32_t",$3,$4,$6,$8);
 			  SCFree($3); SCFree($4); SCFree($6); SCFree($8); SCFree($10);}
		;

//************************************
// Enumerations

enum:		ENUM enumSymbol '{' enumValList '}'
  			{ SCFree (scParserLex.enumname); }

		;
enumSymbol:	SYMBOL	{ scParserLex.enumname = $1; }
		|	{ scParserLex.enumname = NULL; }
		;
enumValList:	enumVal
 		| enumValList ',' enumVal
		;
enumVal:	SYMBOL	enumAssign  {
			if (scParserLex.enumname) scparser_call(2,"enum_value",scParserLex.enumname,$1);
			SCFree ($1); }
		;
enumAssign:	'=' NUMBER	{ SCFree ($2); }
		| '=' SYMBOL	{ SCFree ($2); }
 		| ;

//************************************

cellname:	SYMBOL
		| SYMBOL vectors_bra		{ $$=scstrjoin2ss($1,$2); }
		;

vectors_bra:	vector_bra
		| vectors_bra vector_bra	{ $$=scstrjoin2ss($1,$2); }
		;

vector_bra:	'[' vectorNum ']'	{ char *cp=malloc(strlen($2)+5);
			  strcpy (cp,"["); strcat(cp,$2);strcat(cp,"]");
			  SCFree ($2);
			  $$=cp; }
		;

vector:		'[' vectorNum ']'	{ $$ = $2; }
		|	{ $$ = strdup(""); }	/* Horrid */
		;

vectorNum:	SYMBOL			{ $$ = $1; }
		| NUMBER		{ $$ = $1; }
	 	| SYMBOL COLONCOLON SYMBOL	{ $$ = scstrjoin3sis ($1,":",$3); }
		;

%%

const char *vlgrammer_tokename (int toke) {
    return (yytname[toke]);
}
