# SystemC - SystemC Perl Interface
# $Id: File.pm,v 1.41 2001/06/27 13:10:53 wsnyder Exp $
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

package SystemC::Netlist::File;
use Class::Struct;
use Carp;

use SystemC::Netlist;
use SystemC::Template;
use SystemC::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::File::Struct
	SystemC::Netlist::Subclass);
$VERSION = '0.420';
use strict;

structs('new',
	'SystemC::Netlist::File::Struct'
	=>[name		=> '$', #'	# Filename this came from
	   basename	=> '$', #'	# Basename of the file
	   netlist	=> '$', #'	# Netlist is a member of
	   #
	   text		=> '$',	#'	# ARRAYREF: Lines of text
	   is_libcell	=> '$',	#'	# True if is a library cell
	   # For special procedures
	   _write_var	=> '%',		# For write() function info passing
	   _enums	=> '$', #'	# For autoenums
	   _modules	=> '%',		# For autosubcell_include
	   ]);
	
######################################################################
######################################################################
#### Read class

package SystemC::Netlist::File::Parser;
use SystemC::Parser;
use strict;
use vars qw (@ISA);
use vars qw (@Text);	# Local for speed while inside parser.
@ISA = qw (SystemC::Parser);

sub text {
    my $self = shift;
    my $line = shift;
    push @Text, [ 0, $self->filename, $self->lineno,
		  $line ];
    if ($self->{netref}) {
	# Snarf comment following signal declaration
	# Note comments must begin on the same line as the signal
	if ($line =~ /^[ \t]*\/\/[ \t]*([^\n]+)/
	    || $line =~ /^[ \t]*\/\*[ \t]*(.*)/) {
	    my $cmt = $1;
	    $cmt =~ s/\*\/.*$//;  # Strip */ ... comment endings
	    $cmt =~ s/\s+/ /g;
	    $self->{netref}->comment($cmt);
	}
	$self->{netref} = undef;
    }
}

sub module {
    my $self = shift;
    my $module = shift;
    my $fileref = $self->{fileref};
    my $netlist = $self->{netlist};
    $module = $fileref->basename if $module eq "__MODULE__";
    print "Module $module\n" if $SystemC::Netlist::Debug;
    $self->{modref} = $netlist->new_module
	(name=>$module,
	 is_libcell=>$fileref->is_libcell(),
	 filename=>$self->filename, lineno=>$self->lineno);
    $fileref->_modules($module, $self->{modref});
}

