# SystemC - SystemC Perl Interface
# $Revision: #45 $$Date: 2003/10/28 $$Author: wsnyder $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# Copyright 2001-2003 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
######################################################################

package SystemC::Netlist;
use Carp;
use IO::File;

use Verilog::Netlist;
use SystemC::Netlist::Module;
use SystemC::Netlist::File;
use Verilog::Netlist::Subclass;
@ISA = qw(Verilog::Netlist);
use strict;
use vars qw($Debug $Verbose $VERSION);

$VERSION = '1.146';

######################################################################
#### Error Handling

# Netlist file & line numbers don't apply
sub filename { return 'SystemC::Netlist'; }
sub lineno { return ''; }

######################################################################
#### Creation

sub new {
    my $class = shift;
    my $self = $class->SUPER::new
	(sp_allow_output_tracing => undef,	# undef = set it automatically
	 sp_allow_bv_tracing => undef,		# undef = set it automatically
	 sp_trace_duplicates => 0,
	 sc_version => undef,
	 _enum_classes => {},
	 @_);
    bless $self, $class;
    $self->_set_features();
    return $self;
}

######################################################################
#### Utilities

sub sc_version {
    my $self = shift;
    # Return version of SystemC in use
    if (!$self->{sc_version} && $ENV{SYSTEMC}) {
	my $fh;
	foreach my $fn ("$ENV{SYSTEMC}/include/systemc/kernel/sc_ver.h",
			"$ENV{SYSTEMC}/include/sc_ver.h") {
	    $fh = IO::File->new($fn);
	    last if $fh;
	}
	if ($fh) {
	    while (defined (my $line = $fh->getline)) {
		if ($line =~ /^\s*#\s*define\s+SYSTEMC_VERSION\s+(\S+)/) {
		    $self->{sc_version} = $1;
		    print "SC_VERSION = $1\n" if $Debug;
		    last;
		}
	    }
	}
    }
    return $self->{sc_version};
}

sub _set_features {
    my $self = shift;
    # Determine what features are in this SystemC version
    my $ver = $self->sc_version;
    my $patched = ($ENV{SYSTEMC} && -r "$ENV{SYSTEMC}/systemperl_patched");
    if (!defined $self->{sp_allow_bv_tracing}) {
	$self->{sp_allow_bv_tracing} = $patched;
    }
    if (!defined $self->{sp_allow_output_tracing}) {
	if ($ver && $ver>20011000) {
	    $self->{sp_allow_output_tracing} = 1;
	} elsif ($patched) {
	    $self->{sp_allow_output_tracing} = 'hack';
	} else {
	    $self->{sp_allow_output_tracing} = 0;
	}
    }
}

######################################################################
#### Functions

sub autos {
    my $self = shift;
    foreach my $modref ($self->modules) {
	next if $modref->is_libcell();
	$modref->autos1();
    }
    $self->link();  # Pick up pins autos1 created
    foreach my $modref ($self->modules) {
	next if $modref->is_libcell();
	$modref->autos2();
    }
    $self->link();
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
	 is_top=>1,
	 @_);
    $self->{_modules}{$modref->name} = $modref;
    return $modref;
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
    $fileref->basename (Verilog::Netlist::Module::modulename_from_filename($fileref->name));
    return $fileref;
}

sub read_file {
    my $self = shift;
    my $fileref = SystemC::Netlist::File::read
	(netlist=>$self,
	 @_);
}

######################################################################
#### Library files

sub write_cell_library {
    my $self = shift;
    my %params = (filename=>undef,
		  @_);
    $self->dependency_out($params{filename});
    my $fh = IO::File->new($params{filename},"w") or die "%Error: $! $params{filename}\n";
    foreach my $modref ($self->modules_sorted) {
	print $fh "MODULE ",$modref->name,"\n";
	foreach my $cellref ($modref->cells_sorted) {
	    print $fh "  CELL ",$cellref->name," ",$cellref->submodname,"\n";
	}
    }
    $fh->close;
}

sub read_cell_library {
    my $self = shift;
    my %params = (filename=>undef,
		  @_);
    $self->dependency_in($params{filename});
    my $fh = IO::File->new($params{filename}) or die "%Error: $! $params{filename}\n";
    my $modref;
    while (defined (my $line = $fh->getline)) {
	chomp $line;
	$line =~ s/#.*$//;
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;
	if ($line =~ /^MODULE\s+(\S+)$/) {
	    $modref = $self->find_module($1);
	    if (!$modref) {
		$modref = $self->new_module(name=>$1, is_libcell=>1,);
	    }
	}
	elsif ($line =~ /^CELL\s+(\S+)\s+(\S+)$/) {
	    my $cellref = $modref->find_cell($1);
	    if (!$cellref) {
		$cellref = $modref->new_cell(name=>$1, submodname=>$2,);
	    }
	}
	else {
	    die "%Error: $params{filename}:$.: Unknown line: $line\n";
	}
    }
    $fh->close;
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

  # See Verilog::Netlist for base functions

    $nl->autos();
    $nl->exit_if_error();


=head1 DESCRIPTION

SystemC::Netlist contains interconnect information about a whole design
database.  The classes of SystemC::Netlist parallel those of
Verilog::Netlist, which should be seen for all documentaion.

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

See Verilog::Netlist for all common functions.

=over 4

=item $netlist->autos

Updates /*AUTO*/ comments in the internal database.  Normally called before
lint.

=item $netlist->sc_version

Return the version number of SystemC.

=back

=head1 SEE ALSO

L<SystemC::Netlist::Cell>,
L<SystemC::Netlist::File>,
L<SystemC::Netlist::Module>,
L<SystemC::Netlist::Net>,
L<SystemC::Netlist::Pin>,
L<SystemC::Netlist::Port>,
L<Verilog::Netlist::Subclass>

=head1 DISTRIBUTION

The latest version is available from CPAN and from C<http://veripool.com/>.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
