# SystemC - SystemC Perl Interface
# $Id: CoverGroup.pm 62129 2008-10-01 22:52:20Z wsnyder $
# Author: Bobby Woods-Corwin <me@alum.mit.edu>
######################################################################
#
# Copyright 2001-2008 by Bobby Woods-Corwin.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
######################################################################

package SystemC::Netlist::CoverGroup;
use Class::Struct;

use Verilog::Netlist;
use Verilog::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::CoverGroup::Struct
	  Verilog::Netlist::Subclass);
$VERSION = '1.300';
use strict;

structs('new',
	'SystemC::Netlist::CoverGroup::Struct'
	=>[name     	=> '$', #'	# Instantiation number
	   coverpoints  => '@', #'	# Coverpoints in this group
	   description  => '$', #'      # description of the group
	   page         => '$', #'      # HTML page name; default group name
	   per_instance => '$', #'      # per_instance coverage? default 0
	   #
	   module	=> '$', #'	# Module containing statement
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   ]);

######################################################################
#### Accessors

sub logger { return $_[0]->module->logger; }

######################################################################
#### Module additions

package SystemC::Netlist::Module;

our $openCovergroup;

sub close_new_covergroup {
    my $self = shift;

    undef $openCovergroup;
}

sub current_covergroup {
    my $self = shift;

    if (!defined $openCovergroup) {
	# Create a new coverage entry under this module
	my $covergroupref = new SystemC::Netlist::CoverGroup
	    (module       => $self,
	     lineno       => $self->lineno,
	     filename     => $self->filename,
	     description  => "",
	     per_instance => 0,
	     );
	$openCovergroup = $covergroupref;
    }
    return $openCovergroup;
}

package SystemC::Netlist::CoverGroup;

######################################################################
#### Automatics (Preprocessing)

sub covergroup_sample_text {
    my $self = shift;
    my $prefix = shift;

    my $name = $self->name;

    my $out = $prefix;
    $out .= "/* group name = $name */\n";

    foreach my $point (@{$self->coverpoints}) {
	bless $point, "SystemC::Netlist::CoverPoint";
	$out .= $point->coverpoint_sample_text($name);
	my $pointname = $point->name;
    }

    return $out;
}

sub add_point {
    my $self = shift;
    my $point = shift;

    #print "adding point to group\n";

    push @{$self->coverpoints}, $point;
}

sub add_desc {
    my $self = shift;
    my $desc = shift;

    #print "adding desc to group\n";

    # remove quotes from string - Apparently the parser leaves them in
    #$desc=~ s/\"//g;

    $self->description($desc);
}

sub add_page {
    my $self = shift;
    my $page = shift;

    $self->page($page);
}

sub set_per_instance {
    my $self = shift;
    my $val = shift;

    $self->per_instance($val);
}

sub _write_covergroup_decl {
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    return if !$SystemC::Netlist::File::outputting;

    foreach my $covergroupref (sort {$a->name cmp $b->name}
			       (values %{$modref->_covergroups})) {
	foreach my $point (@{$covergroupref->coverpoints}) {
	    bless $point, "SystemC::Netlist::CoverPoint";
	    $point->_write_coverpoint_decl($fileref,$prefix,$modref,$covergroupref);
	}
    }
}

sub _write_covergroup_incl {
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    return if !$SystemC::Netlist::File::outputting;
    # NOP
}

sub _write_covergroup_ctor {
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    return if !$SystemC::Netlist::File::outputting;

    my $mod = $modref->name;
    $fileref->print("    // Coverage Groups\n");
    foreach my $covergroupref (sort {$a->name cmp $b->name}
			       (values %{$modref->_covergroups})) {
	foreach my $point (@{$covergroupref->coverpoints}) {
	    bless $point, "SystemC::Netlist::CoverPoint";
	    $point->_write_coverpoint_ctor($fileref,$prefix,$modref,$covergroupref);
	}
    }
}

sub _write_covergroup_impl {
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    # NOP
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::CoverGroup - Coverage group routines

=head1 DESCRIPTION

SystemC::Netlist::CoverGroup creates the SP_COVERGROUP features.
It is called from SystemC::Netlist::Module.

=head1 DISTRIBUTION

SystemPerl is part of the L<http://www.veripool.org/> free SystemC software
tool suite.  The latest version is available from CPAN and from
L<http://www.veripool.org/systemperl>.

Copyright 2001-2008 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>,
Bobby Woods-Corwin <me@alum.mit.edu>

=head1 SEE ALSO

L<SystemC::Netlist::Module>

