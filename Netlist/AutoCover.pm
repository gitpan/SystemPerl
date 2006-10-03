# SystemC - SystemC Perl Interface
# $Id: AutoCover.pm 25920 2006-10-03 15:48:21Z wsnyder $
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

package SystemC::Netlist::AutoCover;
use Class::Struct;

use Verilog::Netlist;
use Verilog::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::AutoCover::Struct
	Verilog::Netlist::Subclass);
$VERSION = '1.272';
use strict;

structs('new',
	'SystemC::Netlist::AutoCover::Struct'
	=>[name     	=> '$', #'	# Instantiation number
	   what		=> '$', #'	# Type of coverage (line/expr)
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   comment	=> '$', #'	# Info on the coverage item
	   enable	=> '$', #'	# Enabling expression
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
    my $out = $prefix;
    $out .= 'if ('.$coverref->enable.') { ' if ($coverref->enable ne "1");
    $out .= sprintf("SP_AUTO_COVERinc(%d,\"%s\",\"%s\",%d,\"%s\");"
		    ,$coverref->name, $coverref->what
		    ,$coverref->filename, $coverref->lineno,
		    ,$coverref->comment);
    if ($coverref->enable ne "1") {
	$out .= '} else { ';
	$out .= sprintf("SP_ERROR_LN(\"%s\",%d,\"Impossible SP_AUTO_COVER_IF case did occur: %s\");"
			,$coverref->filename, $coverref->lineno,
			,$coverref->comment);
	$out .= '}';
    }
    return $out;
}

sub _write_autocover_decl {
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    return if !$SystemC::Netlist::File::outputting;
    my $maxId = $modref->autocover_max_id;
    return if !$maxId;
    $fileref->printf ("%sSpZeroed<uint32_t>\t_sp_coverage[%d];\t// SP_AUTO_COVER declaration\n"
		      ,$prefix, $maxId);
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
    #$fileref->printf ("%sSpFunctorNamed::add(\"coverageWrite\",&%s::coverageWrite,this);\t// SP_AUTO_COVER declaration\n"
    #		      ,$prefix,$modref->name);

    my $mod = $modref->name;
    $fileref->print("    // Auto Coverage\n");
    foreach my $coverref (sort {$a->name cmp $b->name
			    || $a->lineno <=> $b->lineno}
		      (values %{$modref->_autocovers})) {
	$fileref->printf('    ');
	$fileref->printf('if ('.$coverref->enable.') { ') if ($coverref->enable ne "1");
	$fileref->printf('SP_COVER_INSERT(&_sp_coverage[%d]', $coverref->name);
	$fileref->printf(',"filename","%s"', $coverref->filename);
	$fileref->printf(',"lineno","%s"', $coverref->lineno);
	$fileref->printf(',"hier",name()');
	$fileref->printf(',"comment","%s"', $coverref->comment);
	$fileref->printf(");");
	$fileref->printf(' }') if ($coverref->enable ne "1");
	$fileref->printf("\n");
    }
    $fileref->print("\n");
}

sub _write_autocover_impl {
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    # NOP
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

=head1 DISTRIBUTION

SystemPerl is part of the L<http://www.veripool.com/> free SystemC software
tool suite.  The latest version is available from CPAN and from
L<http://www.veripool.com/systemperl.html>.

Copyright 2001-2006 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=head1 SEE ALSO

L<SystemC::Netlist::Module>

=cut
