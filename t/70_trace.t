#!/usr/local/bin/perl -w
# $Id: 70_trace.t,v 1.3 2002/03/11 14:07:22 wsnyder Exp $
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
    skip(1,1);
    skip(1,1);
} else {
    run_system ("cd test_dir "
		."&& g++ -DSPTRACEVCD_TEST ../src/SpTraceVcd.cpp -o SpTraceVcd "
		."&& ./SpTraceVcd");
    ok(1);
    ok(-r "test_dir/test.dump")
}
