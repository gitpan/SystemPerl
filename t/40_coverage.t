#!/usr/bin/perl -w
# $Revision: #2 $$Date: 2004/07/22 $$Author: ws150726 $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2004 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;

BEGIN { plan tests => 8 }
BEGIN { require "t/test_utils.pl"; }

use SystemC::Coverage;
ok(1);

my $cov = new SystemC::Coverage;
ok($cov);

$cov->inc('foo','bar',10);
ok(1);

covline('line','a.b.c',__FILE__,__LINE__,'testok',100);
covline('line','a.b.c',__FILE__,__LINE__,'testlow',1);
covline('line','a.b.c',__FILE__,__LINE__,'testnone',0);
ok(1);

mkdir 'test_dir/logs', 0777;
$cov->write(filename=>'test_dir/logs/coverage.pl');
ok(1);

my $cov2 = new SystemC::Coverage;
$cov2->read(filename=>'test_dir/logs/coverage.pl');
ok ($cov2);

$cov2->write(filename=>'test_dir/logs/coverage2.pl');
ok (files_identical('test_dir/logs/coverage.pl', 'test_dir/logs/coverage2.pl'));

run_system("cd test_dir ; ${PERL} ../vcoverage -y ../");
ok (-r "test_dir/logs/coverage_source/40_coverage.t");
