# $Id: Makefile.PL,v 1.9 2001/05/21 13:32:27 wsnyder Exp $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

use ExtUtils::MakeMaker;

sub MY::postamble {
'
LEX = flex
YACC = bison
CFLAGS += -Wall

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
