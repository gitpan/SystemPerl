# SystemC - SystemC Perl Interface
# $Id: AutoTrace.pm,v 1.21 2002/03/11 15:52:09 wsnyder Exp $
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

package SystemC::Netlist::AutoTrace;
use File::Basename;

use SystemC::Netlist::Module;
$VERSION = '1.100';
use strict;

use vars qw ($Setup_Ident_Code);	# Local use for recursion only

######################################################################
#### Automatics (Preprocessing)

sub _write_autotrace {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    if ($self->_autotrace() eq 'manual') {
	$fileref->print
	    ("${prefix}// Beginning of SystemPerl automatic trace file routine\n",
	     "${prefix}// *MANUALLY CREATED*\n",
	     "${prefix}// End of SystemPerl automatic trace file routine\n",);
	return;
    }

    # Flatten out all hiearchy under this into a array of signal information
    my @tracevars = ();
    local $Setup_Ident_Code = 0;
    _tracer_setup($self,\@tracevars,
		  ($self->_autotrace() eq 'recurse'),
		  );

    # Output the data
    $fileref->print
	("${prefix}// Beginning of SystemPerl automatic trace file routine\n",
	 "#if WAVES\n",
	 "# include \"SpTraceVcd.h\"\n",);

    my $last_modref = 0;
    foreach my $tref (@tracevars) {
	my $modref = $tref->{modref};
	next if $modref == $last_modref;
	$last_modref = $modref;
	my $header = basename($modref->filename);
	$header =~ s/\.(c+p*|h|sp)/.h/;
	$fileref->print("#include \"${header}\"\n");
    }

    _write_tracer_trace($self, $fileref);
    _write_tracer_init ($self, $fileref, \@tracevars);
    _write_tracer_change($self, $fileref, \@tracevars);
    $fileref->print ("#endif\n");
    $fileref->print ("${prefix}// End of SystemPerl automatic trace file routine\n"),
}

sub _tracer_setup {
    my $modref = shift or return;   # Submodule may not exist if library cell
    my $tvarref = shift;
    my $recurse = shift;
    my $level = shift || 1;
    my $nethier = shift || "t";
    my $modhier = shift || "";
    my $upper_codes_ref = shift || {};

    my %our_codes;
    foreach my $netref ($modref->nets_sorted()) {
	next if ($netref->name =~ /^_/);	# Skip leading _ signals
	my $ignore = 0;
	#$ignore = "Memory Vector" if $netref->array();
	$ignore = "Unknown width" if !$netref->width();
	$ignore = "Wide Memory Signal"  if (($netref->width()||0)>256);
	$ignore = "Wide Memory Vector"  if ($netref->array()
					    && ($netref->array=~/^[0-9]/)
					    && (($netref->array()||0)>32));

	my $accessor = "";	# Function call to get the value of the signal
	my $scbv = ($netref->type =~ /^sc_bv/);
	if ($scbv) {
	    $accessor .= "(((uint32_t*)";
	}
	#$accessor .= $nethier.'->'.$netref->name;
	$accessor .= 'ts->'.$netref->name;
	if ($netref->array) {
	    $accessor .= "[i]";
	}
	if (($netref->width||0) > 32 && !$scbv) {
	    $accessor .= "[0]";
	}
	if (!$netref->simple_type) {
	    if ($netref->port && $netref->port->direction eq "out") {
		# This is nasty, and might even result in bad data
		# It also requires a library patch
		if (!$modref->netlist->{sp_allow_output_tracing}) {
		    $ignore ||= "Can't read output ports";
		} else {
		    $accessor .= ".const_signal()->get_cur_value()";
		}
	    } else {
		$accessor .= ".read()";
	    }
	    if ($scbv) {
		$accessor .= ".data)[0])";
	    }
	}
	my $code_inc = 0;
	if (!$ignore) {
	    $code_inc = (int($netref->width()/32) + 1);
	}
	my $identical = $upper_codes_ref->{$netref->name};

	# Store info for this var
	my $tref = {
	    modref => $modref,
	    netref => $netref,
	    level  => $level,
	    nethier => $nethier,
	    modhier => $modhier,
	    code_inc => $code_inc,
	    ignore => $ignore,
	    identical => $identical,
	    identical_code => ($identical || 0),
	    accessor => $accessor,
	};
	push @{$tvarref}, $tref;
	$our_codes{$netref->name} = $tref if $recurse;
    }
    if ($recurse) {
	foreach my $cellref ($modref->cells_sorted()) {
	    my %dup_codes = ();
	    if (!$modref->netlist->{sp_trace_duplicates}) {
		foreach my $pinref ($cellref->pins_sorted) {
		    if ($pinref->net && $pinref->port && $pinref->port->net
			&& $pinref->port->net->name eq $pinref->net->name
			&& $pinref->port->net->array eq $pinref->net->array
			&& $pinref->port->net->type eq $pinref->net->type
			&& $pinref->port->net->msb eq $pinref->net->msb
			&& $pinref->port->net->lsb eq $pinref->net->lsb
			) { # Then, it's the same signal.
			#print "PIN ",$cellref->name," XX ", $pinref->name,"\n";
			my $ourref = $our_codes{$pinref->net->name};
			$ourref->{identical_code} ||= ++$Setup_Ident_Code;
			my $ourcode = $ourref->{identical_code};
			$ourref->{identical_child} = $ourcode;	# May be more then one
			$dup_codes{$pinref->port->net->name} = $ourcode;
		    }
		}
	    }
	    _tracer_setup($cellref->submod, $tvarref,
			  $recurse,
			  $level+1, $nethier."->".$cellref->name,
			  $modhier.".".$cellref->name,
			  \%dup_codes,
			  );
	}
    }
}