sub auto {
    my $self = shift;
    my $line = shift;

    return if (!$self->{strip_autos});

    my $modref = $self->{modref};
    my $cellref = $self->{cellref};
    if ($line =~ /^(\s*)\/\*AUTOSIGNAL\*\//) {
	if (!$modref) {
	    return $self->error ("AUTOSIGNAL outside of module definition", $line);
	}
	$modref->_autosignal(1);
	push @Text, [ 1, $self->filename, $self->lineno,
		      \&SystemC::Netlist::Module::_write_autosignal,
		      $modref, $self->{fileref}, $1];
    }
    elsif ($line =~ /^(\s*)\/\*AUTOSUBCELL(S|_DECL)\*\//) {
	if (!$modref) {
	    return $self->error ("AUTOSUBCELL_DECL outside of module definition", $line);
	}
	$modref->_autosubcells(1);
	push @Text, [ 1, $self->filename, $self->lineno,
		      \&SystemC::Netlist::Module::_write_autosubcell_decl,
		      $modref, $self->{fileref}, $1];
    }
    elsif ($line =~ /^(\s*)\/\*AUTOSUBCELL_CLASS\*\//) {
	push @Text, [ 1, $self->filename, $self->lineno,
		      \&SystemC::Netlist::File::_write_autosubcell_class,
		      $self->{fileref}, $self->{fileref}, $1];
    }
    elsif ($line =~ /^(\s*)\/\*AUTOSUBCELL_INCLUDE\*\//) {
	push @Text, [ 1, $self->filename, $self->lineno,
		      \&SystemC::Netlist::File::_write_autosubcell_include,
		      $self->{fileref}, $self->{fileref}, $1];
    }
    elsif ($line =~ /^(\s*)\/\*AUTOINST\*\//) {
	if (!$cellref) {
	    return $self->error ("AUTOINST outside of cell definition", $line);
	}
	$cellref->_autoinst(1);
	push @Text, [ 1, $self->filename, $self->lineno,
		      \&SystemC::Netlist::Cell::_write_autoinst,
		      $cellref, $self->{fileref}, $1];
    }
    elsif ($line =~ /^(\s*)\/\*AUTOENUM_CLASS\(([a-zA-Z0-9_]+)(\.|::)([a-zA-Z0-9_]+)\)\*\//) {
	my $prefix = $1; my $class = $2;  my $enumtype = $4;
	push @Text, [ 1, $self->filename, $self->lineno,
		      \&SystemC::Netlist::File::_write_autoenum_class,
		      $self->{fileref}, $class, $enumtype, $prefix,];
    }
    elsif ($line =~ /^(\s*)\/\*AUTOENUM_GLOBAL\(([a-zA-Z0-9_]+)(\.|::)([a-zA-Z0-9_]+)\)\*\//) {
	my $prefix = $1; my $class = $2;  my $enumtype = $4;
	push @Text, [ 1, $self->filename, $self->lineno,
		      \&SystemC::Netlist::File::_write_autoenum_global,
		      $self->{fileref}, $class, $enumtype, $prefix,];
    }
    elsif ($line =~ /^(\s*)\/\*AUTODECLS\*\//) {
	my $prefix = $1;
	push @Text, [ 1, $self->filename, $self->lineno,
		      \&SystemC::Netlist::Module::_write_autodecls,
		      $modref, $self->{fileref}, $prefix];
    }
    elsif ($line =~ /^(\s*)\/\*AUTOTRACE\(([a-zA-Z0-9_]+)\)\*\//) {
	my $prefix = $1; my $modname = $2;
	$modname = $self->{fileref}->basename if $modname eq "__MODULE__";
	my $mod = $self->{netlist}->find_module ($modname);
	$mod or $self->warn ("Declaration for module not found: $modname\n");
	$mod->_autotrace(1);
	push @Text, [ 1, $self->filename, $self->lineno,
		      \&SystemC::Netlist::Module::_write_autotrace,
		      $mod, $self->{fileref}, $prefix,];
    }
    else {
	return $self->error ("Unknown AUTO command", $line);
    }
}

sub ctor {}

sub cell_decl {
    my $self = shift;
    my $submodname=shift;
    my $instname=shift;

    print "Cell_decl $instname\n" if $SystemC::Netlist::Debug;
    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("SP_CELL_DECL outside of module definition", $instname);
    }
    (my $instnamebase = $instname) =~ s/\[.*//;	# Strip any arrays
    $modref->_celldecls($instnamebase,$submodname);
}

sub cell {
    my $self = shift;
    my $instname=shift;
    my $submodname=shift;

    print "Cell $instname\n" if $SystemC::Netlist::Debug;
    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("SP_CELL outside of module definition", $instname);
    }
    $self->{cellref} = $modref->new_cell
	(name=>$instname, 
	 filename=>$self->filename, lineno=>$self->lineno,
	 submodname=>$submodname);
}

sub pin {
    my $self = shift;
    my $cellname = shift;
    my $pin = shift;
    my $pinvec = shift;
    my $net = shift;
    my $netvec = shift;

    my $cellref = $self->{cellref};
    if (!$cellref) {
	return $self->error ("SP_PIN outside of cell definition", $net);
    }
    $cellref->new_pin (name=>$pin,
		       filename=>$self->filename, lineno=>$self->lineno,
		       netname=>$net, );
}

