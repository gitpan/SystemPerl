#!/usr/bin/perl -w
# $Id: 32_example.t 37619 2007-04-30 13:20:11Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2001-2007 by Wilson Snyder.  This program is free software;
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
