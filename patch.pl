#!/usr/local/bin/perl -w

use Cwd;
use IO::File;
BEGIN { require "t/test_utils.pl"; }
use strict;

if (-r "$ENV{SYSTEMC}/systemperl_patched") {
    print "Patch already applied\n";
    exit(0);
}

if (!-r "$ENV{SYSTEMC}/src/systemc/datatypes/bit/sc_bv_base.h") {
    die "%Error: Unknown version of SystemC,";
}

my $pfile = getcwd()."/patch-2-0-1.diff";

run_system("cd $ENV{SYSTEMC} && pwd");
run_system("cd $ENV{SYSTEMC} && patch -b -p0 <$pfile");

IO::File->new("$ENV{SYSTEMC}/systemperl_patched","w")->close();  #touch

print "Patch applied!\n";
