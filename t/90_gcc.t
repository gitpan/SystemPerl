#!/usr/local/bin/perl -w
# $Revision: #4 $$Date: 2002/07/16 $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package

use strict;
use Test;
use Config;

BEGIN { plan tests => 5 }
BEGIN { require "t/test_utils.pl"; }

ok(1);
require "t/9x_common_build.pl";

