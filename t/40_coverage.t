#!/usr/bin/perl -w
# $Id: 40_coverage.t 6132 2005-09-13 15:10:41Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2005 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;

BEGIN { plan tests => 9 }
BEGIN { require "t/test_utils.pl"; }

use SystemC::Coverage;
ok(1);

my $cov = new SystemC::Coverage;
ok($cov);

$cov->inc(comment=>'foo',filename=>__FILE__,lineno=>__LINE__,bar=>'bar',count=>10);
ok(1);

inc(type=>'block',comment=>'line',hier=>'a.b.c',filename=>__FILE__,lineno=>__LINE__,com2=>'testok',  count=>100);
inc(type=>'block',comment=>'line',hier=>'a.b.c',filename=>__FILE__,lineno=>__LINE__,com2=>'testlow', count=>1);
inc(type=>'block',comment=>'line',hier=>'a.b.c',filename=>__FILE__,lineno=>__LINE__,com2=>'testnone',count=>0);
ok(1);

my $icount=0;
foreach my $item ($cov->items_sorted) {
    print "  Filename ",$item->filename.":".$item->lineno," Count ",$item->count,"\n";
    $icount++;
}
ok($icount==4);

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