sub signal {
    my $self = shift;
    my $inout = shift;
    my $type = shift;
    my $net = shift;
    my $array = shift;

    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("Signal declaration outside of module definition", $net);
    }

    if ($inout eq "sc_signal"
	|| $inout eq "sc_clock"
	) {
	my $net = $modref->new_net
	    (name=>$net,
	     filename=>$self->filename, lineno=>$self->lineno,
	     direction=>$inout, type=>$type, array=>$array,
	     comment=>undef,
	     # we don't detect variable usage, so presume ok if declared
	     _used_input=>1, _used_output=>1,	
	     );
	$self->{netref} = $net;
    }
    elsif ($inout =~ /sc_(inout|in|out)$/) {
	my $dir = $1;
	my $net = $modref->new_port
	    (name=>$net,
	     filename=>$self->filename, lineno=>$self->lineno,
	     direction=>$dir, type=>$type,
	     array=>$array, comment=>undef,);
	$self->{netref} = $net;
    }
    else {
	return $self->error ("Strange signal type: $inout", $inout);
    }
}

sub preproc_sp {
    my $self = shift;
    my $line = shift;
    if ($line=~ /^\s*\#sp\s+(.*)$/) {
	my $cmd = $1; $cmd =~ s/\s+$//;
	if ($cmd =~ /^implementation$/) {
	    push @Text, [ 0, $self->filename, $self->lineno,
			  \&SystemC::Netlist::File::_write_implementation,
			  $self->{fileref}, $line];
	}
	elsif ($cmd =~ /^interface$/) {
	    push @Text, [ 0, $self->filename, $self->lineno,
			  \&SystemC::Netlist::File::_write_interface,
			  $self->{fileref}, $line];
	}
	else {
	    return $self->error ("Invalid sp_preproc directive",$line);
	}
    }
}

sub class {
    my $self = shift;
    my $class = shift;
    # Track class x { enum y ...}
    $self->{class} = $class;
}

sub enum_value {
    my $self = shift;
    my $enum = shift;
    my $def = shift;
    # We haven't defined a class for enums... Presume others won't use them(?)
    my $fileref = $self->{fileref};

    my $class = $self->{class} || "TOP";
    my $href = $fileref->_enums() || {};
    $href->{$class}{$enum}{$def} = 1;
    $fileref->_enums($href);
}

sub error {
    my $self = shift;
    my $text = shift;
    my $token = shift;

    my $fileref = $self->{fileref};
    # Call SystemC::Netlist::Subclass's error reporting, it will track # errors
    my $fileline = $self->filename.":".$self->lineno;
    $fileref->error ($self, "$text\n"
		     ."%Error: ".(" "x length($fileline))
		     .": At token '$token'\n");
}

package SystemC::Netlist::File;

######################################################################
######################################################################
#### Functions

sub read {
    my %params = (@_);	# filename=>

    my $filename = $params{filename} or croak "%Error: ".__PACKAGE__."::read_file (filename=>) parameter required, stopped";

    print __PACKAGE__."::read_file $filename\n" if $SystemC::Netlist::Debug;
    (-r $filename) or die "%Error: Cannot open $filename\n";

    my $netlist = $params{netlist} or croak ("Call SystemC::Netlist::read_file instead,");
    my $fileref = $netlist->new_file (name=>$filename,
				      is_libcell=>$params{is_libcell}||0,
				      );

    my $parser = SystemC::Netlist::File::Parser->new
	( modref=>undef,	# Module being parsed now
	  cellref=>undef,	# Cell being parsed now
	  fileref=>$fileref,
	  filename=>$filename,	# for ->read
	  netlist=>$netlist,
	  strip_autos=>$params{strip_autos}||0,	# for ->read
	  );
    # For speed, we don't use the accessor function
    local @SystemC::Netlist::File::Parser::Text = ();
    $netlist->dependancy_in ($filename);
    $parser->read (filename=>$filename,);
    $fileref->text(\@SystemC::Netlist::File::Parser::Text);
    return $fileref;
}

sub print {
    my $self = shift;
    my $indent = shift||0;
    print " "x$indent,"File:",$self->name(),"  Lines:",$#{@{$self->text}},"\n";
}

######################################################################
######################################################################
# WRITING

# _write locals
use vars qw($as_imp $as_int $outputting);

