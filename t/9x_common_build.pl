#!/usr/local/bin/perl -w
# $Revision: #7 $$Date: 2003/07/16 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

my $dir = "test_dir";
if ($Use_SCL) {
    print "*** Using SCLITE\n";
    $ENV{SYSTEMC} = "../sclite";
    $dir = "test_scl";
}

print "Building example...\n";
if ($Config{archname} !~ /linux/
    || !$ENV{SYSTEMC}) {
    skip("skip Not linux or missing SystemC",1);
} else {
    run_system ("cd $dir && make -j 3 -f ../example/Makefile_obj");
    ok(1);
}

print "Running example...\n";
if (! -x "$dir/ex_main"
    || $Use_SCL  # For now...
    ) {
    skip("skip Not linux or missing SystemC",1);
    skip("skip Not linux or missing SystemC",1);
    skip("skip Not linux or missing SystemC",1);
} else {
    run_system ("cd $dir && ./ex_main");
    ok(1);
    ok(-r "$dir/sim_sc.vcd");
    ok(-r "$dir/sim_sp.dump");
}
