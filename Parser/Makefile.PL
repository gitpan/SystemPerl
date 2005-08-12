# $Id: Makefile.PL 4305 2005-08-02 13:21:57Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package
#
# Copyright 2001-2005 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use ExtUtils::MakeMaker;

sub MY::postamble {
'
LEX = flex
YACC = bison
CFLAGS += -Wall

#CFLAGS += -DFLEX_DEBUG
#LEXFLAGS += -d -L

sclex.c: sclex.l  scgrammer.h scparse.h
	${LEX} ${LEXFLAGS} -Psclex -o$@ $<

scgrammer.c scgrammer.h:	scgrammer.y scparse.h
	${YACC} ${YFLAGS} --debug --verbose -d -k $< -pscgrammer -o scgrammer.c

clean::
	-rm -rf test *.o sclex.c scgrammer.h scgrammer.c *.output
';
}

WriteMakefile(
              NAME => "SystemC::Parser",
	      VERSION_FROM  => 'Parser.pm',
	      MYEXTLIB => 'sclex.o scgrammer.o',
	      INC => (" -I."),
	      );