sub _write_print {
    shift if ref $_[0];
    SystemC::Template::print (@_);
}
sub _write_printf {
    shift if ref $_[0];
    SystemC::Template::printf (@_);
}

sub write {
    my $self = shift;  ref $self or croak "%Error: Call as \$ref->".__PACKAGE__."::write, stopped";
    my %params = (@_);

    $SystemC::Netlist::Verbose = 1 if $SystemC::Netlist::Debug;

    my $filename = $params{filename} or croak "%Error: ".__PACKAGE__."::write (filename=>) parameter required, stopped";
    local $as_imp = $params{as_implementation};
    local $as_int = $params{as_interface};
    my $autos  = $params{expand_autos};
    my $program = $params{program} || __PACKAGE__;	# Allow user to override it
    foreach my $var (keys %params) {
	# Copy variables so subprocesses can see them
	$self->_write_var($var, $params{$var});
    }


    my $tpl = new SystemC::Template (ppline=>($as_imp||$as_int),
				     keep_timestamp=>$params{keep_timestamp},
				     );
    foreach my $lref (@{$tpl->src_text()}) {
	#print "GOT LINE $lref->[1], $lref->[2], $lref->[3]";
	$tpl->print_ln ($lref->[1], $lref->[2], $lref->[3]);
    }

    local $outputting = 1;

    if ($as_imp || $as_int) {
	if ($as_int) {
	    $tpl->printf("#ifndef _%s_H_\n#define _%s_H_ 1\n", uc $self->basename, uc $self->basename);
	}
	$tpl->print("// This file generated automatically by $program\n");
	$tpl->printf("#include \"%s.h\"\n", $self->basename) if $as_imp;
	$tpl->print("#include \"systemperl.h\"\n") if $as_int;
    }

    my $basename = $self->basename;
    foreach my $line (@{$self->text}) {
	# [autos, filename, lineno, text]
	# [autos, filename, lineno, function, args, ...]
	my $needautos = $line->[0];
	my $src_filename   = $line->[1];
	my $src_lineno = $line->[2];
	if ($autos || !$needautos) {
	    my $func = $line->[3];
	    if (ref $func) {
		# it contains a function and arguments to that func
		#print "$func ($line->[1], $fh, $line->[2], );\n";
		&{$func} ($line->[4],$line->[5],$line->[6],$line->[7],$line->[8],);
	    } else {
		my $text = $line->[3];
		if (defined $text && $outputting) {
		    # This will also substitute in strings.  This was deemed a feature.
		    $text =~ s/\b__MODULE__\b/$basename/g;
		    $tpl->print_ln ($src_filename, $src_lineno, $text);
		}
	    }
	}
    }

    if ($as_imp || $as_int) {
	$tpl->print ("// This file generated automatically by $program\n");
	$tpl->printf ("#endif /*_%s_H_*/\n", uc $self->basename) if $as_int;
    }

    # Write the file
    $self->netlist->dependancy_out ($filename);
    $tpl->write( filename=>$filename, );
}

sub _write_implementation {
    my $self = shift;
    my $line = shift;
    if ($as_imp || $as_int) {
	_write_print ("//$line");
	$outputting = 0 if ($as_int);
	$outputting = 1 if ($as_imp);
    } else {
	_write_print ($line);
    }
}
sub _write_interface {
    my $self = shift;
    my $line = shift;
    if ($as_imp || $as_int) {
	_write_print ("//$line");
	$outputting = 1 if ($as_int);
	$outputting = 0 if ($as_imp);
    } else {
        _write_print ($line);
    }
}

