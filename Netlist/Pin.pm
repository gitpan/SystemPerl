# SystemC - SystemC Perl Interface
# $Id: Pin.pm,v 1.17 2001/07/30 13:43:08 wsnyder Exp $
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

use SystemC::Netlist;
use SystemC::Netlist::Port;
use SystemC::Netlist::Net;
use SystemC::Netlist::Cell;
use SystemC::Netlist::Module;
use SystemC::Netlist::Pin;
use SystemC::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::Pin::Struct
	SystemC::Netlist::Subclass);
$VERSION = '0.430';
use strict;

structs('new',
	'SystemC::Netlist::Pin::Struct'
	=>[name     	=> '$', #'	# Pin connection
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   userdata	=> '%',		# User information
	   #
	   netname	=> '$', #'	# Net connection
	   cell     	=> '$', #'	# Cell reference
	   # below only after link()
	   net		=> '$', #'	# Net connection reference
	   port		=> '$', #'	# Port connection reference
	   # below only after autos()
	   autocreated	=> '$', #'	# Created by auto()
	   # below by accessor computation
	   #module
	   #submod
	   ]);

sub module {
    my $self = shift;
    return $self->cell->module;
}
sub submod {
    my $self = shift;
    return $self->cell->submod;
}

sub _link {
    my $self = shift;
    if ($self->netname) {
	$self->net($self->module->find_net($self->netname));
	if ($self->net() && $self->port()) {
	    $self->net->_used_input(1) if ($self->port->direction() =~ /in/); # in/inout
	    $self->net->_used_output(1) if ($self->port->direction() =~ /out/); # out/inout
	}
    }
    if ($self->name && $self->submod) {
	$self->port($self->submod->find_port($self->name));
    }
}

sub lint {
    my $self = shift;
    if (!$self->net) {
        $self->error ("Pin's net declaration not found: ",$self->netname(),,"\n");
    }
    if ($self->port && $self->net) {
	my $nettype = $self->net->type;
	my $porttype = $self->port->type;
	if ($nettype ne $porttype) {
	    $self->error("Port pin type $porttype != Net type $nettype: "
			 ,$self->name,"\n");
	}
	my $netdir = "net";
	$netdir = $self->net->port->direction if $self->net->port;
	my $portdir = $self->port->direction;
	if (($netdir eq "in" && $portdir eq "out")
	    #Legal: ($netdir eq "in" && $portdir eq "inout")
	    #Legal: ($netdir eq "out" && $portdir eq "inout")
	    ) {
	    $self->error("Port is ${portdir}put from submodule, but ${netdir}put from this module: "
			 ,$self->name,"\n");
	    #$self->cell->module->netlist->dump;
	}
    }
    if (!$self->port && $self->submod) {
        $self->error ($self,"Port not found in module ",$self->submod->name,": ",$self->name(),,"\n");
    }
}

sub dump {
    my $self = shift;
    my $indent = shift||0;
    print " "x$indent,"Pin:",$self->name(),"  Net:",$self->netname(),"\n";
    if ($self->port) {
	$self->port->dump($indent+10, 'norecurse');
    }
    if ($self->net) {
	$self->net->dump($indent+10, 'norecurse');
    }
}

######################################################################
#### Automatics (preprocessing)

sub _autos {
    my $self = shift;
    if ($self->module->_autosignal) {
	if (!$self->net && $self->port) {
	    $self->module->new_net (name=>$self->netname,
				    filename=>$self->module->filename,
				    lineno=>$self->lineno . ':(AUTOSIGNAL)',
				    type=>$self->port->type,
				    comment=>" For ".$self->submod->name, #.".".$self->name, 
				    module=>$self->module, autocreated=>1,)
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

=head1 SYNOPSIS

  use SystemC::Netlist;

  ...
  my $pin = $cell->find_pin ('pinname');
  print $pin->name;

=head1 DESCRIPTION

SystemC::Netlist creates a pin for every pin connection on a cell.  A Pin
connects a net in the current design to a port on the instantiated cell's
module.

=head1 ACCESSORS

=over 4

=item $self->filename

The filename the pin was created in.

=item $self->lineno

The line number the pin was created on.

=item $self->module

Reference to the SystemC::Netlist::Module the pin is in.

=item $self->name

The name of the pin.

=item $self->port

Reference to the SystemC::Netlist::Port the pin connects to.  Only valid after a link.

=item $self->net

Reference to the SystemC::Netlist::Net the pin connects to.  Only valid after a link.

=item $self->netname

The net name the pin connects to.

=back

=head1 MEMBER FUNCTIONS

=over 4

=item $self->lint

Checks the pin for errors.  Normally called by SystemC::Netlist::lint.

=item $self->dump

Prints debugging information for this pin.

=back

=head1 SEE ALSO

L<SystemC::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
