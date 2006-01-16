#!/usr/bin/perl -w
# $Id: 90_ncsc_run.t 11992 2006-01-16 18:59:58Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2006 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;
use Config;

BEGIN { plan tests => 2 }
BEGIN { require "t/test_utils.pl"; }

run_system ("/bin/rm -rf test_dir");
mkdir 'test_dir',0777;

# Generate preprocessed files
# Basically the same as 60_spp_pre.t
run_system ("cp example/*.sp* test_dir");
run_system ("cp example/*.cpp test_dir");
ok(1);

print "Building example...\n";
if (!ncsc_ok()) {
    skip("skip Harmless; Not linux or missing NC-SC",1);
} else {
    run_system ("cd test_dir && make -f ../example/Makefile_ncsc");
    ok(-x "test_dir/ncsim_sc");
}

1;

