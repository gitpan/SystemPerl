#!/usr/bin/perl -w
# $Id: 02_help.t 59184 2008-08-15 14:47:22Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2007-2008 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License or the Perl Artistic License.

use strict;
use Test;

BEGIN { require "t/test_utils.pl"; }
my @execs = glob("blib/script/[a-z]*");
plan tests => (3 * ($#execs+1));

foreach my $exe (@execs) {
    print "Doc test of: $exe\n";
    ok (-e $exe);
    my $help = `$PERL $exe --help 2>&1`;
    ok ($help =~ /DISTRIBUTION/);
    $help = `$PERL $exe --version 2>&1`;
    ok ($help =~ /Version.*[0-9]/);
}
