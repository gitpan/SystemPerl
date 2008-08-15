# $Id: Makefile.PL 58970 2008-08-12 13:24:36Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package
#
# Copyright 2001-2008 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use ExtUtils::MakeMaker;

sub MY::postamble {
    my $out;
    $out .= "CCFLAGS  += -Wall -Wno-unused -Werror\n" if $ENV{VERILATOR_AUTHOR_SITE};
    $out .= '
ifeq ($(OBJCACHE_HOSTS_DETERMINANT),)
OBJCACHE :=
else
OBJCACHE := objcache --read --write
endif

CC = $(OBJCACHE) gcc
LEX = flex
YACC = bison
CFLAGS += -Wall

#CFLAGS += -DFLEX_DEBUG
#LEXFLAGS += -d -L

sclex_prefix.c: sclex.l  scgrammer.h scparse.h
	${LEX} ${LEXFLAGS} -Psclex -o$@ $<

sclex.c: sclex_prefix.c
	sed "s/(void) *fwrite(\(.*\))/if (fwrite(\1)) {}/" < $< > $@    # GCC 4.1.0 warn_unused_result

scgrammer.c scgrammer.h:	scgrammer.y scparse.h
	${YACC} ${YFLAGS} --debug --verbose -d -k $< -pscgrammer -o scgrammer.c

clean::
	-rm -rf test *.o sclex*.c scgrammer.h scgrammer.c *.output
';
    return $out;
}

WriteMakefile(
              NAME => "SystemC::Parser",
	      VERSION_FROM  => 'Parser.pm',
	      MYEXTLIB => 'sclex.o scgrammer.o',
	      INC => (" -I."),
	      );