sub _write_tracer_trace {
    my $self = shift;
    my $fileref = shift;
    
    my $mod = $self->name;
    $fileref->print
	("void ${mod}::trace (SpTraceFile* tfp, int levels, int options=0)\n",
	 "{\n",
	 "    if(0 && options) {}  // Prevent unused\n",
	 "    tfp->spTrace()->addCallback (&${mod}::traceInit, &${mod}::traceChange, this);\n",);
    my $cmt = "";
    if ($self->_autotrace() eq 'recurse') {
	$fileref->print ("    // Inline child recursion, so don't need:\n");
	$cmt = "//";
    }
    $fileref->print ("    ${cmt}if (levels > 0) {\n",);
    foreach my $cellref ($self->cells_sorted) {
	my $name = $cellref->name;
	(my $namenobra = $name) =~ tr/\[\]/()/;
	if ($cellref->submod->_autotrace()) {
	    $fileref->printf ("    ${cmt}    this->${name}->trace (tfp, levels-1, options);  // Is-a %s\n",
				     $cellref->submod->name);
	}
    }
    $fileref->print ("    ${cmt}}\n",
		     "}\n",);
}

sub _write_tracer_init {
    my $modref = shift;
    my $fileref = shift;
    my $tr = shift; my @tracevars = @{$tr};
    
    my $mod = $modref->name;
    $fileref->print("void ${mod}::traceInit (SpTraceVcd* vcdp, void* userthis, uint32_t code)\n");
    $fileref->print("{\n");
    $fileref->printf("  int _identcode[%d];\n", $Setup_Ident_Code+1) if $Setup_Ident_Code;
    $fileref->print("  // Callback from vcd->open()\n");
    $fileref->print("  if (0 && vcdp && userthis && code) {}  // Prevent unused\n");
    if ($#tracevars >= 0) {
	$fileref->print("  int c=code;\n");
	$fileref->print("  ${mod}* t=(${mod}*)userthis;\n");
	$fileref->print("  string prefix = t->name();\n");
    }
    $fileref->printf("  {\n");
    my $last_modhier = undef;
    foreach my $tref (@tracevars) {
	my $modref = $tref->{modref};
	my $netref = $tref->{netref};
	my $indent = "  "x$tref->{level};
	my $accessor = $tref->{accessor};
	# Scope to correct parent module
	if (!defined $last_modhier || $last_modhier ne $tref->{modhier}) {
	    $last_modhier = $tref->{modhier};
	    $fileref->printf("${indent}"."}{\n");
	    $fileref->printf("${indent}"."vcdp->module(prefix+\"%s\");  // Is-a %s\n"
			     , $tref->{modhier}, $modref->name);
	    $fileref->printf("${indent} register %s* ts = %s;\n"
			     , $modref->name, $tref->{nethier});
	}
	# Now do the signal
	if ($tref->{identical_child} && !$tref->{identical}) {   # This code is reused by a child module.
	    $fileref->printf("${indent}  _identcode[".$tref->{identical_child}."] = c;\n");
	}
	my $c = "c";
	my $ket = "";
	if ($tref->{identical}) {
	    $c = "lc";
	    $fileref->printf("${indent}  {int lc=_identcode[".$tref->{identical}."];\n"); 
	    $ket .= "}";
	}
	if ($netref->array && !$tref->{ignore}) {
	    $fileref->printf("${indent}  for (int i=0; i<%s; ++i) {\n"
			     ,$netref->array);
	    $indent .= "  ";
	    $ket .= "}";
	}

	if ($tref->{ignore}) {
	    $fileref->printf("${indent}  //IGNORED: %s: Type=%s  Array=%s\n"
			     ,$tref->{ignore},$netref->type||"",$netref->array||'');
	    $fileref->printf("${indent}  //{");
	} else {
	    $fileref->printf("${indent}  {");
	}
	$ket .= "}";
	if ($netref->type eq "sc_clock") {
	    $fileref->printf("const bool& tempClk=%s;\n", $accessor);
	    $fileref->printf("${indent}   ");
	    $accessor = "tempClk";
	}
	my $width = $netref->width || 1;
	my $arraynum = ($netref->array ? " i":"-1");
	$fileref->printf("");
	if ($width == 1) {
	    $fileref->printf("vcdp->declBit  (${c},\"%s\",%s,&(%s)"
			     ,$netref->name, $arraynum, ${accessor});
	} elsif ($width <= 32) {
	    $fileref->printf("vcdp->declBus  (${c},\"%s\",%s,&(%s),%d,%d"
			     ,$netref->name, $arraynum, ${accessor},$netref->msb, $netref->lsb);
	} else {
	    $fileref->printf("vcdp->declArray(${c},\"%s\",%s,&(%s),%d,%d",
			     ,$netref->name, $arraynum, ${accessor},$netref->msb, $netref->lsb);
	}
	$fileref->printf("); ${c}+=%s;$ket",$tref->{code_inc});
	$fileref->printf(" // Is-a: %s\n", $netref->type);
    }
    $fileref->printf("  }\n");
    $fileref->print("}\n");
}

