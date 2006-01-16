#!/usr/bin/perl -w
# $Id: 80_gcc.t 11992 2006-01-16 18:59:58Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2006 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;
use Config;

BEGIN { plan tests => 6 }
BEGIN { require "t/test_utils.pl"; }

ok(1);
require "t/9x_common_build.pl";

