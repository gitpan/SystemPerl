# SystemC - SystemC Perl Interface
# $Id: Module.pm,v 1.8 2001/04/03 21:26:01 wsnyder Exp $
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

package SystemC::Netlist::Module;
use Class::Struct;

use SystemC::Netlist;
use SystemC::Netlist::Port;
use SystemC::Netlist::Net;
use SystemC::Netlist::Cell;
use SystemC::Netlist::Pin;
use SystemC::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::Module::Struct
	SystemC::Netlist::Subclass);
use strict;

structs('SystemC::Netlist::Module::Struct'
	=>[name     	=> '$', #'	# Name of the module
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   netlist	=> '$', #'	# Netlist is a member of
	   #
	   ports	=> '%',		# hash of SystemC::Netlist::Ports
	   nets		=> '%',		# hash of SystemC::Netlist::Nets
	   cells	=> '%',		# hash of SystemC::Netlist::Cells
	   _autosignal	=> '$', #'	# Module has /*AUTOSIGNAL*/ in it
	   _autosubcells=> '$', #'	# Module has /*AUTOSUBCELLS*/ in it
	   ]);

sub modulename_from_filename {
    my $filename = shift;
    (my $module = $filename) =~ s/.*\///;
    $module =~ s/\.[a-z]+$//;
    return $module;
}

sub find_port {
    my $self = shift;
    my $search = shift;
    return $self->ports->{$search};
}
sub find_cell {
    my $self = shift;
    my $search = shift;
    return $self->cells->{$search};
}
sub find_net {
    my $self = shift;
    my $search = shift;
    my $rtn = $self->nets->{$search}||"";
    #print "FINDNET ",$self->name, " SS $search  $rtn\n";
    return $self->nets->{$search};
}

sub nets_sorted {
    my $self = shift;
    return (sort {$a->name() cmp $b->name()} (values %{$self->nets}));
}
sub ports_sorted {
    my $self = shift;
    return (sort {$a->name() cmp $b->name()} (values %{$self->ports}));
}
sub cells_sorted {
    my $self = shift;
    return (sort {$a->name() cmp $b->name()} (values %{$self->cells}));
}

sub new_net {
    my $self = shift;
    # @_ params
    # Create a new net under this module
    my $netref = new SystemC::Netlist::Net (module=>$self, @_);
    $self->nets ($netref->name(), $netref);
    return $netref;
}

sub new_port {
    my $self = shift;
    # @_ params
    # Create a new port under this module
    my $portref = new SystemC::Netlist::Port (module=>$self, @_);
    $self->ports ($portref->name(), $portref);
    return $portref;
}

sub new_cell {
    my $self = shift;
    # @_ params
    # Create a new cell under this module
    my $cellref = new SystemC::Netlist::Cell (module=>$self, @_);
    $self->cells ($cellref->name(), $cellref);
    return $cellref;
}

sub link {
    my $self = shift;
    foreach my $portref (values %{$self->ports}) {
	$portref->_link();
    }
    foreach my $netref (values %{$self->nets}) {
	$netref->_link();
    }
    foreach my $cellref (values %{$self->cells}) {
	$cellref->_link();
    }
}

sub lint {
    my $self = shift;
    foreach my $portref (values %{$self->ports}) {
	$portref->lint();
    }
    foreach my $netref (values %{$self->nets}) {
	$netref->lint();
    }
    foreach my $cellref (values %{$self->cells}) {
	$cellref->lint();
    }
}

sub print {
    my $self = shift;
    my $indent = shift||0;
    my $norecurse = shift;
    print " "x$indent,"Module:",$self->name(),"  File:",$self->filename(),"\n";
    if (!$norecurse) {
	foreach my $portref (values %{$self->ports}) {
	    $portref->print($indent+2);
	}
	foreach my $netref (values %{$self->nets}) {
	    $netref->print($indent+2);
	}
	foreach my $cellref (values %{$self->cells}) {
	    $cellref->print($indent+2);
	}
    }
}

######################################################################
#### Automatics (Preprocessing)

sub autos {
    my $self = shift;
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
    $fileref->_write_print ("${prefix}// Beginning of SystemPerl automatic signals\n");
    foreach my $netref ($self->nets_sorted) {
	 if ($netref->autocreated) {
	     my $vec = $netref->array || "";
	     $fileref->_write_printf ("%ssc_signal%-20s %-20s //%s\n"
		 ,$prefix,"<".$netref->type.">",$netref->name.$vec.";", $netref->comment);
	 }
    }
    $fileref->_write_print ("${prefix}// End of SystemPerl automatic signals\n");
}

sub _write_autosubcells {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->_write_print ("${prefix}// Beginning of SystemPerl automatic subcells\n");
    foreach my $cellref ($self->cells_sorted) {
        $fileref->_write_printf ("%s%-20s *%s\n"
	    ,$prefix,$cellref->submodname,$cellref->name.";");
    }
    $fileref->_write_print ("${prefix}// End of SystemPerl automatic subcells\n");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Module - Module within a SystemC Netlist

=head1 SYNOPSIS

  use SystemC::Netlist;

  ...
  my $module = $netlist->find_module('modname');
  my $cell = $self->find_cell('name')
  my $port =  $self->find_port('name')
  my $net =  $self->find_net('name')

=head1 DESCRIPTION

SystemC::Netlist creates a module for every file in the design.

=head1 ACCESSORS

=over 4

=item $self->cells

Returns list of references to SystemC::Netlist::Cell in the module.

=item $self->filename

The filename the module was created in.

=item $self->lineno

The line number the module was created on.

=item $self->name

The name of the module.

=item $self->ports

Returns list of references to SystemC::Netlist::Port in the module.

=item $self->nets

Returns list of references to SystemC::Netlist::Net in the module.

=back

=head1 MEMBER FUNCTIONS

=over 4

=item $self->autos

Updates the AUTOs for the module.

=item $self->find_cell($name)

Returns SystemC::Netlist::Cell matching given name.

=item $self->find_port($name)

Returns SystemC::Netlist::Port matching given name.

=item $self->find_net($name)

Returns SystemC::Netlist::Net matching given name.

=item $self->lint

Checks the module for errors.

=item $self->link

Creates interconnections between this module and other modules.

=item $self->new_cell

Creates a new SystemC::Netlist::Cell.

=item $self->new_port

Creates a new SystemC::Netlist::Port.

=item $self->new_net

Creates a new SystemC::Netlist::Net.

=item $self->print

Prints debugging information for this module.

=back

=head1 SEE ALSO

L<SystemC::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
