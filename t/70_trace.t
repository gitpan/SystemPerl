#!/usr/local/bin/perl -w
# $Revision: #9 $$Date: 2004/03/08 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2004 by Wilson Snyder.  This program is free software;
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
		."&& g++ -ggdb -DSPTRACEVCD_TEST ../src/SpTraceVcd.cpp -o SpTraceVcd "
		."&& ./SpTraceVcd");
    ok(1);
    ok(-r "test_dir/test.dump")
}
