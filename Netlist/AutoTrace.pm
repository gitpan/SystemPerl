# SystemC - SystemC Perl Interface
# $Revision: #54 $$Date: 2004/08/12 $$Author: ws150726 $
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

package SystemC::Netlist::AutoTrace;
use File::Basename;

use SystemC::Netlist::Module;
$VERSION = '1.160';
use strict;

use vars qw ($Setup_Ident_Code);	# Local use for recursion only
use vars qw ($Debug_Check_Code);
#$Debug_Check_Code=1;	# Compile in debugging check of sig identifiers

######################################################################
#### Automatics (Preprocessing)

sub _write_autotrace {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    return if !$SystemC::Netlist::File::outputting;
    if ($self->_autotrace('manual')) {
	$fileref->print
	    ("${prefix}// Beginning of SystemPerl automatic trace file routine\n",
	     "${prefix}// *MANUALLY CREATED*\n",
	     "${prefix}// End of SystemPerl automatic trace file routine\n",);
	return;
    }

    # Detect duplicate signal information
    my $dupsref = {};
    if ($self->_autotrace('recurse') && !$self->netlist->{sp_trace_duplicates}) {
	_tracer_dups_recurse($self,$dupsref);
	_tracer_dups_show($self,$dupsref) if $Debug_Check_Code;
    }

    # Flatten out all hiearchy under this into a array of signal information
    my $tracesref = {};
    local $Setup_Ident_Code = 0;
    _tracer_setup($self,$tracesref,
		  $dupsref, {},
		  ($self->_autotrace('recurse')),
		  );

    # Output the data
    $fileref->print ("${prefix}// Beginning of SystemPerl automatic trace file routine\n");

    if ($self->_autotrace('exists')) {
	$fileref->print ("${prefix}// Exists switch: predeclared tracing routine\n");
    } else {
	$fileref->print ("#if WAVES\n",
			 "# include \"SpTraceVcd.h\"\n",);
	_tracer_include_recurse($self,$fileref,$tracesref);
	_write_tracer_trace($self, $fileref, $tracesref);
	_write_tracer_init ($self, $fileref, $tracesref);
	_write_tracer_change($self, $fileref, $tracesref, "full");
	_write_tracer_change($self, $fileref, $tracesref, "chg");
	$fileref->print ("#endif // WAVES\n");
    }
    $fileref->print ("${prefix}// End of SystemPerl automatic trace file routine\n"),
}

sub _tracer_dups_recurse {
    my $modref = shift or return;   # Submodule may not exist if library cell
    my $dupsref = shift;	# global entry to write to
    my $modhier = shift || "";	# ".cellname" appended each recursion
    # Goal: For each signal, try to find the lowest level in the hiearchy that
    # sources that signal.  (There are the fewest changedetects at lower levels.)

    # Add our nets to the layout
    foreach my $cellref ($modref->cells_sorted()) {
	my $submodhier = $modhier.".".$cellref->name;
	foreach my $pinref ($cellref->pins_sorted) {
	    if ($pinref->net && $pinref->port && $pinref->port->net
		&& $pinref->port->net->array eq $pinref->net->array
		&& $pinref->port->net->type eq $pinref->net->type
		&& $pinref->port->net->msb eq $pinref->net->msb
		&& $pinref->port->net->lsb eq $pinref->net->lsb
		&& !_net_ignore($pinref->port->net, $modref)
		&& !_net_ignore($pinref->net, $modref)
		) {
		# Thus, it's the same signal passed across the hiearchy.
		#print "PIN ",$cellref->name," XX ", $pinref->name,"\n";
		my $nethiername = $modhier."->".$pinref->net->name;
		my $subnethiername = $submodhier."->".$pinref->port->net->name;
		# We link *references* so that changing one reference value changes
		# all signal users that point to it.
		my $linkref = $nethiername;
		$dupsref->{$nethiername} ||= \$linkref;
		if ($pinref->port->direction() eq 'out') {
		    # Output, use submod's change
		    ${$dupsref->{$nethiername}} = $subnethiername;
		    $dupsref->{$subnethiername} = $dupsref->{$nethiername};
		} else {
		    # In/inout use upper's change
		    $dupsref->{$subnethiername} = $dupsref->{$nethiername};
		}
	    }
	}
	_tracer_dups_recurse ($cellref->submod,
			      $dupsref,
			      $submodhier,
			      );
    }
}

