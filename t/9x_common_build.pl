#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2009 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License or the Perl Artistic License.

my $dir = "test_dir";
if ($Use_SCL) {
    print "*** Using SCLITE\n";
    $ENV{SYSTEMC} = "../sclite";
    $dir = "test_scl";
}

unlink glob("$dir/logs/*");

print "Building example...\n";
if ($Config{archname} !~ /linux/
    || !$ENV{SYSTEMC}) {
    skip("skip Harmless; Not linux or missing SystemC",1);
} else {
    run_system ("cd $dir && make -j 3 -f ../example/Makefile_obj preproc");
    run_system ("cd $dir && make -j 3 -f ../example/Makefile_obj compile");
    ok(-x "$dir/ex_main");
}

print "Running example...\n";
if (! -x "$dir/ex_main"
    || $Use_SCL  # For now...
    ) {
    skip("skip Harmless; Not linux or missing SystemC",1);
    skip("skip Harmless; Not linux or missing SystemC",1);
    skip("skip Harmless; Not linux or missing SystemC",1);
    skip("skip Harmless; Not linux or missing SystemC",1);
} else {
    run_system ("cd $dir && ./ex_main");
    ok(1);
    ok(-r "$dir/sim_sc.vcd");
    ok(-r "$dir/sim_sp.vcd");
    run_system ("cd $dir && ../vcoverage -y ../");
    ok(-r "$dir/logs/coverage_source/ExModSub.sp");
}

1;