sub _write_autoenum_class {
    my $self = shift;
    my $class = shift;
    my $enumtype = shift;
    my $prefix = shift;

    return if !$SystemC::Netlist::File::outputting;
    _write_print
	("${prefix}// Beginning of SystemPerl automatic enumeration\n"
	 ."${prefix}enum ${enumtype} e_${enumtype};\n"
	 ."${prefix}inline ${class} () {};\n"
	 .("${prefix}inline ${class} (${enumtype} _e)"
	   ." : e_${enumtype}(_e) {};\n")
	 .("${prefix}explicit inline ${class} (int _e)"
	   ." : e_${enumtype}(static_cast<${enumtype}>(_e)) {};\n")
	 ."${prefix}operator const char * (void) const { return ascii(); };\n"
	 ."${prefix}operator ${enumtype} (void) const { return e_${enumtype}; };\n"
	 ."${prefix}const char *ascii (void) const {\n"
	 ."${prefix}   switch (e_${enumtype}) {\n"
	 );

    my $href = $self->_enums() || {{}};
    my $vals = $href->{$class};
    $vals = $href->{TOP} if !defined $vals;
    foreach my $valsym (sort (keys %{$vals->{$enumtype}})) {
	my $name = $valsym;
	_write_print ("${prefix}   case ${valsym}: return \"${name}\";\n");
    }

    _write_print ("${prefix}   default: return \"%E:BadVal:${class}\";\n"
		  ."${prefix}   };\n"
		  ."${prefix}};\n"
		  );

    #Can do this, but then also need setting functions...
    #foreach my $valsym (sort (keys %{$href->{$enumtype}})) {
    #	 _write_print ("${prefix}bool is${valsym}() const {return e_${enumtype}==${valsym};};\n");
    #}
    _write_print ("${prefix}// End of SystemPerl automatic enumeration\n");
}

sub _write_autoenum_global {
    my $self = shift;
    my $class = shift;
    my $enumtype = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    _write_print
	("${prefix}// Beginning of SystemPerl automatic enumeration\n"
	 ."${prefix}inline bool operator== (${class} lhs, ${class} rhs)"
	 ." { return (lhs.e_${enumtype} == rhs.e_${enumtype}); }\n"
	 ."${prefix}inline bool operator== (${class} lhs, ${class}::${enumtype} rhs)"
	 ." { return (lhs.e_${enumtype} == rhs); }\n"
	 ."${prefix}inline bool operator== (${class}::${enumtype} lhs, ${class} rhs)"
	 ." { return (lhs == rhs.e_${enumtype}); }\n"
	 ."${prefix}inline std::ostream& operator<< (std::ostream& lhs, const ${class}& rhs)"
	 ." { return lhs << rhs.ascii(); }\n"
	 ."${prefix}// End of SystemPerl automatic enumeration\n"
	 );
}

sub _cells_in_file {
    my $fileref = shift;
    my %cells;
    foreach my $modref (values %{$fileref->_modules}) {
	foreach my $cellref ($modref->cells_sorted) {
	    $cells{$cellref->submodname} = $cellref;
	}
    }
    return (sort {$a->submodname cmp $b->submodname} (values %cells));
}

sub _write_autosubcell_class {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->_write_print ("${prefix}// Beginning of SystemPerl automatic subcell classes\n");
    foreach my $cellref ($fileref->_cells_in_file) {
	$fileref->_write_printf ("%sclass %-21s  // For %s.%s\n"
				 ,$prefix,$cellref->submodname.";"
				 ,$cellref->module->name, $cellref->name);
    }
    $fileref->_write_print ("${prefix}// End of SystemPerl automatic subcell classes\n");
}

sub _write_autosubcell_include {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    $fileref->_write_print ("${prefix}// Beginning of SystemPerl automatic subcell includes\n");
    foreach my $cellref ($fileref->_cells_in_file) {
	$fileref->_write_printf ("#include \"%-22s  // For %s.%s\n"
				 ,$cellref->submodname.".h\""
				 ,$cellref->module->name, $cellref->name);
    }
    $fileref->_write_print ("${prefix}// End of SystemPerl automatic subcell includes\n");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::File - File containing SystemC code

=head1 SYNOPSIS

  use SystemC::Netlist;

  my $nl = new SystemC::Netlist;
  my $fileref = $nl->read_file (filename=>'filename');
  $fileref->write (filename=>'new_filename',
		   expand_autos=>1,);

=head1 DESCRIPTION

SystemC::Netlist::File allows SystemC files to be read and written.

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

=item $self->print

Prints debugging information for this file.

=back

=head1 SEE ALSO

L<SystemC::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