sub _tracer_dups_show {
    my $modref = shift;
    my $dupsref = shift;	# global entry to write to
    print "DUPS ",$modref->name,"\n";
    printf "  %-40s %s\n", "NET", "Gets data from NET";
    foreach my $netname (sort (keys %{$dupsref})) {
	my $outputter_name = ${$dupsref->{$netname}};
	if ($outputter_name ne $netname) {
	    printf "  %-40s %s\n", $netname, $outputter_name;
	}
    }
}

sub _net_ignore {
    my $netref = shift;
    my $modref = shift;
    # Return a reason for ignoring this signal, or undef
    return "Leading _" if ($netref->name =~ /^_/ 	# Skip leading _ signals
			   && $netref->name !~ /^__PVT__[^_]/);
    return "Unknown width of type ".$netref->type() if !$netref->width();
    return "Wide Memory Signal"  if (($netref->width()||0)>256);
    return "Wide Memory Vector"  if ($netref->array()
				     && ($netref->array=~/^[0-9]/)
				     && (($netref->array()||0)>32));
    my $scbv = ($netref->type =~ /^sc_bv/);
    if (!$netref->simple_type) {
	if ($netref->port && $netref->port->direction eq "out") {
	    if (!$modref->netlist->{sp_allow_output_tracing}) {
		return "Can't read output ports -- need patch";
	    }
	}
	if ($scbv && !$modref->netlist->{sp_allow_bv_tracing}) {
	    return "Memory Vector - need patch";
	}
    }
    return undef;
}

sub _tracer_setup {
    my $modref = shift or return;   # Submodule may not exist if library cell
    my $tracesref = shift;	# *PARENT's* {cells} entry to write to
    my $dupsref = shift;	# global duplicate information
    my $dupscoderef = shift;	# global duplicate code number info
    my $recurse = shift;	# static across recursions; AUTOTRACE(,recurse) switch
    my $level = shift || 1;	# increments each recursion
    my $nethier = shift || "t";	# "->cellname" appended each recursion
    my $modhier = shift || "";	# ".cellname" appended each recursion

    # Tracesref has information on the module
    $tracesref->{modref} = $modref;
    $tracesref->{modhier} = $modhier;
    $tracesref->{nethier} = $nethier,
    $tracesref->{cells} = [];
	    
    my %our_codes;
    foreach my $netref ($modref->nets_sorted()) {
	my $ignore = _net_ignore($netref,$modref);

	my $accessor = "";	# Function call to get the value of the signal
	my $scbv = ($netref->type =~ /^sc_bv/);
	if ($scbv) {
	    $accessor .= "(((uint32_t*)";
	}
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
		    $ignore or die "%Error: Should have ignored, Can't read output ports,";
		} elsif ($modref->netlist->{sp_allow_output_tracing} eq 'hack') {
		    # SystemC 1.0.1a
		    $accessor .= ".const_signal()->get_cur_value()";
		} else {
		    $accessor .= ".read()";
		}
	    } else {
		$accessor .= ".read()";
	    }
	    if ($scbv) {
		$accessor .= ".get_datap())[0])";
		$ignore or die "%Error: Should have ignored, memory vector,"
		    if (!$ignore && !$modref->netlist->{sp_allow_bv_tracing});
	    }
	}

	my $code_inc = 0;
	if (!$ignore) {
	    $code_inc = (int($netref->width()/32) + 1);
	}

	# Check identicals
	my $nethiername = $modhier."->".$netref->name;
	my $identical = $dupsref->{$nethiername} && ${$dupsref->{$nethiername}};
	my $identical_decl; my $identical_use;
	if ($identical && !$ignore) {
	    # Thus, it's the same signal passed across the hiearchy.
	    if (!defined $dupscoderef->{$identical}) {
		# First module that references it gets to choose the code for it
		# This isn't necessarially the same cell that generates the *value*
		$dupscoderef->{$identical}{code} = ++$Setup_Ident_Code;
	    }
	    if ($identical ne $nethiername) { 	# Driven from somewhere else
		# Use previous declaration
		$identical_use = $dupscoderef->{$identical}{code};
	    } else {
		$identical_decl = $dupscoderef->{$identical}{code};
	    }
	}

	# Report errors
	if ($netref->sp_traced && $ignore) {
	    $netref->warn("Ignoring SP_TRACED, $ignore: ".$netref->name."\n");
	}

	# Store info for this var
	my $tref = {
	    netref => $netref,
	    code_inc => $code_inc,
	    ignore => $ignore,
	    identical_decl => $identical_decl,
	    identical_use => $identical_use,
	    accessor => $accessor,
	};
	push @{$tracesref->{vars}}, $tref;
	$our_codes{$netref->name} = $tref if $recurse;
	$tref->{check_code} = $Debug_Check_Code++ if $Debug_Check_Code;
    }
    if ($recurse) {
	foreach my $cellref ($modref->cells_sorted()) {
	    my $subref = {};
	    push @{$tracesref->{cells}}, $subref;
	    _tracer_setup($cellref->submod,
			  $subref,
			  $dupsref,
			  $dupscoderef,
			  $recurse,
			  $level+1,
			  $nethier."->".$cellref->name,
			  $modhier.".".$cellref->name,
			  );
	}
    }
}

