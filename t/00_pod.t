#!/usr/bin/perl -w
# $Id: 00_pod.t 37619 2007-04-30 13:20:11Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2000-2007 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;

eval "use Test::Pod 1.00";
if ($@) {
    print "1..1\n";
    print "ok 1 # skip Test::Pod not installed so ignoring Pod check (harmless)";
} else {
    all_pod_files_ok();
}
