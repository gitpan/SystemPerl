#!/usr/local/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Test;

BEGIN { plan tests => 2 }
BEGIN { require "t/test_utils.pl"; }

print "Checking sp_preproc (Preproc mode)...\n";
run_system ("cp example/*.sp test_dir");
ok(1);

run_system ("cd test_dir && perl -Iblib/arch -Iblib/lib ../sp_preproc --preproc *.sp");
ok(1);
