# SystemC - SystemC Perl Interface
# $Id: Pin.pm,v 1.21 2002/03/11 15:52:09 wsnyder Exp $
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

package SystemC::Netlist::Pin;
use Class::Struct;

use Verilog::Netlist;
use SystemC::Netlist;
use SystemC::Netlist::Port;
use SystemC::Netlist::Net;
use SystemC::Netlist::Cell;
use SystemC::Netlist::Module;
@ISA = qw(Verilog::Netlist::Pin);
$VERSION = '1.100';
use strict;

######################################################################
#### Automatics (preprocessing)

sub _autos {
    my $self = shift;
    if ($self->module->_autosignal) {
	if (!$self->net && $self->port) {
	    my $net = $self->module->find_net ($self->netname);
	    $net or $net = $self->module->new_net
		(name=>$self->netname,
		 filename=>$self->module->filename,
		 lineno=>$self->lineno . ':(AUTOSIGNAL)',
		 type=>$self->port->type,
		 comment=>" For ".$self->submod->name, #.".".$self->name, 
		 module=>$self->module, sp_autocreated=>1,)
		->_link;
	}
    }
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Pin - Pin on a SystemC Cell

=head1 DESCRIPTION

This is a superclass of Verilog::Netlist::Pin, derived for a SystemC netlist
pin.

=head1 SEE ALSO

L<Verilog::Netlist::Pin>
L<Verilog::Netlist>
L<SystemC::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
