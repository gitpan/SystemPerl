# SystemC - SystemC Perl Interface
# $Id: Port.pm,v 1.6 2001/04/03 21:26:02 wsnyder Exp $
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

package SystemC::Netlist::Port;
use Class::Struct;

use SystemC::Netlist;
use SystemC::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::Port::Struct
	SystemC::Netlist::Subclass);
use strict;

structs('SystemC::Netlist::Port::Struct'
	=>[name     	=> '$', #'	# Name of the port
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   #
	   direction	=> '$', #'	# Direction (in/out/inout)
	   type	 	=> '$', #'	# C++ Type (bool/int)
	   comment	=> '$', #'	# Comment provided by user
	   array	=> '$', #'	# Vectorization
	   module	=> '$', #'	# Module entity belongs to
	   ]);

sub _link {}
sub lint {}

sub print {
    my $self = shift;
    my $indent = shift||0;
    print " "x$indent,"Port:",$self->name(),"  Dir:",$self->direction()
	,"  Type:",$self->type(),"  Array:",$self->array()||"","\n";
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Port - Port for a SystemC Module

=head1 SYNOPSIS

  use SystemC::Netlist;

  ...
  my $port = $module->find_port ('pinname');
  print $port->name;

=head1 DESCRIPTION

SystemC::Netlist creates a port for every connection to the outside
world in the current module.

=head1 ACCESSORS

=over 4

=item $self->array

Any array declaration for the port.

=item $self->comment

Any comment the user placed on the same line as the port.

=item $self->direction

The direction of the port.

=item $self->filename

The filename the port was created in.

=item $self->lineno

The line number the port was created on.

=item $self->module

Reference to the SystemC::Netlist::Module the port is in.

=item $self->name

The name of the port.

=item $self->type

The C++ type of the port.

=back

=head1 MEMBER FUNCTIONS

=over 4

=item $self->print

Prints debugging information for this port.

=back

=head1 SEE ALSO

L<SystemC::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