sub _tracer_include_recurse {
    my $self = shift;
    my $fileref = shift;
    my $tracesref = shift;
    my $level = shift||0;

    my $modref = $tracesref->{modref};
    my $header = basename($modref->filename);
    $header =~ s/\.(c+p*|h|sp)/.h/;
    $fileref->print("#".(" "x$level)."include \"${header}\"\n");

    foreach my $cellref (@{$tracesref->{cells}}) {
	_tracer_include_recurse($self,$fileref,$cellref,$level);
    }
}

sub _write_tracer_trace {
    my $self = shift;
    my $fileref = shift;
    #my $tracesref = shift;
    
    my $mod = $self->name;

    $fileref->print
	("void ${mod}::trace (SpTraceFile* tfp, int levels, int options) {\n",
	 "    if(0 && options) {}  // Prevent unused\n",
	 "    tfp->spTrace()->addCallback (&${mod}::traceInit, &${mod}::traceFull,  &${mod}::traceChg, this);\n",);
    my $cmt = "";
    if ($self->_autotrace('recurse')) {
	$fileref->print ("    // Inline child recursion, so don't need:\n");
	$cmt = "//";
    }
    $fileref->print ("    ${cmt}if (levels > 0) {\n",);
    foreach my $cellref ($self->cells_sorted) {
	my $name = $cellref->name;
	(my $namenobra = $name) =~ tr/\[\]/()/;
	if ($cellref->submod->_autotrace('on')) {
	    $fileref->printf ("    ${cmt}    if (this->${name}) this->${name}->trace (tfp, levels-1, options);  // Is-a %s\n",
			      $cellref->submod->name);
	}
    }
    $fileref->print ("    ${cmt}}\n",
		     "}\n",);
}

sub _write_tracer_init {
    my $self = shift;
    my $fileref = shift;
    my $tracesref = shift;
    
    my $mod = $self->name;
    $fileref->printf("static int ${mod}_checkcode[%d];\n\n", $Debug_Check_Code+1) if $Debug_Check_Code;

    $fileref->print("void ${mod}::traceInit (SpTraceVcd* vcdp, void* userthis, uint32_t code) {\n");
    $fileref->printf("  int _identcode[%d];\n", $Setup_Ident_Code+1) if $Setup_Ident_Code;
    $fileref->printf("  for (int i=0; i<%d; i++) { _identcode[i]=0; }\n", $Setup_Ident_Code+1) if $Setup_Ident_Code;
    $fileref->print("  // Callback from vcd->open()\n");
    $fileref->print("  if (0 && vcdp && userthis && code) {}  // Prevent unused\n");
    if ($#{$tracesref->{vars}} >= 0) {
	$fileref->print("  int c=code;\n");
	$fileref->print("  ${mod}* t=(${mod}*)userthis;\n");
	$fileref->print("  string prefix = t->name();\n");
	$fileref->print("  // Calculate identical signal codes\n");
    }
    
    _write_tracer_init_recurse($self,$fileref,$tracesref, 1);
    if ($#{$tracesref->{vars}} >= 0) {
	$fileref->print("  // Setup signal names\n");
	$fileref->print("  c=code;\n");
    }
    _write_tracer_init_recurse($self,$fileref,$tracesref, 0);
    $fileref->print("}\n");
}

