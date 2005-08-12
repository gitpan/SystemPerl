#!/usr/bin/perl -w
# $Id: 50_spp_inline.t 4305 2005-08-02 13:21:57Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2005 by Wilson Snyder.  This program is free software;
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
