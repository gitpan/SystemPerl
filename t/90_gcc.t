#!/usr/bin/perl -w
# $Revision: #8 $$Date: 2004/07/19 $$Author: ws150726 $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2004 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;
use Config;

BEGIN { plan tests => 6 }
BEGIN { require "t/test_utils.pl"; }

ok(1);
require "t/9x_common_build.pl";

