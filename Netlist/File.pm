# SystemC - SystemC Perl Interface
# $Id: File.pm,v 1.20 2001/04/03 21:26:01 wsnyder Exp $
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
use SystemC::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::File::Struct
	SystemC::Netlist::Subclass);
use strict;

structs('SystemC::Netlist::File::Struct'
	=>[name		=> '$', #'	# Filename this came from
	   basename	=> '$', #'	# Basename of the file
	   netlist	=> '$', #'	# Netlist is a member of
	   #
	   text		=> '$',	#'	# ARRAYREF: Lines of text
	   # For special procedures
	   _write_var	=> '%',		# For write() function info passing
	   _enums	=> '$', #'	# For autoenums
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
	 filename=>$self->filename, lineno=>$self->lineno);
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
    elsif ($line =~ /^(\s*)\/\*AUTOSUBCELLS\*\//) {
	if (!$modref) {
	    return $self->error ("AUTOSUBCELLS outside of module definition", $line);
	}
	$modref->_autosubcells(1);
	push @Text, [ 1, $self->filename, $self->lineno,
		      \&SystemC::Netlist::Module::_write_autosubcells,
		      $modref, $self->{fileref}, $1];
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
    elsif ($line =~ /^(\s*)\/\*AUTOASCII_ENUM\(([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)\)\*\//) {
	my $prefix = $1; my $class = $2;  my $element = $3;
	push @Text, [ 1, $self->filename, $self->lineno,
		      \&SystemC::Netlist::File::_write_autoascii_enum,
		      $self->{fileref}, $class, $element, $prefix,];
    }
    else {
	return $self->error ("Unknown AUTO command", $line);
    }
}

sub ctor {}

sub cell {
    my $self = shift;
    my $instname=shift;
    my $submodname=shift;

    print "Cell $instname\n" if $SystemC::Netlist::Debug;
    my $modref = $self->{modref};
    if (!$modref) {
	return $self->error ("Cell declaration outside of module definition", $instname);
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
	return $self->error ("Pin declaration outside of cell definition", $net);
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
	$modref->new_net (name=>$net,
			  filename=>$self->filename, lineno=>$self->lineno,
			  direction=>$inout, type=>$type, array=>$array,
			  comment=>undef,);
    }
    elsif ($inout =~ /sc_(in|out|inout)/) {
	my $dir = $1;
	$modref->new_port (name=>$net,
			   filename=>$self->filename, lineno=>$self->lineno,
			   direction=>$dir, type=>$type,
			   array=>$array, comment=>undef,);
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

sub enum_value {
    my $self = shift;
    my $class = shift;
    my $def = shift;
    # We haven't defined a class for enums... Presume others won't use them(?)
    my $fileref = $self->{fileref};

    my $href = $fileref->_enums() || {};
    $href->{$class}{$def} = 1;
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
    my $fileref = $netlist->new_file (name=>$filename,);

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
use vars qw($as_imp $as_int $outputting @write_newtext $outlineno $gcclineno $gccfilename);

sub _write_print {
    shift if ref $_[0];	# Allow calling as $self->... or not
    my $outtext = join('',@_);
    push @write_newtext, $outtext;
    while ($outtext =~ /\n/g) {
	$outlineno++;
	$gcclineno++;
    }
}
sub _write_printf {
    shift if ref $_[0];	# Allow calling as $self->... or not
    my $fmt = shift;
    my $str = sprintf ($fmt,@_);
    _write_print ($str);
}
sub _write_lineno {
    my $lineno = shift;
    my $filename = shift;
    if ($gccfilename ne $filename
	|| $gcclineno != $lineno) {
	#push @write_newtext, "//LL '$gcclineno'  '$lineno' '$gccfilename' '$filename'\n";
	$gcclineno = $lineno;
	# We may not be on a empty line, if not add a CR
	my $nl = "\n";
	#if (($write_newtext[$#write_newtext]||"\n") !~ /\n$/m) {
	#    print "WNT $#write_newtext  $write_newtext[$#write_newtext]\n";
	#    $nl = "\n";
	#}
	if (defined $filename && $gccfilename ne $filename) {
	    $gccfilename = $filename;
	    # Don't use write_print, as we don't want the line number to change
	    push @write_newtext, "${nl}#line $gcclineno \"$gccfilename\"\n";
	} else {
	    # Don't use write_print, as we don't want the line number to change
	    push @write_newtext, "${nl}#line $gcclineno\n";
	}
    }
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
    my $keepstamp = $params{keep_timestamp};
    foreach my $var (keys %params) {
	# Copy variables so subprocesses can see them
	$self->_write_var($var, $params{$var});
    }

    # Read the old file, so we can tell if it changes
    my @oldtext;	# Old file contents
    local @write_newtext;  # New file contents
    if ($keepstamp) {
	my $fh = IO::File->new ($filename);
	if ($fh) {
	    @oldtext = $fh->getlines();
	    $fh->close();
	} else {
	    $keepstamp = 0;
	}
    }

    local $outputting = 1;
    local $outlineno = 1;	# Real line in current output file
    local $gcclineno = -1;	# Line we're telling compiler we are on
    local $gccfilename = "";	# Filename we're telling compiler we are on

    if ($as_imp || $as_int) {
	if ($as_int) {
	    _write_printf "#ifndef _%s_H\n#define _%s_H\n", uc $self->basename, uc $self->basename;
	}
	_write_lineno ($outlineno,$filename);
	_write_print "// This file generated automatically by $program\n";
	_write_printf "#include \"%s.h\"\n", $self->basename if $as_imp;
	_write_print "#include \"systemperl.h\"\n" if $as_int;
    }

    my $didmodule = 0;
    $didmodule = 1 if !($as_imp || $as_int);  # If in-place, skip #define
    my $basename = $self->basename;
    foreach my $line (@{$self->text}) {
	# [autos, filename, lineno, text]
	# [autos, filename, lineno, function, args, ...]
	my $needautos = $line->[0];
	my $srcfile   = $line->[1];
	my $srclineno = $line->[2];
	if ($autos || !$needautos) {
	    my $func = $line->[3];
	    if (ref $func) {
		# it contains a function and arguments to that func
		#print "$func ($line->[1], $fh, $line->[2], );\n";
		if ($as_imp||$as_int) {
		    # This way, errors in the AUTOs refer to the .cpp file
		    _write_lineno ($outlineno,$filename);
		}
		&{$func} ($line->[4],$line->[5],$line->[6],$line->[7],$line->[8],);
	    } else {
		my $text = $line->[3];
		if (defined $text && $outputting) {
		    $text =~ s/\b__MODULE__\b/$basename/g;
		    if (0 && !$didmodule && $text =~ /\b__MODULE__\b/) {
			# Has problem if __MODULE__ usage is before some includes
			_write_print "#define __MODULE__ ",$self->basename,"\n";
			$didmodule = 1;
		    }
		    if ($as_imp||$as_int) {
			_write_lineno ($srclineno,$srcfile);
		    }
		    _write_print $text;
		}
	    }
	}
    }

    if ($as_imp || $as_int) {
	_write_print "#undef __MODULE__\n" if $didmodule;
	_write_print "// This file generated automatically by $program\n";
	_write_printf "#endif /*_%s_H*/\n", uc $self->basename if $as_int;
    }

    # Write the file
    if (!$keepstamp
	|| (join ('',@oldtext) ne join ('',@write_newtext))) {
	print "Write $filename\n" if $SystemC::Netlist::Verbose;
	my $fh = IO::File->new (">$filename.tmp") or die "%Error: $! $filename.tmp\n";
        $self->unlink_if_error ("$filename.tmp");
	print $fh @write_newtext;
	$fh->close();
	rename "$filename.tmp", $filename;
    } else {
	print "Same $filename\n" if $SystemC::Netlist::Verbose;
    }
    unlink "$filename.tmp";
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

sub _write_autoascii_enum {
    my $self = shift;
    my $class = shift;
    my $element = shift;
    my $prefix = shift;

    _write_print ("${prefix}// Beginning of SystemPerl automatic enumeration\n");
    _write_print ("${prefix}const char *ascii (void) const {\n"
		  ."${prefix}   switch (${element}) {\n");

    my $href = $self->_enums() || {};
    foreach my $valsym (sort (keys %{$href->{$class}})) {
	my $name = $valsym;
	_write_print ("${prefix}   case ${valsym}: return \"${name}\";\n");
    }

    _write_print ("${prefix}   default: return \"%E:Bad${class}\";\n"
		  ."${prefix}   };\n"
		  ."${prefix}}\n"
		  .("${prefix}friend ostream& operator << "
		    ."(ostream& os, const ${class}& e) {"
		    ."return os << e.ascii(); }\n")
		  );
    _write_print ("${prefix}// Beginning of SystemPerl automatic enumeration\n");
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
