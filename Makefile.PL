# $Id: Makefile.PL,v 1.20 2001/11/16 15:01:38 wsnyder Exp $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package

require 5.005;
use ExtUtils::MakeMaker;
use Carp;

sub MY::postamble {
"
README: readme.texi
	-rm \$@
	makeinfo \$< --output \$@ --no-headers --no-validate

dist: distcheck README

install-local: manifypods
	cp -R blib/man* /usr/local/common/man
	cp -R sp_makecheck /usr/local/common/bin/sp_makecheck__notfound

## Maintainer use:
tag:
	cvs tag -F \$(DISTNAME)_\$(VERSION_SYM) .

maintainer-dist: dist tag
	cp \$(DISTVNAME).tar.gz \$(HOME)/src/kits
	mv \$(DISTVNAME).tar.gz \$(HOME)/backpack

maintainer-clean: distclean
	-rm README Makefile

clean::
	-rm -rf test_dir
";
}

local $! = undef;
`flex --version`; ($?==0) or die "\n%Error: 'flex' must be installed to build\n";
`bison --version`; ($?==0) or die "\n%Error: 'bison' must be installed to build\n";

WriteMakefile(
	      DISTNAME  => 'SystemPerl',
	      NAME      => 'SystemC::Netlist',
	      AUTHOR	=> 'Wilson Snyder <wsnyder@wsnyder.org>',
	      ABSTRACT  => 'SystemC Netlist Utilities and Parsing',
	      VERSION_FROM  => 'Netlist.pm',
	      PREREQ_PM => {'Verilog::Getopt' => 1.13,
			    'Verilog::Netlist' => 2.010,
			},
	      EXE_FILES => [qw( sp_preproc sp_includer sp_makecheck )],
	      'clean'	=> {FILES => qw ( ),},
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );

