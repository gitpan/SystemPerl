# SystemC - SystemC Perl Interface
# $Revision: #24 $$Date: 2002/08/19 $$Author: wsnyder $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# This program is Copyright 2000 by Wilson Snyder.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the GNU General Public License or the
# Perl Artistic License.
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

use Verilog::Netlist;
use SystemC::Netlist;
@ISA = qw(Verilog::Netlist::Cell);
$VERSION = '1.120';
use strict;

######################################################################

sub new_pin {
    my $self = shift;
    # @_ params
    # Create a new pin under this cell
    my $pinref = new SystemC::Netlist::Pin (cell=>$self, @_);
    $self->portname($self->name) if !$self->name;	# Back Version 1.000 compatibility
    $self->pins ($pinref->name(), $pinref);
    return $pinref;
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
		    $self->new_pin (name=>$portref->name, portname=>$portref->name,
				    filename=>'AUTOINST('.$self->module->name.')', lineno=>$self->lineno,
				    netname=>$portref->name, sp_autocreated=>1,)
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
    $fileref->print ("${prefix}// Beginning of SystemPerl automatic instantiation pins\n");
    foreach my $pinref ($self->pins_sorted) {
	if ($pinref->sp_autocreated) {
	    $fileref->printf ("%sSP_PIN(%s, %-20s %-20s // %s\n"
		,$prefix,$self->name,$pinref->name.",",$pinref->port->name.");"
				     ,$pinref->port->direction);
	}
    }
    $fileref->print ("${prefix}// End of SystemPerl automatic instantiation pins\n");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Cell - Cell for a SystemC Module

=head1 DESCRIPTION

This is a superclass of Verilog::Netlist::Cell, derived for a SystemC netlist
pin.

=head1 SEE ALSO

L<Verilog::Netlist::Cell>
L<SystemC::Netlist>
L<Verilog::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
