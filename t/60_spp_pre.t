#!/usr/local/bin/perl -w
# $Revision: #9 $$Date: 2003/06/16 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

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
	    ." *.sp");
ok(1);

ok(-r 'test_dir/sp_preproc.sp_tree');
ok(-r 'test_dir/sp_preproc.sp_lib');
ok(-r 'test_dir/sp_preproc.d');

#----------------------------------------------------------------------

run_system ("cd test_dir && ${PERL} ../sp_preproc "
	    ." sp_preproc.sp_lib");
ok(1);