sub _write_tracer_change {
    my $modref = shift;
    my $fileref = shift;
    my $tr = shift; my @tracevars = @{$tr};

    my $mod = $modref->name;
    $fileref->print("//","="x70,"\n");
    $fileref->print("void ${mod}::traceChange (SpTraceVcd* vcdp, void* userthis, uint32_t code)\n");
    $fileref->print("{\n");
    $fileref->print("  // Callback from vcd->dump()\n");
    $fileref->print("  if (0 && vcdp && userthis && code) {}  // Prevent unused\n");
    if ($#tracevars >= 0) {
	$fileref->print("  int c=code;\n");
	$fileref->print("  ${mod}* t=(${mod}*)userthis;\n");
    }
    $fileref->printf("  {\n");
    my $last_modhier = undef;
    foreach my $tref (@tracevars) {
	my $modref = $tref->{modref};
	my $netref = $tref->{netref};
	next if $tref->{ignore};
	next if $tref->{identical};
	my $indent = "  "x$tref->{level};
	my $accessor = $tref->{accessor};

	if (!defined $last_modhier || $last_modhier ne $tref->{modhier}) {
	    $last_modhier = $tref->{modhier};
	    $fileref->printf("${indent}"."}{\n");
	    $fileref->printf("${indent} register %s* ts = %s;\n"
			     , $modref->name, $tref->{nethier});
	}

	if ($netref->array) {
	    $fileref->printf("${indent}  for (int i=0; i<%s; ++i) {\n"
			     ,$netref->array);
	    $indent .= "  ";
	}
	if ($netref->type eq "sc_clock") {
	    $fileref->printf("${indent}  {const bool& tempClk=%s;\n",
			     $accessor);
	    $fileref->printf("${indent}   ");
	    $accessor = "tempClk";
	} else {
	    $fileref->printf("${indent}  {");
	}
	if ($netref->width == 1) {
	    $fileref->printf("vcdp->dumpBit  (c,  %s"
			     ,${accessor});
	} elsif ($netref->width <= 32) {
	    $fileref->printf("vcdp->dumpBus  (c,  %s,%d"
			     ,${accessor}, $netref->width);
	} else {
	    $fileref->printf("vcdp->dumpArray(c,&(%s),%d",
			     ,${accessor}, $netref->width);
	}
	$fileref->printf("); c+=%s;}\n",$tref->{code_inc});

	if ($netref->array) {
	    $indent = "  "x$tref->{level};
	    $fileref->printf("${indent}  }\n");
	}
    }
    $fileref->printf("  }\n");
    $fileref->print("}\n");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::AutoTrace - Tracing routines

=head1 DESCRIPTION

SystemC::Netlist::AutoTrace creates the /*AUTOTRACE*/ features.
It is called from SystemC::Netlist::Module.

=head1 SEE ALSO

L<SystemC::Netlist::Module>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
