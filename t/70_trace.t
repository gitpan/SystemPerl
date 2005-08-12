#!/usr/bin/perl -w
# $Id: 70_trace.t 4305 2005-08-02 13:21:57Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2005 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;
use Config;

BEGIN { plan tests => 2 }
BEGIN { require "t/test_utils.pl"; }

print "Building example...\n";
if ($Config{archname} !~ /linux/
    || !$ENV{SYSTEMC}) {
    print "Skipping: Harmless; Not linux with systemc installed\n";
    skip("skip Harmless; Not linux or missing SystemC",1);
    skip("skip Harmless; Not linux or missing SystemC",1);
} else {
    run_system ("cd test_dir "
		."&& g++ -ggdb -DSPTRACEVCD_TEST ../src/SpTraceVcdC.cpp -o SpTraceVcdC "
		."&& ./SpTraceVcdC");
    ok(1);
    ok(-r "test_dir/test.vcd")
}
