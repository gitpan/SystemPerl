# $Id: Makefile.PL,v 1.14 2001/05/21 13:34:54 wsnyder Exp $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

require 5.005;
use ExtUtils::MakeMaker;
use Carp;

sub MY::postamble {
"
README: readme.texi
	-rm \$@
	makeinfo \$< --output \$@ --no-headers --no-validate

maintainer-clean: distclean
	-rm README Makefile

dist: distcheck README

install-local: manifypods
	cp -R blib/man* /usr/local/common/man
	cp -R sp_makecheck /usr/local/common/bin/sp_makecheck__notfound

tag:
	cvs tag -F \$(DISTNAME)_\$(VERSION_SYM) .
";
}

WriteMakefile(
	      DISTNAME  => 'SystemPerl',
	      NAME      => 'SystemC::Netlist',
	      AUTHOR	=> 'Wilson Snyder <wsnyder@wsnyder.org>',
	      ABSTRACT  => 'SystemC Netlist Utilities and Parsing',
	      VERSION_FROM  => 'Netlist.pm',
	      EXE_FILES => [qw( sp_preproc sp_includer sp_makecheck )],
	      'clean'	=> {FILES => qw ( ),},
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );

