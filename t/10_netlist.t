#!/usr/local/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Test;

BEGIN { plan tests => 5 }
BEGIN { require "t/test_utils.pl"; }

use SystemC::Netlist;
ok(1);

my $nl = new SystemC::Netlist ();
ok($nl);

$nl->read_file (filename=>'example/ex_mod.sp',
		strip_autos=>1);
ok($nl);
$nl->read_file (filename=>'example/ex_mod_sub.sp',
		strip_autos=>1);
ok($nl);

$nl->link();
$nl->autos();
$nl->lint();
ok($nl);