sub _dedot {
    my $dot = shift;
    $dot =~ s/__PVT__//g;
    $dot =~ s/__DOT__/./g;
    return $dot;
}

sub _write_tracer_init_recurse {
    my $self = shift;
    my $fileref = shift;
    my $tracesref = shift;
    my $doident = shift;
    my $level = shift||1;

    my $indent = "  "x$level;

    my $mod = $self->name;
    my $modref = $tracesref->{modref};
    if ($doident) {
	$fileref->printf("${indent}\{ // %s\n", $tracesref->{modhier});
    } else {
	$fileref->printf("${indent}\{\n");
	$fileref->printf("${indent} vcdp->module(prefix+\"%s\");  // Is-a %s\n"
			 , _dedot($tracesref->{modhier}), $modref->name);
    }

    foreach my $tref (@{$tracesref->{vars}}) {
	my $netref = $tref->{netref};
	my $aindent = $indent;
	# Scope to correct parent module
	# Now do the signal
	if ($doident) {
	    $fileref->printf("${aindent}  // ".$netref->name."\n") if $Debug_Check_Code;
	    if ($tref->{identical_decl}) {   # This code is reused by a child module.
		$fileref->printf("${aindent}  _identcode[".$tref->{identical_decl}."] = c;\n");
	    }
	}
	if ($doident) {
	    $fileref->printf("${aindent}  ${mod}_checkcode[".$tref->{check_code}."] = c-code;\n") if $Debug_Check_Code;
	    next if $tref->{identical_use};
	    next if $tref->{ignore};
	} else {
	    $fileref->printf("${aindent}  if (${mod}_checkcode[".$tref->{check_code}."] != c-code) abort();\n") if $Debug_Check_Code;
	}
	my $c = "c";
	my $ket = "";
	if ($tref->{identical_use} && !$tref->{ignore}) {
	    $c = "lc";
	    $fileref->printf("${aindent}  {int lc=_identcode[".$tref->{identical_use}."];\n"); 
	    $ket .= "}";
	}
	if ($netref->array && !$tref->{ignore}) {
	    $fileref->printf("${aindent}  for (int i=0; i<%s; ++i) {\n"
			     ,$netref->array);
	    $aindent .= "  ";
	    $ket .= "}";
	}

	if ($tref->{ignore}) {
	    $fileref->printf("${aindent}  //IGNORED: %s: Type=%s  Array=%s\n"
			     ,$tref->{ignore},$netref->type||"",$netref->array||'');
	    $fileref->printf("${aindent}  //{");
	} else {
	    $fileref->printf("${aindent}  {");
	}
	$ket .= "}";

	my $width = $netref->width || 1;
	my $arraynum = ($netref->array ? " i":"-1");
	$fileref->printf("");
	my $name = _dedot($netref->name());
	if (!$doident) {
	    if ($width == 1) {
		$fileref->printf("vcdp->declBit  (${c},\"%s\",%s"
				 ,$name, $arraynum);
	    } elsif ($width <= 32) {
		$fileref->printf("vcdp->declBus  (${c},\"%s\",%s,%d,%d"
				 ,$name, $arraynum,$netref->msb, $netref->lsb);
	    } else {
		$fileref->printf("vcdp->declArray(${c},\"%s\",%s,%d,%d",
				 ,$name, $arraynum,$netref->msb, $netref->lsb);
	    }
	    $fileref->printf("); ");
	}
	$fileref->printf("${c}+=%s;$ket",$tref->{code_inc});
	if ($doident) {
	    $fileref->printf("\n");
	} else {
	    $fileref->printf(" // Is-a: %s\n", $netref->type);
	}
    }

    foreach my $tref (@{$tracesref->{cells}}) {
	_write_tracer_init_recurse($self, $fileref, $tref, $doident, $level+1);
    }
    $fileref->printf("${indent}\}\n");
}

