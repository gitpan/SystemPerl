# SystemC - SystemC Perl Interface
# $Id: Net.pm,v 1.17 2001/07/12 19:30:24 wsnyder Exp $
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
$VERSION = '0.430';
use strict;

# List of basic C++ types and their sizes
use vars qw (%TypeInfo);
%TypeInfo = (bool=>	{ msb=>0,  lsb=>0, basic_type=>1, },
	     sc_clock=>	{ msb=>0,  lsb=>0, basic_type=>0, },  # Special AutoTrace code
#	     int8_t=>	{ msb=>7,  lsb=>0, basic_type=>1, },
#	     int16_t=>	{ msb=>15, lsb=>0, basic_type=>1, },
	     int32_t=>	{ msb=>31, lsb=>0, basic_type=>1, },
#	     int =>	{ msb=>31, lsb=>0, basic_type=>1, },
#	     uint8_t=>	{ msb=>7,  lsb=>0, basic_type=>1, },
#	     uint16_t=>	{ msb=>15, lsb=>0, basic_type=>1, },
	     uint32_t=>	{ msb=>31, lsb=>0, basic_type=>1, },
#	     uint =>	{ msb=>0,  lsb=>0, basic_type=>1, },
#	     nint8_t=> 	{ msb=>7,  lsb=>0, basic_type=>1, },
#	     nint16_t=>	{ msb=>15, lsb=>0, basic_type=>1, },
	     nint32_t=>	{ msb=>31, lsb=>0, basic_type=>1, },
	 );

######################################################################

structs('new',
	'SystemC::Netlist::Net::Struct'
	=>[name     	=> '$', #'	# Name of the net
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   userdata	=> '%',		# User information
	   #
	   type	 	=> '$', #'	# C++ Type (bool/int)
	   comment	=> '$', #'	# Comment provided by user
	   array	=> '$', #'	# Vector
	   module	=> '$', #'	# Module entity belongs to
	   simple_type	=> '$', #'	# True if is uint (as opposed to sc_signal)
	   # below only after links()
	   port		=> '$', #'	# Reference to port connected to
	   msb		=> '$', #'	# MSB of signal (if known)
	   lsb		=> '$', #'	# LSB of signal (if known)
	   _used_input	=> '$', #'	# Declared as signal, or input to cell
	   _used_output	=> '$', #'	# Declared as signal, or output from cell
	   # below only after autos()
	   autocreated	=> '$', #'	# Created by /*AUTOSIGNAL*/
	   ]);

######################################################################

sub _link {
    my $self = shift;
    # If there is no msb defined, try to pull it based on the type of the signal
    if (!defined $self->msb && defined $self->type) {
	my $tiref = $TypeInfo{$self->type};
	if (defined $tiref) {
	    $self->msb($tiref->{msb});
	    $self->lsb($tiref->{lsb});
	}
    }
}

sub width {
    my $self = shift;
    # Return bit width (if known)
    if (defined $self->msb && defined $self->lsb) {
	return ($self->msb - $self->lsb + 1);
    }
    return undef;
}

sub lint {
    my $self = shift;
    # These tests don't work because we can't determine if sequential logic gen/uses a signal
    if (0&&$self->_used_input() && !$self->_used_output()) {
	$self->warn("Signal is not generated (or needs signal declaration): ",$self->name(), "\n");
    }
    if (0&&$self->_used_output() && !$self->_used_input()
	&& $self->name() !~ /unused/) {
	$self->dump(5);
	$self->port->dump(10) if $self->port;
	$self->warn("Signal is not used (or needs signal declaration): ",$self->name(), "\n");
	flush STDOUT;
	flush STDERR;
    }
}

sub dump {
    my $self = shift;
    my $indent = shift||0;
    print " "x$indent,"Net:",$self->name()
	,"  ",($self->_used_input() ? "I":""),($self->_used_output() ? "O":""),
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

=item $self->dump

Prints debugging information for this net.

=back

=head1 SEE ALSO

L<SystemC::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
