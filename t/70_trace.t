#!/usr/local/bin/perl -w
# $Revision: #6 $$Date: 2003/08/13 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Test;
use Config;

BEGIN { plan tests => 2 }
BEGIN { require "t/test_utils.pl"; }

print "Building example...\n";
if ($Config{archname} !~ /linux/
    || !$ENV{SYSTEMC}) {
    print "Skipping: Not linux with systemc installed\n";
    skip("skip Not linux or missing SystemC",1);
    skip("skip Not linux or missing SystemC",1);
} else {
    run_system ("cd test_dir "
		."&& g++ -ggdb -DSPTRACEVCD_TEST ../src/SpTraceVcd.cpp -o SpTraceVcd "
		."&& ./SpTraceVcd");
    ok(1);
    ok(-r "test_dir/test.dump")
}
