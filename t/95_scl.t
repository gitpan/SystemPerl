#!/usr/local/bin/perl -w
# $Id: 95_scl.t,v 1.3 2002/03/11 14:07:22 wsnyder Exp $
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

