#!/usr/bin/perl -w
# $Revision: 1.10 $$Date: 2005-03-01 17:59:56 -0500 (Tue, 01 Mar 2005) $$Author: wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2005 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.

use strict;
use Test;

BEGIN { plan tests => 2 }
BEGIN { require "t/test_utils.pl"; }

use SystemC::Netlist;
ok(1);

{
    print "Checking example in Netlist.pm\n";
    my $nl = new SystemC::Netlist ();
    foreach my $file ('example/ExMod.sp', 'example/ExModSub.sp') {
	$nl->read_file (filename=>$file,
			strip_autos=>1);
    }
    $nl->link();
    $nl->autos();
    $nl->lint();
    $nl->exit_if_error();

    foreach my $mod ($nl->modules_sorted) {
	show_hier ($mod, "  ");
    }

    sub show_hier {
	my $mod = shift;
	my $indent = shift;
	print $indent,"Module ",$mod->name,"\n";
	foreach my $cell ($mod->cells_sorted) {
	    show_hier ($cell->submod, $indent."  ".$cell->name."  ");
	}
    }
}
ok(1);
