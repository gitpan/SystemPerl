#!/usr/local/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Test;
use Config;

BEGIN { plan tests => 4 }
BEGIN { require "t/test_utils.pl"; }

print "Building example...\n";
if ($Config{archname} !~ /linux/
    || !$ENV{SYSTEMC}) {
    print "Skipping: Not linux with systemc installed\n";
    skip(1,1);
} else {
    run_system ("cd test_dir && make -f ../example/Makefile_obj");
    ok(1);
}

print "Running example...\n";
if (! -x "test_dir/ex_main") {
    skip(1,1);
    skip(1,1);
    skip(1,1);
} else {
    run_system ("cd test_dir && ./ex_main");
    ok(1);
    ok(-r "test_dir/sim_sc.vcd");
    ok(-r "test_dir/sim_sp.vcd");
}
