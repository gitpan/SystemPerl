# $Revision: 1.41 $$Date: 2005-03-14 11:19:09 -0500 (Mon, 14 Mar 2005) $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package
#
# Copyright 2001-2005 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

require 5.005;
use ExtUtils::MakeMaker;
use Carp;

sub MY::postamble {
"
README: readme.texi
	-rm -rf \$@
	makeinfo \$< --output \$@ --no-headers --no-validate

dist: distcheck README

install-local: manifypods
	cp -R blib/man*    \$(DIRPROJECT_PREFIX)/man
	cp -R sp_makecheck \$(DIRPROJECT_PREFIX)/bin/sp_makecheck__notfound
	cp systemc-mode.el \$(DIRPROJECT_PREFIX)/site-lisp

sc_patch:
	\$(PERL) patch.pl

## Maintainer use:
preexist:
	test ! -r \$(HOME)/src/kits/\$(DISTVNAME).tar.gz

tag:
	svnorcvs tag  \$(DISTNAME)_\$(VERSION_SYM)

maintainer-diff:
	svnorcvs diff \$(DISTNAME)_\$(VERSION_SYM) 

maintainer-dist: preexist dist tag
	cp \$(DISTVNAME).tar.gz \$(HOME)/src/kits
	mv \$(DISTVNAME).tar.gz \$(HOME)/backpack
	echo \"NOTE: Did you try a test without SYSTEMC set?\"

maintainer-clean: distclean
	-rm -rf README Makefile

clean::
	-rm -rf test_dir test_scl
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
	      NO_META	=> 1,
	      PREREQ_PM => {'Verilog::Getopt' => 2.211,
			    'Verilog::Netlist' => 2.314,
			},
	      EXE_FILES => [qw( sp_preproc sp_includer sp_makecheck vcoverage )],
	      'clean'	=> {FILES => qw ( ),},
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );

if (!$ENV{SYSTEMC}) {
    warn "-Info: SystemC isn't in the environment, 'make test' won't work\n";
} elsif (!-r "$ENV{SYSTEMC}/systemperl_patched") {
    warn "-Info: Your SystemC distribution has NOT been patched to allow sc_bv\n";
    warn "       tracing.  Type 'make sc_patch' to attempt the edits.\n";
    warn "       See the README file for details.\n"
}
