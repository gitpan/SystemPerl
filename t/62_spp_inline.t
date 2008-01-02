#!/usr/bin/perl -w
# $Id: 62_spp_inline.t 49154 2008-01-02 14:22:02Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2008 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;

BEGIN { plan tests => 2 }
BEGIN { require "t/test_utils.pl"; }

print "Checking sp_preproc (Inline mode)...\n";

run_system ("cp example/*.sp* test_dir");
ok(1);

run_system ("cd test_dir && ${PERL} ../sp_preproc --inline *.sp");
ok(1);
