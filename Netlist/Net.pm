# SystemC - SystemC Perl Interface
# $Id: Net.pm,v 1.5 2001/04/03 21:26:01 wsnyder Exp $
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

package SystemC::Netlist::Net;
use Class::Struct;

use SystemC::Netlist;
use SystemC::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::Net::Struct
	SystemC::Netlist::Subclass);
use strict;

structs('SystemC::Netlist::Net::Struct'
	=>[name     	=> '$', #'	# Name of the net
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   array	=> '$', #'	# Vector
	   #
	   type	 	=> '$', #'	# C++ Type (bool/int)
	   comment	=> '$', #'	# Comment provided by user
	   module	=> '$', #'	# Module entity belongs to
	   # below only after autos()
	   autocreated	=> '$', #'	# Created by /*AUTOSIGNAL*/
	   ]);

sub _link {}

sub lint {
    my $self = shift;
    if ($self->module->find_port ($self->name)) {
      $self->error ("Net redeclares existing port: ",$self->name,"\n");
    }
}

sub print {
    my $self = shift;
    my $indent = shift||0;
    print " "x$indent,"Net:",$self->name(),
	,"  Type:",$self->type(),"  Array:",$self->array()||"","\n";
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Net - Net for a SystemC Module

=head1 SYNOPSIS

  use SystemC::Netlist;

  ...
  my $net = $module->find_net ('signalname');
  print $net->name;

=head1 DESCRIPTION

SystemC::Netlist creates a net for every sc_signal declaration in the
current module.

=head1 ACCESSORS

=over 4

=item $self->array

Any array declaration for the net.

=item $self->comment

Any comment the user placed on the same line as the net.

=item $self->filename

The filename the net was created in.

=item $self->lineno

The line number the net was created on.

=item $self->module

Reference to the SystemC::Netlist::Module the net is in.

=item $self->name

The name of the net.

=item $self->type

The C++ type of the net.

=back

=head1 MEMBER FUNCTIONS

=over 4

=item $self->lint

Checks the net for errors.  Normally called by SystemC::Netlist::lint.

=item $self->print

Prints debugging information for this net.

=back

=head1 SEE ALSO

L<SystemC::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
