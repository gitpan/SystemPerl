#!/usr/local/bin/perl -w
# $Revision: #7 $$Date: 2004/01/27 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2004 by Wilson Snyder.  This program is free software;
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
