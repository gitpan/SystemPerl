#!/usr/bin/perl -w
# $Revision: 1.10 $$Date: 2005-03-01 17:59:56 -0500 (Tue, 01 Mar 2005) $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2005 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;

BEGIN { plan tests => 4 }
BEGIN { require "t/test_utils.pl"; }

use SystemC::Netlist;
ok(1);

{
    my $nl = new SystemC::Netlist (link_read_nonfatal=>1,);
    ok($nl);

    $nl->read_file (filename=>"t/15_notfound.sp");
    ok($nl);

    $nl->link();
    ok($nl);
}
