%{
/* $Id: scgrammer.y,v 1.15 2001/04/03 16:11:00 wsnyder Exp $
 ******************************************************************************
 * DESCRIPTION: SystemC bison parser
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
#define YYERROR_VERBOSE

extern /*const*/ char *sclextext;
int scgrammerdebug = 0;
extern int sclexleng;

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
%token		NUMBER
%token		PP
%token		SP

%token		SC_MODULE
%token<string>	SC_SIGNAL
%token<string>	SC_INOUT_CLK
%token<string>	SC_SIGNAL_CLK
%token		SC_CTOR
%token		SP_CELL
%token		SP_PIN
%token		ENUM
%token		AUTO

%type<string>	vector
%type<string>	vectorNum

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
		| pin
		| decl
		| inoutck
		| declck
		| sp
		| enum
		| STRING	{ }
		| SYMBOL	{ free($1); }
		| NUMBER	{ }
		| PP		{ }
		| symbol
;

auto:		AUTO
			{ scparser_call(1,"auto",sclextext);}
module:		SC_MODULE '(' SYMBOL ')' '{'
			{ scparser_call(-1,"module",$3); }
ctor:		SC_CTOR '(' SYMBOL ')' '{'
			{ scparser_call(-1,"ctor",$3); }
cell:		SP_CELL '(' SYMBOL ',' SYMBOL ')' ';'
			{ scparser_call(-2,"cell",$3,$5); }
pin:		SP_PIN '(' SYMBOL ',' SYMBOL vector ',' SYMBOL vector ')' ';'
			{ scparser_call(-5,"pin",$3,$5,$6,$8,$9); }
decl:		SC_SIGNAL '<' SYMBOL '>' SYMBOL vector ';'
			{ scparser_call(-4,"signal",$1,$3,$5,$6); }
inoutck:	SC_INOUT_CLK SYMBOL
			{
			  {char *cp = strrchr($1,'_'); if (cp) *cp='\0';} /* Drop _clk */
			  scparser_call(3,"signal",$1,"sc_clock",$2);
 			  free($1); free($2);}
declck:		SC_SIGNAL_CLK SYMBOL ';'
			{
			  scparser_call(3,"signal",$1,"sc_clock",$2);
 			  free($1); free($2);}
		| SC_SIGNAL_CLK '(' { free($1); }	// foo = sc_clk (bar)

sp:		SP	{ scparser_call(1,"preproc_sp",sclextext);}
enum:		ENUM enumSymbol '{' enumValList '}'
  			{ free (ScParserLex.enumname); }

enumSymbol:	SYMBOL	{ ScParserLex.enumname = $1; }
enumValList:	enumVal
 		| enumValList ',' enumVal ;
enumVal:	SYMBOL	enumAssign  {
			scparser_call(2,"enum_value",ScParserLex.enumname,$1);
			free ($1); }
enumAssign:	'=' NUMBER	{ }
 		| ;

//************************************

vector:		'[' vectorNum ']'	{ $$ = $2; }
		|	{ $$ = strdup(""); }	/* Horrid */

vectorNum:	SYMBOL
		| NUMBER	{$$ = strdup(""); }	/* Horrid */

//	      if ($line =~ /^\s* sc_(in|out|inout) \s* (_clk|<([^>]+)>)
//		  \s*  ([^\[; \t]+)		# Signame
//		  \s* (\[\s*([^\] \t]+)\s*\]||)	# Array
//		  ; \s* (.*)$/x) {		# Comment
//		  my $dir=$1; my $clk=$2; my $type=$3; my $name=$4;
//		  my $array=$6; my $cmt=$7;
//		  $type = "sc_clock" if $clk eq "_clk";
//		  $cmt =~ s/^\/\/\s+//;
//	      }
//	      if ($line =~ /^\s* sc_(signal) \s* <([^>]+)>
//		  \s*  ([^\[; \t]+)		# Signame
//		  \s* (\[\s*([^\] \t]+)\s*\]||)	# Array
//		  ; \s* (.*)$/x) {		# Comment
//		  my $dir=$1; my $type=$2; my $name=$3; my $array=$5; my $cmt=$6;
//		  $cmt =~ s/^\/\/\s+//;
//		  $modref->new_signal (name=>$name, filename=>$filename, line=>$.,
//				       direction=>$dir, type=>$type, array=>$array,
//				       comment=>$cmt,);
//	      }
//		  if ($line =~ /^\s* ([^- \t]+)	# Cell
//		      \s*\->\s* ([^= \t\[]+)	# pin
//		      (\[[^\]]+\]|)		# vector
//		      \s* \( \s*
//		      ([^; \t\[\)]+)		# sig
//		      (\[[^\]]+\]|)		# vector
//		      /x) {
//		      my $pin = $2; my $sig=$4;

%%

const char *vlgrammer_tokename (int toke) {
    return (yytname[toke]);
}
