# SystemC - SystemC Perl Interface
# $Revision: #20 $$Date: 2004/01/27 $$Author: wsnyder $
# Author: Wilson Snyder <wsnyder@wsnyder.org>
######################################################################
#
# Copyright 2001-2004 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
######################################################################

package SystemC::Netlist::AutoCover;
use Class::Struct;

use Verilog::Netlist;
use Verilog::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::AutoCover::Struct
	Verilog::Netlist::Subclass);
$VERSION = '1.148';
use strict;

structs('new',
	'SystemC::Netlist::AutoCover::Struct'
	=>[name     	=> '$', #'	# Instantiation number
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   comment	=> '$', #'	# Info on the coverage item
	   #
	   module	=> '$', #'	# Module containing statement
	   ]);

######################################################################
#### Accessors

######################################################################
#### Module additions

package SystemC::Netlist::Module;

sub autocover_max_id {
    my $modref = shift;
    my $id = keys %{$modref->_autocovers};  # Scalar
    return ($id||0);
}

sub new_cover {
    my $self = shift;
    # @_ params
    # Create a new coverage entry under this module
    my $coverref = new SystemC::Netlist::AutoCover
	(name=>$self->autocover_max_id, @_, module=>$self, );
    $self->_autocovers ($coverref->name(), $coverref);
    return $coverref;
}

package SystemC::Netlist::AutoCover;

######################################################################
#### Automatics (Preprocessing)

sub call_text {
    my $coverref = shift;
    my $prefix = shift;
    # We simply replace the existing SP_AUTO instead of adding the comments.
    return sprintf ("%sSP_AUTO_COVER4(%d,\"%s\",\"%s\",%d);"
		    ,$prefix
		    ,$coverref->name, $coverref->comment
		    ,$coverref->filename, $coverref->lineno);
}

sub _write_autocover_decl {
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    return if !$SystemC::Netlist::File::outputting;
    my $maxId = $modref->autocover_max_id;
    return if !$maxId;
    $fileref->printf ("%sUInt32Zeroed\t_sp_coverage[%d];\t// SP_AUTO_COVER declaration\n"
		      ,$prefix, $maxId);
    $fileref->print ("${prefix}void\t\tcoverageWrite(void*);\n");
}

sub _write_autocover_incl {
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    return if !$SystemC::Netlist::File::outputting;
    return if !$modref->autocover_max_id;
    $fileref->printf ("#include \"SpCoverage.h\"\t// SP_AUTO_COVER declaration\n");
}

sub _write_autocover_ctor {
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    return if !$SystemC::Netlist::File::outputting;
    return if !$modref->autocover_max_id;
    $fileref->printf ("%sSpFunctorNamed::add(\"coverageWrite\",&%s::coverageWrite,this);\t// SP_AUTO_COVER declaration\n"
		      ,$prefix,$modref->name);
}

sub _write_autocover_impl {
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    return if !$SystemC::Netlist::File::outputting;
    my $maxId = $modref->autocover_max_id;
    return if !$maxId;

    my $mod = $modref->name;
    $fileref->print("void ${mod}::coverageWrite(void*) {\n");
    foreach my $cref (sort {$a->name cmp $b->name
			    || $a->lineno <=> $b->lineno}
		      (values %{$modref->_autocovers})) {
	$fileref->printf("    sp_coverage_data (name(),\"%s\",\"%s\",%d,_sp_coverage[%d]);\n"
			 ,$cref->comment, $cref->filename, $cref->lineno
			 ,$cref->name);
    }
    $fileref->print("}\n\n");
}


######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::AutoCover - Coverage analysis routines

=head1 DESCRIPTION

SystemC::Netlist::AutoCover creates the SP_AUTO_COVERAGE features.
It is called from SystemC::Netlist::Module.

=head1 SEE ALSO

L<SystemC::Netlist::Module>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
