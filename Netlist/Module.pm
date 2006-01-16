# SystemC - SystemC Perl Interface
# $Id: Module.pm 11992 2006-01-16 18:59:58Z wsnyder $
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

package SystemC::Netlist::Module;
use Class::Struct;

use Verilog::Netlist;
use SystemC::Netlist;
use SystemC::Netlist::Port;
use SystemC::Netlist::Net;
use SystemC::Netlist::Method;
use SystemC::Netlist::Cell;
use SystemC::Netlist::Pin;
use SystemC::Netlist::AutoCover;
use SystemC::Netlist::AutoTrace;

@ISA = qw(Verilog::Netlist::Module);
$VERSION = '1.250';
use strict;

# Some attributes we use:
#	check_outputs_used => $,	# AUTOATTR setting
#	_sp_methods => @,		# SP_AUTO_METHOD pairings, as array of [func,sensitive]

######################################################################
# Constructors
sub new_net {
    my $self = shift;
    # @_ params
    # Create a new net under this module
    my $netref = new SystemC::Netlist::Net (direction=>'net', array=>'', @_, module=>$self, );
    $self->_nets ($netref->name(), $netref);
    return $netref;
}

sub new_port {
    my $self = shift;
    # @_ params
    # Create a new port under this module
    my $portref = new SystemC::Netlist::Port (@_, module=>$self,);
    $self->_ports ($portref->name(), $portref);
    return $portref;
}

sub new_cell {
    my $self = shift;
    # @_ params
    # Create a new cell under this module
    my $cellref = new SystemC::Netlist::Cell (@_, module=>$self,);
    $self->_cells ($cellref->name(), $cellref);
    return $cellref;
}

sub new_pin_template {
    my $self = shift;
    # @_ params
    # Create a new pin template under this module
    my $templref = new SystemC::Netlist::PinTemplate (@_,);
    push @{$self->_pintemplates}, $templref;
    return $templref;
}

sub new_method {
    my $self = shift;
    # @_ params
    my $attrref = $self->attributes("_sp_methods");
    if (!$attrref) { $attrref={}; $self->attributes("_sp_methods", $attrref); }
    my $methref = new SystemC::Netlist::Method (@_,);
    $attrref->{$methref->name} = $methref;
}

######################################################################
# Accessors

sub _decl_max {
    $_[0]->attributes("_sp_decl_max", $_[1]) if exists $_[1];
    return $_[0]->attributes("_sp_decl_max")||0;
}

sub methods {
    my $attrref = $_[0]->attributes("_sp_methods") || {};
    return values %{$attrref};
}
sub methods_sorted {
    return sort {$a->name cmp $b->name || $a->sensitive cmp $b->sensitive} ($_[0]->methods);
}

######################################################################
#### Automatics (Preprocessing)

sub autos1 {
    my $self = shift;
    # First stage of autos... Builds pins, etc
    $self->_autos1_recurse_inherits($self->netlist->{_class_inherits}{$self->name});
    if ($self->_autoinoutmod) {
	my $frommodname = $self->_autoinoutmod;
	my $fromref = $self->netlist->find_module ($frommodname);
	if (!$fromref && $self->netlist->{link_read}) {
	    print "  Link_Read_Auto ",$frommodname,"\n" if $Verilog::Netlist::Debug;
	    $self->netlist->read_file(filename=>$frommodname, is_libcell=>1,
				      error_self=>$self);
	    $fromref = $self->netlist->find_module ($frommodname);
	}
	if (!$fromref) {
	    $self->warn ("AUTOINOUT_MODULE not found: $frommodname\n");
	} else {
	    # Copy ports
	    foreach my $portref ($fromref->ports_sorted) {
		my $newport = $self->new_port
		    (name	=> $portref->name,
		     filename	=> ($self->filename.":AUTOINOUT_MODULE("
				    .$portref->filename.":"
				    .$portref->lineno.")"),
		     lineno	=> $self->lineno,
		     direction	=> $portref->direction,
		     type	=> $portref->type,
		     comment	=> " From AUTOINOUT_MODULE(".$fromref->name.")",
		     array	=> $portref->array,
		     sp_autocreated=>1,
		     );
	    }
	}
    }
}

sub _autos1_recurse_inherits {
    my $self = shift;
    my $inhsref = shift;
    return if !$inhsref;
    # Recurse inheritance tree looking for pins to inherit
    foreach my $inh (keys %$inhsref) {
	next if $inh eq "sc_module";
	my $fromref = $self->netlist->find_module ($inh);
	print "Module::autos1_inh ",$self->name,"  $inh  $fromref\n" if $Verilog::Netlist::Debug;
	if ($fromref) {
	    # Clone I/O
	    foreach my $portref ($fromref->ports_sorted) {
		my $newport = $self->new_port
		    (name	=> $portref->name,
		     filename	=> ($self->filename.":INHERITED("
				    .$portref->filename.":"
				    .$portref->lineno.")"),
		     lineno	=> $self->lineno,
		     direction	=> $portref->direction,
		     type	=> $portref->type,
		     comment	=> " From INHERITED(".$fromref->name.")",
		     array	=> $portref->array,
		     );
		$newport->inherited(1);
	    }
	    foreach my $netref ($fromref->nets_sorted) {
		my $newnet = $self->new_net
		    (name	=> $netref->name,
		     filename	=> ($self->filename.":INHERITED("
				    .$netref->filename.":"
				    .$netref->lineno.")"),
		     lineno	=> $self->lineno,
		     type	=> $netref->type,
		     comment	=> " From INHERITED(".$fromref->name.")",
		     array	=> $netref->array,
		     );
		$newnet->inherited(1);
	    }
	    # Recurse its children
	    $self->_autos1_recurse_inherits($self->netlist->{_class_inherits}{$inh});
	}
    }
}

