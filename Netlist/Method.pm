# SystemC - SystemC Perl Interface
# $Id: Method.pm 15713 2006-03-13 17:42:48Z wsnyder $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# Copyright 2005-2006 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
######################################################################

package SystemC::Netlist::Method;
use Class::Struct;
use Carp;

use SystemC::Netlist;
use SystemC::Netlist::Net;
use SystemC::Template;
use Verilog::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::Method::Struct
	  Verilog::Netlist::Subclass);
$VERSION = '1.260';
use strict;

structs('new',
	'SystemC::Netlist::Method::Struct'
	=>[name     	=> '$', #'	# Name of the module
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   sensitive	=> '$', #'	# Sensitivity information
	   userdata	=> '%',		# User information
	   ]);
	
######################################################################
######################################################################
#### Methods

######################################################################
#### Linking

sub _link {}

######################################################################
#### Methods

sub verilog_sensitive {
    my $self = shift;
    return undef if !$self->sensitive;
    my $sense = $self->sensitive;
    $sense =~ s/^\s+//;
    $sense =~ s/\s+$//;
    if ($sense =~ /^([a-zA-Z_0-9]+)\.(pos|neg)\(\)$/) {
	return $2."edge $1";
    } else {
	$self->error("Can't understand SP_AUTO_METHOD sensitivity to convert to verilog: $sense");
	return undef;
    }
}


######################################################################
#### Debug

sub dump {
    my $self = shift;
    my $indent = shift||0;
    my $norecurse = shift;
    print " "x$indent,"Method:",$self->name(),"  File:",$self->filename(),"\n";
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Method - Methods in a file

=head1 SYNOPSIS

  use SystemC::Netlist;

=head1 DESCRIPTION

SystemC::Netlist::Method contains information on a method added with SP_AUTO_METHOD.

=head1 ACCESSORS

=over 4

=item $self->name

The method name.

=item $self->sensitive

The sensitivity list of the method.

=back

=head1 MEMBER FUNCTIONS

=over 4

=item $self->dump

Prints debugging information for this file.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.com/>.

Copyright 2005-2006 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SystemC::Netlist>

=cut
