# SystemC - SystemC Perl Interface
# $Revision: 1.45 $$Date: 2005-05-23 11:26:07 -0400 (Mon, 23 May 2005) $$Author: wsnyder $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# Copyright 2001-2005 by Wilson Snyder.  This program is free software;
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
$VERSION = '1.200';
use strict;

######################################################################
#### Automatics (preprocessing)

sub _autos {
    my $self = shift;
    if (my $decl_start = $self->module->_autosignal) {
	if (!$self->net && $self->port) {
	    my $net = $self->module->find_net ($self->netname);
	    if (!$net) {
		$net = $self->module->new_net
		    (name=>$self->netname,
		     filename=>$self->module->filename,
		     lineno=>$self->lineno . ':(AUTOSIGNAL)',
		     type=>$self->port->type,
		     comment=>" For ".$self->submod->name, #.".".$self->name, 
		     module=>$self->module, sp_autocreated=>1,)
		    ->_link;
		# We need to track where we insert this, so we can insert
		# constructors in proper order
		$net->_decl_order($decl_start);
	    }
	}
    }
}

######################################################################

package SystemC::Netlist::PinTemplate;
use Class::Struct;
use Verilog::Netlist::Subclass;
use vars qw(@ISA);
@ISA = qw(SystemC::Netlist::PinTemplate::Struct
	  Verilog::Netlist::Subclass);
use strict;

structs('new',
	'SystemC::Netlist::PinTemplate::Struct'
	=>[filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   #
	   cellregexp	=> '$', #'	# Cell regular expression as string
	   cellre	=> '$', #'	# Cell regular expression compiled
	   pinregexp	=> '$', #'	# Pin regular expression as string
	   pinre	=> '$', #'	# Pin regular expression compiled
	   netregexp	=> '$', #'	# Net regular expression as string
	   ]);

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

Copyright 2001-2005 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Verilog::Netlist::Pin>
L<Verilog::Netlist>
L<SystemC::Netlist>

=cut
