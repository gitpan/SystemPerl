#!/usr/bin/perl -w
# $Revision: 1.13 $$Date: 2005-03-01 17:59:56 -0500 (Tue, 01 Mar 2005) $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2005 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;

BEGIN { plan tests => 6 }
BEGIN { require "t/test_utils.pl"; }

print "Checking sp_preproc (Preproc mode)...\n";
run_system ("cp example/*.sp* test_dir");
ok(1);

run_system ("cd test_dir && ${PERL} ../sp_preproc"
	    ." -M sp_preproc.d"
	    ." --tree sp_preproc.sp_tree --libfile sp_preproc.sp_lib --preproc"
	    ." --write-verilog sp_preproc.v"
	    ." *.sp");
ok(1);

ok(-r 'test_dir/sp_preproc.sp_tree');
ok(-r 'test_dir/sp_preproc.sp_lib');
ok(-r 'test_dir/sp_preproc.d');

#----------------------------------------------------------------------

run_system ("cd test_dir && ${PERL} ../sp_preproc "
	    ." sp_preproc.sp_lib");
ok(1);
