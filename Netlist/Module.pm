# SystemC - SystemC Perl Interface
# $Revision: #51 $$Date: 2003/05/06 $$Author: wsnyder $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# This program is Copyright 2000 by Wilson Snyder.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the GNU General Public License or the
# Perl Artistic License.
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

package SystemC::Netlist::Module;
use Class::Struct;

use Verilog::Netlist;
use SystemC::Netlist;
use SystemC::Netlist::Port;
use SystemC::Netlist::Net;
use SystemC::Netlist::Cell;
use SystemC::Netlist::Pin;
use SystemC::Netlist::AutoCover;
use SystemC::Netlist::AutoTrace;

@ISA = qw(Verilog::Netlist::Module);
$VERSION = '1.140';
use strict;

sub new_net {
    my $self = shift;
    # @_ params
    # Create a new net under this module
    my $netref = new SystemC::Netlist::Net (direction=>'net', @_, module=>$self, );
    $self->nets ($netref->name(), $netref);
    return $netref;
}

sub new_port {
    my $self = shift;
    # @_ params
    # Create a new port under this module
    my $portref = new SystemC::Netlist::Port (@_, module=>$self,);
    $self->ports ($portref->name(), $portref);
    return $portref;
}

sub new_cell {
    my $self = shift;
    # @_ params
    # Create a new cell under this module
    my $cellref = new SystemC::Netlist::Cell (@_, module=>$self,);
    $self->cells ($cellref->name(), $cellref);
    return $cellref;
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
	    }
	    # Recurse its children
	    $self->_autos1_recurse_inherits($self->netlist->{_class_inherits}{$inh});
	}
    }
}

sub autos2 {
    my $self = shift;
    # Below must be after creating above autoinouts
    foreach my $cellref (values %{$self->cells}) {
	$cellref->_autos();
    }
    $self->link();
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
		 ,$prefix,"<".$netref->type." >",$netref->name.$vec.";", $netref->comment);
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
	     $fileref->printf ("%ssc_%-26s %-20s //%s\n"
			       ,$prefix
			       ,$portref->direction."<".$portref->type." >"
			       # Space above in " >" to prevent >> C++ operator
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
    if ($self->_autotrace('on')) {
	$fileref->print
	    ("#if WAVES\n",
	     "${prefix}void trace (SpTraceFile *tfp, int levels, int options=0);\n",
	     "${prefix}static void\ttraceInit",
	     " (SpTraceVcd* vcdp, void* userthis, uint32_t code);\n",
	     "${prefix}static void\ttraceChange",
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

=head1 SEE ALSO

L<Verilog::Netlist::Module>
L<Verilog::Netlist>
L<SystemC::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