sub _write_tracer_change {
    my $self = shift;
    my $fileref = shift;
    my $tracesref = shift;
    my $mode = shift;   # full or chg

    my $mod = $self->name;
    $fileref->print("//","="x70,"\n");
    $fileref->print("void ${mod}::trace".ucfirst($mode)." (SpTraceVcd* vcdp, void* userthis, uint32_t code) {\n");
    $fileref->print("  // Callback from vcd->dump()\n");
    $fileref->print("  if (0 && vcdp && userthis && code) {}  // Prevent unused\n");
    if ($#{$tracesref->{vars}} >= 0) {
	$fileref->print("  int c=code;\n");
	$fileref->print("  ${mod}* t=(${mod}*)userthis;\n");
    }
    _write_tracer_change_recurse($self,$fileref,$tracesref,$mode);

    $fileref->print("}\n");
}

sub _write_tracer_change_recurse {
    my $self = shift;
    my $fileref = shift;
    my $tracesref = shift;
    my $mode = shift;   # full or chg
    my $level = shift||1;

    my $indent = "  "x$level;

    my $mod = $self->name;
    my $modref = $tracesref->{modref};
    $fileref->printf("${indent}\{\n");
    $fileref->printf("${indent} register %s* ts = %s;\n"
		     , $modref->name, $tracesref->{nethier});

    my $use_activity=$self->_autotrace('activity');
    if ($use_activity) {
	$fileref->printf("${indent} if (ts->getClearActivity()) {\n");
    } else {
	$fileref->printf("${indent} {\n");
    }

    my $code_inc = 0;
    my $code_math = "";

    foreach my $tref (@{$tracesref->{vars}}) {
	my $netref = $tref->{netref};
	next if $tref->{ignore};
	next if $tref->{identical_use};
	my $accessor = $tref->{accessor};

	$fileref->printf("${indent}  if (${mod}_checkcode[".$tref->{check_code}."] != c-code) abort();\n") if $Debug_Check_Code;

	my $aindent = $indent;
	if ($netref->array) {
	    $fileref->printf("${indent}  for (int i=0; i<%s; ++i) {\n"
			     ,$netref->array);
	    $aindent .= "  ";
	    if ($netref->array =~ /^\d+$/) {
		$code_inc += ($netref->array * $tref->{code_inc});
	    } else {
		$code_math .= "+((".$netref->array.")*".$tref->{code_inc}.")";   # Let compiler sort it out
	    }
	} else {
	    $code_inc += $tref->{code_inc};
	}
	if ($netref->cast_type) {
	    $fileref->printf("${aindent}  {const ".$netref->cast_type." tempVal=%s;\n",
			     $accessor);
	    $fileref->printf("${aindent}   ");
	    $accessor = "tempVal";
	} else {
	    $fileref->printf("${aindent}  {");
	}
	if ($netref->width == 1) {
	    $fileref->printf("vcdp->${mode}Bit  (c,  %s"
			     ,${accessor});
	} elsif ($netref->width <= 32) {
	    $fileref->printf("vcdp->${mode}Bus  (c,  %s,%d"
			     ,${accessor}, $netref->width);
	} else {
	    $fileref->printf("vcdp->${mode}Array(c,&(%s),%d",
			     ,${accessor}, $netref->width);
	}
	$fileref->printf("); c+=%s;}\n",$tref->{code_inc});

	if ($netref->array) {
	    $fileref->printf("${indent}  }\n");
	}
    }
    foreach my $tref (@{$tracesref->{cells}}) {
	my ($subcode_inc, $subcode_math) 
	    = _write_tracer_change_recurse($self, $fileref, $tref, $mode, $level+1);
	$code_inc += $subcode_inc;
	$code_math .= $subcode_math;
    }

    if ($use_activity) {
	$fileref->printf("${indent} } else {\n");  # Else no activity
	$fileref->printf("${indent}  c+=${code_inc}${code_math}; // No activity\n");
    }

    $fileref->printf("${indent}}}\n");
    return ($code_inc,$code_math);
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
