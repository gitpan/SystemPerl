# $Revision: #11 $$Date: 2002/07/16 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

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
