# SystemC - SystemC Perl Interface
# $Id: Pin.pm 43371 2007-08-16 14:00:54Z wsnyder $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# Copyright 2001-2007 by Wilson Snyder.  This program is free software;
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
$VERSION = '1.281';
use strict;

######################################################################
#### Automatics (preprocessing)

sub type_match {
    my $self = shift;
    # Override base method
    return 1 if $self->net->type eq $self->port->type;
    my $type1 = $self->net->type;
    my $type2 = $self->port->type;
    my $type1ref = $self->netlist->find_class($type1);
    my $type2ref = $self->netlist->find_class($type2);
    if ($type1ref && $type2ref) {
	# Ok if sp_ui connects to uint32_t
	# But don't allow two different sized sp_ui's to connect.
	return 1 if (($type1ref->convert_type || "") eq $type2
		     || ($type2ref->convert_type || "") eq $type1);
    }
    return undef;
}

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
	   typeregexp	=> '$', #'	# Type regular expression as string
	   typere	=> '$', #'	# Type regular expression compiled
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

SystemPerl is part of the L<http://www.veripool.com/> free SystemC software
tool suite.  The latest version is available from CPAN and from
L<http://www.veripool.com/systemperl.html>.

Copyright 2001-2007 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Verilog::Netlist::Pin>
L<Verilog::Netlist>
L<SystemC::Netlist>

=cut
