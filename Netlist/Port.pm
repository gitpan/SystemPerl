# SystemC - SystemC Perl Interface
# $Revision: 1.41 $$Date: 2005-03-02 11:34:26 -0500 (Wed, 02 Mar 2005) $$Author: wsnyder $
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

package SystemC::Netlist::Port;
use Class::Struct;

use Verilog::Netlist;
use SystemC::Netlist;
@ISA = qw(Verilog::Netlist::Port);
$VERSION = '1.171';
use strict;

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

The latest version is available from CPAN and from L<http://www.veripool.com/>.

Copyright 2001-2005 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Verilog::Netlist::Port>
L<Verilog::Netlist>
L<SystemC::Netlist>

=cut
