#!/usr/bin/perl -w
# $Revision: #9 $$Date: 2004/06/21 $$Author: ws150726 $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2004 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;

BEGIN { plan tests => 5 }
BEGIN { require "t/test_utils.pl"; }

use SystemC::Netlist;
ok(1);

my $nl = new SystemC::Netlist ();
ok($nl);

$nl->read_file (filename=>'example/ExMod.sp',
		strip_autos=>1);
ok($nl);
$nl->read_file (filename=>'example/ExModSub.sp',
		strip_autos=>1);
ok($nl);

$nl->link();
$nl->autos();
$nl->lint();
ok($nl);
