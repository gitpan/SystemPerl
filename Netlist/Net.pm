# SystemC - SystemC Perl Interface
# $Id: Net.pm,v 1.20 2001/11/16 15:01:41 wsnyder Exp $
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

use Verilog::Netlist;
use SystemC::Netlist;
@ISA = qw(Verilog::Netlist::Net);
$VERSION = '1.000';
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

sub _link {
    my $self = shift;
    # If there is no msb defined, try to pull it based on the type of the signal
    if (!defined $self->msb && defined $self->type) {
	my $tiref = $TypeInfo{$self->type};
	if (defined $tiref) {
	    $self->msb($tiref->{msb});
	    $self->lsb($tiref->{lsb});
	} elsif ($self->type =~ /^sc_bv<(\d+)/) {
	    $self->msb($1-1);
	    $self->lsb(0);
	}
    }
    $self->SUPER::_link();
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Net - Net for a SystemC Module

=head1 DESCRIPTION

This is a superclass of Verilog::Netlist::Net, derived for a SystemC netlist
pin.

=head1 SEE ALSO

L<Verilog::Netlist::Net>
L<SystemC::Netlist>
L<Verilog::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
