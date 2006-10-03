# SystemC - SystemC Perl Interface
# $Id: Port.pm 25920 2006-10-03 15:48:21Z wsnyder $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# Copyright 2001-2006 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
######################################################################

package SystemC::Netlist::Port;
use Class::Struct;

use Verilog::Netlist;
use SystemC::Netlist;
@ISA = qw(Verilog::Netlist::Port);
$VERSION = '1.272';
use strict;

######################################################################
#### Accessors

sub inherited {
    $_[0]->attributes("_sp_inherited", $_[1]) if exists $_[1];
    return $_[0]->attributes("_sp_inherited")||0;
}

sub _decl_order {
    $_[0]->attributes("_sp_decl_order", $_[1]) if exists $_[1];
    return $_[0]->attributes("_sp_decl_order")||0;
}

sub iotype {
    # Type including I/O direction
    return "sc_".$_[0]->direction."<".($_[0]->net->sc_type || $_[0]->type)." >";
}

######################################################################
#### Methods

sub lint {
    my $self = shift;
    $self->SUPER::lint();
    if ($self->module->attributes('check_outputs_used')
	&& ($self->direction eq "out")
	&& !defined $self->module->_code_symbols->{$self->name}
	&& $self->netlist->{lint_checking}
	) {
	$self->warn("Module with AUTOATTR(check_outputs_used) is missing reference: ",$self->name(), "\n");
	$self->dump_drivers(8);
    }
}

sub verilog_text {
    my $self = shift;
    return $self->net->verilog_text(@_);
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Port - Port for a SystemC Module

=head1 DESCRIPTION

This is a superclass of Verilog::Netlist::Port, derived for a SystemC netlist
port.

=head1 DISTRIBUTION

SystemPerl is part of the L<http://www.veripool.com/> free SystemC software
tool suite.  The latest version is available from CPAN and from
L<http://www.veripool.com/systemperl.html>.

Copyright 2001-2006 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Verilog::Netlist::Port>
L<Verilog::Netlist>
L<SystemC::Netlist>

=cut
