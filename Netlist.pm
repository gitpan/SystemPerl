# SystemC - SystemC Perl Interface
# $Id: Netlist.pm,v 1.11 2001/04/03 19:57:18 wsnyder Exp $
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

package SystemC::Netlist;
use Carp;

use SystemC::Netlist::Module;
use SystemC::Netlist::File;
use SystemC::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::Subclass);
use strict;
use vars qw($Debug $Verbose $VERSION);

$VERSION = '0.2';

######################################################################
#### Error Handling

# Netlist file & line numbers don't apply
sub filename { return 'SystemC::Netlist'; }
sub lineno { return ''; }

######################################################################
#### Creation

sub new {
    my $class = shift;
    my $self = {_modules => {},
		_files => {},
		@_};
    bless $self, $class;
    return $self;
}

######################################################################
#### Functions

sub link {
    my $self = shift;
    foreach my $modref ($self->modules) {
	$modref->link();
    }
}
sub lint {
    my $self = shift;
    foreach my $modref ($self->modules_sorted) {
	$modref->lint();
    }
}
sub autos {
    my $self = shift;
    foreach my $modref ($self->modules) {
	$modref->autos();
    }
}
sub print {
    my $self = shift;
    foreach my $modref ($self->modules_sorted) {
	$modref->print();
    }
}

######################################################################
#### Module access

sub new_module {
    my $self = shift;
    # @_ params
    # Can't have 'new SystemC::Netlist::Module' do this,
    # as not allowed to override Class::Struct's new()
    my $modref = new SystemC::Netlist::Module
	(netlist=>$self,
	 @_);
    $self->{_modules}{$modref->name} = $modref;
    return $modref;
}

sub find_module {
    my $self = shift;
    my $search = shift;
    # Return module maching name
    return $self->{_modules}{$search};
}
    
sub modules {
    my $self = shift;
    # Return all modules
    return (values %{$self->{_modules}});
}

sub modules_sorted {
    my $self = shift;
    # Return all modules
    return (sort {$a->name() cmp $b->name()} (values %{$self->{_modules}}));
}

######################################################################
#### Files access

sub new_file {
    my $self = shift;
    # @_ params
    # Can't have 'new SystemC::Netlist::File' do this,
    # as not allowed to override Class::Struct's new()
    my $fileref = new SystemC::Netlist::File
	(netlist=>$self,
	 @_);
    defined $fileref->name or carp "%Error: No name=> specified, stopped";
    $self->{_files}{$fileref->name} = $fileref;
    $fileref->basename (SystemC::Netlist::Module::modulename_from_filename($fileref->name));
    return $fileref;
}

sub find_file {
    my $self = shift;
    my $search = shift;
    # Return file maching name
    return $self->{_files}{$search};
}
    
sub files {
    my $self = shift; ref $self or die;
    # Return all files
    return (sort {$a->name() cmp $b->name()} (values %{$self->{_files}}));
}

sub read_file {
    my $self = shift;
    my $fileref = SystemC::Netlist::File::read
	(netlist=>$self,
	 @_);
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist - SystemC Netlist

=head1 SYNOPSIS

  use SystemC::Netlist;

    my $nl = new SystemC::Netlist ();
    foreach my $file ('testnetlist.sp') {
	$nl->read_file (filename=>$file,
			strip_autos=>1);
    }
    $nl->link();
    $nl->autos();
    $nl->lint();
    $nl->exit_if_error();

    foreach my $mod ($nl->modules_sorted) {
	show_hier ($mod, "  ");
    }

    sub show_hier {
	my $mod = shift;
	my $indent = shift;
	print $indent,"Module ",$mod->name,"\n";
	foreach my $cell ($mod->cells_sorted) {
	    show_hier ($cell->submod, $indent."  ".$cell->name."  ");
	}
    }

=head1 DESCRIPTION

SystemC::Netlist contains interconnect information about a whole design
database.

The database is composed of files, which contain the text read from each
file.

A file may contain modules, which are individual blocks that can be
instantiated (designs, in Synopsys terminology.)

Modules have ports, which are the interconnection between nets in that
module and the outside world.  Modules also have nets, (aka signals), which
interconnect the logic inside that module.

Modules can also instantiate other modules.  The instantiation of a module
is a Cell.  Cells have pins that interconnect the referenced module's pin
to a net in the module doing the instantiation.

Each of these types, files, modules, ports, nets, cells and pins have a
class.  For example SystemC::Netlist::Cell has the list of
SystemC::Netlist::Pin (s) that interconnect that cell.

=head1 FUNCTIONS

=over 4

=item $netlist->autos

Updates /*AUTO*/ comments in the internal database.  Normally called before
lint.

=item $netlist->error

Prints an error in a standard way, and increments $Errors.

=item $netlist->lint

Error checks the entire netlist structure.

=item $netlist->link

Resolves references between the different modules.

=item $netlist->print

Prints debugging information for the entire netlist structure.

=item $netlist->warn

Prints a warning in a standard way, and increments $Warnings.

=back

=head1 MODULE FUNCTIONS

=over 4

=item $netlist->find_module($name)

Returns SystemC::Netlist::Module matching given name.

=item $netlist->modules_sorted

Returns list of all SystemC::Netlist::Module.

=item $netlist->new_module

Creates a new SystemC::Netlist::Module.

=back

=head1 FILE FUNCTIONS

=over 4

=item $netlist->find_file($name)

Returns SystemC::Netlist::File matching given name.

=item $netlist->read_file( filename=>$name)

Reads the given SystemC file, and returns a SystemC::Netlist::File
reference.

=item $netlist->files

Returns list of all files.

Generally called as $netlist->read_file.  Pass a hash of parameters.  Reads
the filename=> parameter, parsing all instantiations, ports, and signals,
and creating SystemC::Netlist::Module structures.  The optional
preserve_autos=> parameter prevents default ripping of /*AUTOS*/ out for
later recomputation.

=back

=head1 SEE ALSO

L<SystemC::Cell>,
L<SystemC::File>,
L<SystemC::Module>,
L<SystemC::Net>,
L<SystemC::Pin>,
L<SystemC::Port>,
L<SystemC::Subclass>

=head1 DISTRIBUTION

The latest version is available from CPAN and from C<http://veripool.com/>.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
