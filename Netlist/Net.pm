# SystemC - SystemC Perl Interface
# $Revision: 1.52 $$Date: 2005-03-01 17:59:56 -0500 (Tue, 01 Mar 2005) $$Author: wsnyder $
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

package SystemC::Netlist::Net;
use Class::Struct;

use Verilog::Netlist;
use SystemC::Netlist;
@ISA = qw(Verilog::Netlist::Net);
$VERSION = '1.170';
use strict;

# List of basic C++ types and their sizes
use vars qw (%TypeInfo);
%TypeInfo = (bool=>	{ msb=>0,  lsb=>0, cast_type=>undef, },
	     sc_clock=>	{ msb=>0,  lsb=>0, cast_type=>'bool', },
#	     int8_t=>	{ msb=>7,  lsb=>0, cast_type=>undef, },
#	     int16_t=>	{ msb=>15, lsb=>0, cast_type=>undef, },
	     int32_t=>	{ msb=>31, lsb=>0, cast_type=>undef, },
	     int64_t=>	{ msb=>63, lsb=>0, cast_type=>undef, },
#	     int =>	{ msb=>31, lsb=>0, cast_type=>undef, },
#	     uint8_t=>	{ msb=>7,  lsb=>0, cast_type=>undef, },
#	     uint16_t=>	{ msb=>15, lsb=>0, cast_type=>undef, },
	     uint32_t=>	{ msb=>31, lsb=>0, cast_type=>undef, },
	     uint64_t=>	{ msb=>63, lsb=>0, cast_type=>undef, },
#	     uint =>	{ msb=>0,  lsb=>0, cast_type=>undef, },
#	     nint8_t=> 	{ msb=>7,  lsb=>0, cast_type=>undef, },
#	     nint16_t=>	{ msb=>15, lsb=>0, cast_type=>undef, },
	     nint32_t=>	{ msb=>31, lsb=>0, cast_type=>undef, },
	     nint64_t=>	{ msb=>63, lsb=>0, cast_type=>undef, },
	 );

######################################################################
# Accessors

sub cast_type {
    my $self = shift;
    if ($self->is_enum_type) {
	return 'uint32_t';
    } else {
	my $tiref = $TypeInfo{$self->type};
	return $tiref && $tiref->{cast_type};
    }
}

sub is_enum_type {
    my $self = shift;
    return defined $self->module->netlist->{_enum_classes}{$self->type};    
}

######################################################################
# Methods

sub _link {
    my $self = shift;
    # If there is no msb defined, try to pull it based on the type of the signal
    if (!defined $self->msb && defined $self->type) {
	my $tiref = $TypeInfo{$self->type};
	$tiref = $TypeInfo{'uint32_t'} if !$tiref && $self->is_enum_type;
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

sub lint {
    my $self = shift;
    $self->SUPER::lint();
    # We peek into simple sequential logic to see what symbols are referenced
    if ((0 || !$self->module->lesswarn)
	&& $self->_used_in() && !$self->_used_inout() && !$self->_used_out()
	&& !$self->array
	&& !defined $self->module->_code_symbols->{$self->name}) {
	$self->warn("Signal has no drivers: ",$self->name(), "\n");
	$self->dump_drivers(8);
	$self->module->dump() if $Verilog::Netlist::Debug;
    }
}

sub _scdecls {
    my $self = shift;
    my $type = $self->_decls;
    $type = "wire" if $TypeInfo{$type};
    $type = "wire" if $type =~ /^sc_bv\b/;
    return $type;
}

sub verilog_text {
    my $self = shift;
    my @out;
    foreach my $decl ($self->_scdecls) {
	push @out, $decl;
	push @out, " [".$self->msb.":".$self->lsb."]"
	    if defined $self->msb && !($self->msb==0 && $self->lsb==0);
	push @out, " ".$self->name;
	push @out, " ".$self->array if $self->array;
	push @out, ";";
    }
    return (wantarray ? @out : join('',@out));
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

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.com/>.

Copyright 2001-2005 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Verilog::Netlist::Net>
L<SystemC::Netlist>
L<Verilog::Netlist>

=cut
