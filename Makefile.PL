# $Revision: #31 $$Date: 2003/09/22 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'perl Makefile.PL' to create a Makefile for this package
#
# Copyright 2001-2003 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

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
	cp systemc-mode.el /usr/local/common/site-lisp

sc_patch:
	\$(PERL) patch.pl

## Maintainer use:
tag:
	p4 label -d     \$(DISTNAME)_\$(VERSION_SYM) || true
	p4 label        \$(DISTNAME)_\$(VERSION_SYM)
	p4 labelsync -l \$(DISTNAME)_\$(VERSION_SYM) ...
#	cvs tag -F \$(DISTNAME)_\$(VERSION_SYM) .

maintainer-dist: dist tag
	cp \$(DISTVNAME).tar.gz \$(HOME)/src/kits
	mv \$(DISTVNAME).tar.gz \$(HOME)/backpack
	echo \"NOTE: Did you try a test without SYSTEMC set?\"

maintainer-clean: distclean
	-rm README Makefile

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
	      PREREQ_PM => {'Verilog::Getopt' => 2.211,
			    'Verilog::Netlist' => 2.210,
			},
	      EXE_FILES => [qw( sp_preproc sp_includer sp_makecheck )],
	      'clean'	=> {FILES => qw ( ),},
	      'dist'    => {COMPRESS => 'gzip -9f',
			    SUFFIX   => '.gz', 
			    DIST_DEFAULT => 'README all tardist',
			},
	      );

if (!$ENV{SYSTEMC}) {
    warn "-Info: SystemC isn't in the enviornment, 'make test' won't work\n";
} elsif (!-r "$ENV{SYSTEMC}/systemperl_patched") {
    warn "-Info: Your SystemC disctribution has NOT been patched to allow sc_bv\n";
    warn "       tracing.  Type 'make sc_patch' to attempt the edits.\n";
    warn "       See the README file for details.\n"
}
