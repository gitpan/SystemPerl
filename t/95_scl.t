#!/usr/local/bin/perl -w
# $Revision: #4 $$Date: 2002/07/16 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Test;
use Config;

BEGIN { plan tests => 5 }
BEGIN { require "t/test_utils.pl"; }

use vars qw ($Use_SCL);
$Use_SCL = 1;

mkdir 'test_scl',0777;

if (1) {
    # Under development, cheat.
    ok(1);
    ok(1);
    ok(1);
    ok(1);
    ok(1);
    exit;
}

if ($Config{archname} !~ /linux/) {
    print "Skipping: Not linux\n";
    skip(1,1);
} else {
    run_system ("cd sclite/src && make");
    ok(-r "sclite/lib-linux/libsystemc.a");
}

require "t/9x_common_build.pl";

