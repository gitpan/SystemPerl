# SystemC - SystemC Perl Interface
# $Id: Cell.pm,v 1.9 2001/04/03 21:26:01 wsnyder Exp $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# This program is Copyright 2000 by Wilson Snyder.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the GNU General Public License or the
# Perl Artistic License, with the exception that it cannot be placed
# on a CD-ROM or similar media for commercial distribution without the
# prior approval of the author.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
# MA 02139, USA.
######################################################################

package SystemC::Netlist::Cell;
use Class::Struct;

use SystemC::Netlist;
use SystemC::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::Cell::Struct
	SystemC::Netlist::Subclass);
use strict;

structs('SystemC::Netlist::Cell::Struct'
	=>[name     	=> '$', #'	# Instantiation name
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   #
	   submodname	=> '$', #'	# Which module it instantiates
	   module	=> '$', #'	# Module reference
	   pins		=> '%',		# List of SystemC::Netlist::Pins
	   _autoinst	=> '$', #'	# Marked with AUTOINST tag
	   # after link():
	   submod	=> '$', #'	# Sub Module reference
	   ]);

sub netlist {
    my $self = shift;
    return $self->module->netlist;
}

sub new_pin {
    my $self = shift;
    # @_ params
    # Create a new pin under this cell
    my $pinref = new SystemC::Netlist::Pin (cell=>$self, @_);
    $self->pins ($pinref->name(), $pinref);
}

sub _link {
    my $self = shift;
    $self->submod($self->netlist->find_module ($self->submodname())) if $self->submodname();
    foreach my $pinref (values %{$self->pins}) {
	$pinref->_link();
    }
}

sub lint {
    my $self = shift;
    if (!$self->submod()) {
        $self->error ($self,"Module reference not found: ",$self->submodname(),,"\n");
    }
    foreach my $pinref (values %{$self->pins}) {
	$pinref->lint();
    }
}

sub print {
    my $self = shift;
    my $indent = shift||0;
    my $norecurse = shift;
    print " "x$indent,"Cell:",$self->name(),"  is-a:",$self->submodname(),"\n";
    if ($self->submod()) {
	$self->submod->print($indent+10, 'norecurse');
    }
    if (!$norecurse) {
	foreach my $pinref ($self->pins_sorted) {
	    $pinref->print($indent+2);
	}
    }
}

sub pins_sorted {
    my $self = shift;
    return (sort {$a->name() cmp $b->name()} (values %{$self->pins}));
}

######################################################################
#### Automatics (Preprocessing)

sub _autos {
    my $self = shift;
    if ($self->_autoinst) {
	if ($self->submod()) {
	    my %conn_ports = ();
	    foreach my $pinref (values %{$self->pins}) {
		$conn_ports{$pinref->name} = 1;
	    }
	    foreach my $portref (values %{$self->submod->ports}) {
		if (!$conn_ports{$portref->name}) {
		    print "  AUTOINST connect ",$self->module->name,"."
			,$self->name," (",$self->submod->name,") port ",$portref->name
			    ,"\n" if $SystemC::Netlist::Debug;
		    $self->new_pin (name=>$portref->name,
				    filename=>'AUTOINST('.$self->module->name.')', lineno=>$self->lineno,
				    netname=>$portref->name, autocreated=>1,)
			->_link();
		}
	    }
	}
    }
    foreach my $pinref (values %{$self->pins}) {
	$pinref->_autos();
    }
}

sub _write_autoinst {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->_write_print ("${prefix}// Beginning of SystemPerl automatic instantiation pins\n");
    foreach my $pinref ($self->pins_sorted) {
	if ($pinref->autocreated) {
	    $fileref->_write_printf ("%sSP_PIN(%s, %-20s %s);\n"
		,$prefix,$self->name,$pinref->name.",",$pinref->port->name);
	}
    }
    $fileref->_write_print ("${prefix}// End of SystemPerl automatic instantiation pins\n");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Cell - Instantiated cell within a SystemC Netlist

=head1 SYNOPSIS

  use SystemC::Netlist;

  ...
  my $cell = $module->find_cell ('cellname');
  print $cell->name;

=head1 DESCRIPTION

SystemC::Netlist creates a cell for every instantiation in the current
module.

=head1 ACCESSORS

=over 4

=item $self->filename

The filename the cell was created in.

=item $self->lineno

The line number the cell was created on.

=item $self->module

Pointer to the module the cell is in.

=item $self->name

The instantiation name of the cell.

=item $self->pins

List of pins connections for the cell.

=item $self->submod

Reference to the SystemC::Netlist::Module the cell instantiates.  Only
valid after the design is linked.

=item $self->submodname

The module name the cell instantiates (under the cell).

=back

=head1 MEMBER FUNCTIONS

=over 4

=item $self->lint

Checks the cell for errors.  Normally called by SystemC::Netlist::lint.

=item $self->new_pin

Creates a new SystemC::Netlist::Pin connection for this cell.

=item $self->print

Prints debugging information for this cell.

=back

=head1 SEE ALSO

L<SystemC::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
