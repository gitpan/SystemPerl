# SystemC - SystemC Perl Interface
# $Revision: #43 $$Date: 2004/11/18 $$Author: ws150726 $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# Copyright 2001-2004 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
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
$VERSION = '1.163';
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

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.com/>.

Copyright 2001-2004 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Verilog::Netlist::Pin>
L<Verilog::Netlist>
L<SystemC::Netlist>

=cut