sub autos2 {
    my $self = shift;
    # Below must be after creating above autoinouts
    foreach my $cellref ($self->cells) {
	$cellref->_autos();
    }
    $self->link();
}

sub _write_autoinit {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->print ("${prefix}// Beginning of SystemPerl automatic initializer\n");
    my $sep = ":";
    foreach my $netref (sort {($a->_decl_order <=> $b->_decl_order
			       || $a->name cmp $b->name)   # AUTOSIGNALS appear in name order
			      } $self->ports) {
	if (!$netref->inherited) { # If ever do nets, need this: !$netref->simple_type
	    my $vec = $netref->array || "";
	    $fileref->print ($prefix,$sep,$netref->name,'("',$netref->name,'")',"\n");
	    $sep = ",";
	}
    }
    $fileref->print ("${prefix}// End of SystemPerl automatic initializer\n");
}

sub _write_autosignal {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->print ("${prefix}// Beginning of SystemPerl automatic signals\n");
    foreach my $netref ($self->nets_sorted) {
	 if ($netref->sp_autocreated) {
	     my $vec = $netref->array || "";
	     $fileref->printf ("%ssc_signal%-20s %-20s //%s\n"
			       ,$prefix,"<".$netref->sc_type." >",$netref->name.$vec.";",
			       $netref->comment);
	 }
    }
    $fileref->print ("${prefix}// End of SystemPerl automatic signals\n");
}

sub _write_autoinout {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->print ("${prefix}// Beginning of SystemPerl automatic ports\n");
    foreach my $portref ($self->ports_sorted) {
	 if ($portref->sp_autocreated) {
	     my $vec = $portref->array || "";
	     $vec = "[$vec]" if $vec;
	     # Space below in " >" to prevent >> C++ operator
	     my $type = "sc_".$portref->direction."<".$portref->net->sc_type." >";
	     $fileref->printf ("%s%-29s %-20s //%s\n"
			       ,$prefix
			       ,$type
			       ,$portref->name.$vec.";", $portref->comment);
	 }
    }
    $fileref->print ("${prefix}// End of SystemPerl automatic ports\n");
}

sub _write_autosubcell_decl {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->print ("${prefix}// Beginning of SystemPerl automatic subcells\n");
    foreach my $cellref ($self->cells_sorted) {
	my $name = $cellref->name; my $bra = "";
	next if ($self->_celldecls($name));
	if ($name =~ /^(.*?)\[(.*)\]/) {
	    $name = $1; $bra = $2;
	    next if ($self->_celldecls($name));
	    $cellref->warn ("Vectored cell $name needs manual: SP_CELL_DECL(",
			    $cellref->submodname,",",$name,"[/*MAXNUMBER*/]);\n");
	    next;
	}
	$fileref->printf ("%sSP_CELL_DECL(%-20s %s);\n"
				 ,$prefix,$cellref->submodname.",",$name);
    }
    $fileref->print ("${prefix}// End of SystemPerl automatic subcells\n");
}

sub _write_autodecls {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->print ("${prefix}// Beginning of SystemPerl automatic declarations\n");
    if (!$self->_ctor()) {
	$fileref->print("${prefix}SC_CTOR(",$self->name,");\n");
    }

    # Methods
    my $last_meth = "";
    foreach my $meth ($self->methods_sorted) {
	$fileref->print($prefix."private:\n") if ($last_meth eq "");
	if ($last_meth ne $meth) {
	    $last_meth = $meth;
	    $fileref->print($prefix."void ".$meth->name."();  // SP_AUTO_METHOD at ".$meth->fileline."\n");
	}
    }
    $fileref->print($prefix."public:\n") if ($last_meth ne "");

    if ($self->_autotrace('on')
	&& $self->netlist->tracing) {
	$fileref->print
	    ("#if WAVES\n",
	     "${prefix}void trace (SpTraceFile *tfp, int levels, int options=0);\n",
	     "${prefix}static void\ttraceInit",
	     " (SpTraceVcd* vcdp, void* userthis, uint32_t code);\n",
	     "${prefix}static void\ttraceFull",
	     " (SpTraceVcd* vcdp, void* userthis, uint32_t code);\n",
	     "${prefix}static void\ttraceChg",
	     " (SpTraceVcd* vcdp, void* userthis, uint32_t code);\n",
	     "#endif\n");
    }
    SystemC::Netlist::AutoCover::_write_autocover_decl($fileref,$prefix,$self);
    $fileref->print ("${prefix}// End of SystemPerl automatic declarations\n");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Module - Module on a SystemC Cell

=head1 DESCRIPTION

This is a superclass of Verilog::Netlist::Module, derived for a SystemC netlist
pin.

=head1 DISTRIBUTION

The latest version is available from CPAN and from L<http://www.veripool.com/>.

Copyright 2001-2006 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<Verilog::Netlist::Module>
L<Verilog::Netlist>
L<SystemC::Netlist>

=cut
