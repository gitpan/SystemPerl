# SystemC - SystemC Perl Interface
# $Revision: 1.46 $$Date: 2005-03-21 09:43:43 -0500 (Mon, 21 Mar 2005) $$Author: wsnyder $
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

package SystemC::Netlist::Cell;
use Class::Struct;

use Verilog::Netlist;
use SystemC::Netlist;
@ISA = qw(Verilog::Netlist::Cell);
$VERSION = '1.190';
use strict;

######################################################################

sub new_pin {
    my $self = shift;
    # @_ params
    # Create a new pin under this cell
    my $pinref = new SystemC::Netlist::Pin (cell=>$self, @_);
    $self->portname($self->name) if !$self->name;	# Back Version 1.000 compatibility
    $self->_pins ($pinref->name(), $pinref);
    return $pinref;
}

######################################################################
#### Automatics (Preprocessing)

sub _autos_connect_port {
    my $self = shift;
    my $portref = shift;

    my $netname = $portref->name;
    # Search for a template for this
    my $cellname = $self->name;
    my $comment;
    foreach my $templref (@{$self->module->_pintemplates}) {
	my $cellre = $templref->cellre;
	if ($cellname =~ /$cellre/) {
	    my $pinre = $templref->pinre;
	    if ($netname =~ /$pinre/) {
		my $cellpin_regexp = "^".$templref->cellregexp . "####" . $templref->pinregexp.'$';
		my $cellpin = $cellname . "####" . $netname;
		my $replace = $templref->netregexp;
		# You can't use s/$compile/$compile/ directly.  We could make a eval{}, but
		# we'll do it the way some C code might eventually have to...
		if ($cellpin =~ m/$cellpin_regexp/) {
		    my $a=$1; my $b=$2; my $c=$3; my $d=$4; my $e=$5; my $f=$6; my $g=$7; my $h=$8; my $i=$9;
		    $replace =~ s/\$1/$a/; $replace =~ s/\$2/$b/;  $replace =~ s/\$3/$c/; $replace =~ s/\$4/$d/;
		    $replace =~ s/\$5/$e/; $replace =~ s/\$6/$f/;  $replace =~ s/\$g/$c/; $replace =~ s/\$8/$h/;
		    $replace =~ s/\$9/$i/;
		    $netname = $replace;
		    $comment = "Templated on ".$templref->filename.":".$templref->lineno;
		} else {
		    $self->error("Bad regexp in expanding AUTO_TEMPLATE, Cellpin='$cellpin_regexp', Cellpin='$cellpin', Replace='$replace'\n");
		}
	    }
	}
    }

    print "  AUTOINST connect ",$self->module->name,"."
	,$self->name," (",$self->submod->name,") port ",$portref->name
	," to ",$netname,"\n" if $SystemC::Netlist::Debug;
    $self->new_pin (name=>$portref->name, portname=>$portref->name,
		    filename=>'AUTOINST('.$self->module->name.')', lineno=>$self->lineno,
		    netname=>$netname, sp_autocreated=>($comment||1),)
	->_link();
}

sub _autos {
    my $self = shift;
    if ($self->_autoinst) {
	if ($self->submod()) {
	    my %conn_ports = ();
	    foreach my $pinref ($self->pins) {
		$conn_ports{$pinref->name} = 1;
	    }
	    foreach my $portref ($self->submod->ports) {
		if (!$conn_ports{$portref->name}) {
		    $self->_autos_connect_port($portref);
		}
	    }
	}
    }
    foreach my $pinref ($self->pins) {
	$pinref->_autos();
    }
}

sub _write_autoinst {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->print ("${prefix}// Beginning of SystemPerl automatic instantiation pins\n");
    foreach my $pinref ($self->pins_sorted) {
	if ($pinref->sp_autocreated) {
	    $fileref->printf ("%sSP_PIN(%s, %-20s %-20s // %s%s\n"
			      ,$prefix,$self->name,$pinref->name.",",$pinref->port->name.");"
			      ,$pinref->port->direction
			      ,(($pinref->sp_autocreated ne '1')?" ".$pinref->sp_autocreated:"")
			      );
	}
    }
    $fileref->print ("${prefix}// End of SystemPerl automatic instantiation pins\n");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Cell - Cell for a SystemC Module

=head1 DESCRIPTION

This is a superclass of Verilog::Netlist::Cell, derived for a SystemC netlist
pin.

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.com/>.

Copyright 2001-2005 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Verilog::Netlist::Cell>
L<SystemC::Netlist>
L<Verilog::Netlist>

=cut
