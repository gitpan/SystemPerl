# SystemC - SystemC Perl Interface
# $Id: Class.pm 11992 2006-01-16 18:59:58Z wsnyder $
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

package SystemC::Netlist::Class;
use Class::Struct;
use Carp;

use SystemC::Netlist;
use SystemC::Netlist::Net;
use SystemC::Template;
use Verilog::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::Class::Struct
	  Verilog::Netlist::Subclass);
$VERSION = '1.250';
use strict;

structs('new',
	'SystemC::Netlist::Class::Struct'
	=>[name     	=> '$', #'	# Name of the module
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   msb	 	=> '$', #'	# MSB bit #
	   lsb		=> '$', #'	# LSB bit #
	   stored_lsb	=> '$', #'	# Bit number of signal stored in bit 0  (generally lsb)
	   cast_type	=> '$', #'	# What to cast to for tracing
	   convert_type	=> '$', #'	# What to output if transforming sp_ui's
	   is_enum	=> '$', #'	# Maps to enum type
	   netlist	=> '$', #'	# Netlist is a member of
	   userdata	=> '%',		# User information
	   #
	   # For special procedures
	   _nets	=> '%',		# List of nets if this is tracable
	   ]);
	
######################################################################
# List of basic C++ types and their sizes

our %GenerateInfo
    = (bool=>		[ msb=>0,  lsb=>0, cast_type=>undef, ],
       sc_clock=>	[ msb=>0,  lsb=>0, cast_type=>'bool', ],
       int8_t=>		[ msb=>7,  lsb=>0, cast_type=>undef, ],
       int16_t=>	[ msb=>15, lsb=>0, cast_type=>undef, ],
       int32_t=>	[ msb=>31, lsb=>0, cast_type=>undef, ],
       int64_t=>	[ msb=>63, lsb=>0, cast_type=>undef, ],
#      int =>		[ msb=>31, lsb=>0, cast_type=>undef, ],
       uint8_t=>	[ msb=>7,  lsb=>0, cast_type=>undef, ],
       uint16_t=>	[ msb=>15, lsb=>0, cast_type=>undef, ],
       uint32_t=>	[ msb=>31, lsb=>0, cast_type=>undef, ],
       uint64_t=>	[ msb=>63, lsb=>0, cast_type=>undef, ],
#      uint =>		[ msb=>0,  lsb=>0, cast_type=>undef, ],
       nint8_t=> 	[ msb=>7,  lsb=>0, cast_type=>undef, ],
       nint16_t=>	[ msb=>15, lsb=>0, cast_type=>undef, ],
       nint32_t=>	[ msb=>31, lsb=>0, cast_type=>undef, ],
       nint64_t=>	[ msb=>63, lsb=>0, cast_type=>undef, ],
       );

######################################################################
######################################################################
#### Netlist construction

sub generate_class {
    my $netlist = shift;
    my $name = shift;
    # We didn't find a class already declared of the specified type.
    # See if it matches a C++ standard type, and if so, add it.
    if ($GenerateInfo{$name}) {
	return $netlist->new_class(name=>$name,
				   @{$GenerateInfo{$name}});
    }
    elsif ($name =~ /^sc_bv<(\d+)>$/) {
	return $netlist->new_class(name=>$name,
				   msb=>($1-1), lsb=>0, cast_type=>undef);
    }
    elsif ($name =~ /^sp_ui<(\d+),(\d+)>$/) {
	my $msb = $1;  my $lsb = $2;
	my $out = ((($msb==0 && $lsb==0) && "bool")
		   || (($msb<=31) && "uint32_t")
		   || (($msb<=63) && "uint64_t")
		   || "sc_bv<".($msb+1).">");
	return $netlist->new_class(name=>$name, convert_type=>$out,
				   msb=>$msb, lsb=>$lsb, stored_lsb=>0, cast_type=>undef);
    }
    elsif ($netlist->{_enum_classes}{$name}) {
	return $netlist->new_class(name=>$name, is_enum=>1,
				   msb=>31, lsb=>0, cast_type=>'uint32_t');
    }
    return undef;
}

######################################################################
######################################################################
#### Accessors

sub sc_type { return $_[0]->convert_type || $_[0]->name; }

sub is_sc_bv {
    my $self = shift;
    return ($self->sc_type =~ /^sc_bv/);
}

######################################################################
######################################################################
#### Nets

# Constructors
sub new_net {
    my $self = shift;
    # @_ params
    # Create a new net under this module
    my $netref = new SystemC::Netlist::Net (direction=>'net', array=>'', @_, module=>$self, );
    $self->_nets ($netref->name(), $netref);
    return $netref;
}

######################################################################
#### Nets
# These are compatible with Module's methods so the reader doesn't need to know
# if it is adding to a module or a class

sub find_net {
    my $self = shift;
    my $search = shift;
    return $self->_nets->{$search};
}

sub _decl_order {}
sub _decl_max { return 1;}

sub nets {
    return (values %{$_[0]->_nets});
}
sub nets_sorted {
    return (sort {$a->name() cmp $b->name()} (values %{$_[0]->_nets}));
}

######################################################################
#### Linking

sub _link {
    my $self = shift;
    foreach my $netref ($self->nets_sorted) {
	$netref->_link();
    }
}

######################################################################
#### Debug

sub dump {
    my $self = shift;
    my $indent = shift||0;
    my $norecurse = shift;
    print " "x$indent,"Class:",$self->name(),"  File:",$self->filename(),"\n";
    if (!$norecurse) {
	foreach my $netref ($self->nets_sorted) {
	    $netref->dump($indent+2);
	}
    }
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Class - File containing SystemC code

=head1 SYNOPSIS

  use SystemC::Netlist;

  my $nl = new SystemC::Netlist;
  my $fileref = $nl->read_file (filename=>'filename');
  $fileref->write (filename=>'new_filename',
		   expand_autos=>1,);

=head1 DESCRIPTION

SystemC::Netlist::Class allows SystemC files to be read and written.

=head1 ACCESSORS

=over 4

=item $self->basename

The filename of the file with any path and . suffix stripped off.

=item $self->name

The filename of the file.

=back

=head1 MEMBER FUNCTIONS

=over 4

=item $self->read

Generally called as $netlist->read_file.  Pass a hash of parameters.  Reads
the filename=> parameter, parsing all instantiations, ports, and signals,
and creating SystemC::Netlist::Module structures.  The optional
preserve_autos=> parameter prevents default ripping of /*AUTOS*/ out for
later recomputation.

=item $self->write

Pass a hash of parameters.  Writes the filename=> parameter with the
contents of the previously read file.  If the expand_autos=> parameter is
set, /*AUTO*/ comments will be expanded in the output.  If the
as_implementation=> parameter is set, only implementation code (.cpp) will
be written.  If the as_interface=> parameter is set, only interface code
(.h) will be written.

=item $self->dump

Prints debugging information for this file.

=back

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.com/>.

Copyright 2001-2006 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SystemC::Netlist>

=cut
