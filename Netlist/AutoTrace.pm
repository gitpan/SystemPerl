# SystemC - SystemC Perl Interface
# $Revision: #25 $$Date: 2002/08/07 $$Author: wsnyder $
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

package SystemC::Netlist::AutoTrace;
use File::Basename;

use SystemC::Netlist::Module;
$VERSION = '1.110';
use strict;

use vars qw ($Setup_Ident_Code);	# Local use for recursion only

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

    # Flatten out all hiearchy under this into a array of signal information
    my $tracesref = {};
    local $Setup_Ident_Code = 0;
    _tracer_setup($self,$tracesref,
		  ($self->_autotrace('recurse')),
		  );

    # Output the data
    $fileref->print
	("${prefix}// Beginning of SystemPerl automatic trace file routine\n",
	 "#if WAVES\n",
	 "# include \"SpTraceVcd.h\"\n",);

    _tracer_include_recurse($self,$fileref,$tracesref);

    _write_tracer_trace($self, $fileref, $tracesref);
    _write_tracer_init ($self, $fileref, $tracesref);
    _write_tracer_change($self, $fileref, $tracesref);
    $fileref->print ("#endif\n");
    $fileref->print ("${prefix}// End of SystemPerl automatic trace file routine\n"),
}

sub _tracer_setup {
    my $modref = shift or return;   # Submodule may not exist if library cell
    my $tracesref = shift;
    my $recurse = shift;
    my $level = shift || 1;
    my $nethier = shift || "t";
    my $modhier = shift || "";
    my $upper_codes_ref = shift || {};

    # Tracesref is information on the module
    $tracesref->{modref} = $modref;
    $tracesref->{modhier} = $modhier;
    $tracesref->{nethier} = $nethier,
    $tracesref->{cells} = [];
	    
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
	    netref => $netref,
	    code_inc => $code_inc,
	    ignore => $ignore,
	    identical => $identical,
	    identical_code => ($identical || 0),
	    accessor => $accessor,
	};
	push @{$tracesref->{vars}}, $tref;
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
	    my $subref = {};
	    push @{$tracesref->{cells}}, $subref;
	    _tracer_setup($cellref->submod,
			  $subref,
			  $recurse,
			  $level+1, $nethier."->".$cellref->name,
			  $modhier.".".$cellref->name,
			  \%dup_codes,
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
	("void ${mod}::trace (SpTraceFile* tfp, int levels, int options=0) {\n",
	 "    if(0 && options) {}  // Prevent unused\n",
	 "    tfp->spTrace()->addCallback (&${mod}::traceInit, &${mod}::traceChange, this);\n",);
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
	    $fileref->printf ("    ${cmt}    this->${name}->trace (tfp, levels-1, options);  // Is-a %s\n",
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
    $fileref->print("void ${mod}::traceInit (SpTraceVcd* vcdp, void* userthis, uint32_t code) {\n");
    $fileref->printf("  int _identcode[%d];\n", $Setup_Ident_Code+1) if $Setup_Ident_Code;
    $fileref->print("  // Callback from vcd->open()\n");
    $fileref->print("  if (0 && vcdp && userthis && code) {}  // Prevent unused\n");
    if ($#{$tracesref->{vars}} >= 0) {
	$fileref->print("  int c=code;\n");
	$fileref->print("  ${mod}* t=(${mod}*)userthis;\n");
	$fileref->print("  string prefix = t->name();\n");
    }
    _write_tracer_init_recurse($self,$fileref,$tracesref);
    $fileref->print("}\n");
}

sub _write_tracer_init_recurse {
    my $self = shift;
    my $fileref = shift;
    my $tracesref = shift;
    my $level = shift||1;

    my $indent = "  "x$level;

    my $modref = $tracesref->{modref};
    $fileref->printf("${indent}\{\n");
    $fileref->printf("${indent} vcdp->module(prefix+\"%s\");  // Is-a %s\n"
		     , $tracesref->{modhier}, $modref->name);
    $fileref->printf("${indent} register %s* ts = %s;\n"
		     , $modref->name, $tracesref->{nethier});

    foreach my $tref (@{$tracesref->{vars}}) {
	my $netref = $tref->{netref};
	my $accessor = $tref->{accessor};
	# Scope to correct parent module
	# Now do the signal
	if ($tref->{identical_child} && !$tref->{identical}) {   # This code is reused by a child module.
	    $fileref->printf("${indent}  _identcode[".$tref->{identical_child}."] = c;\n");
	}
	my $c = "c";
	my $ket = "";
	if ($tref->{identical} && !$tref->{ignore}) {
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

    foreach my $tref (@{$tracesref->{cells}}) {
	_write_tracer_init_recurse($self, $fileref, $tref, $level+1);
    }
    $fileref->printf("${indent}\}\n");
}

sub _write_tracer_change {
    my $self = shift;
    my $fileref = shift;
    my $tracesref = shift;

    my $mod = $self->name;
    $fileref->print("//","="x70,"\n");
    $fileref->print("void ${mod}::traceChange (SpTraceVcd* vcdp, void* userthis, uint32_t code) {\n");
    $fileref->print("  // Callback from vcd->dump()\n");
    $fileref->print("  if (0 && vcdp && userthis && code) {}  // Prevent unused\n");
    if ($#{$tracesref->{vars}} >= 0) {
	$fileref->print("  int c=code;\n");
	$fileref->print("  ${mod}* t=(${mod}*)userthis;\n");
    }
    _write_tracer_change_recurse($self,$fileref,$tracesref);

    $fileref->print("}\n");
}

sub _write_tracer_change_recurse {
    my $self = shift;
    my $fileref = shift;
    my $tracesref = shift;
    my $level = shift||1;

    my $indent = "  "x$level;

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
	next if $tref->{identical};
	my $accessor = $tref->{accessor};

	my $aindent = $indent;
	if ($netref->array) {
	    $fileref->printf("${indent}  for (int i=0; i<%s; ++i) {\n"
			     ,$netref->array);
	    $aindent .= "  ";
	    if ($netref->array =~ /^\d/) {
		$code_inc += $netref->array;
	    } else {
		$code_math .= "+".$netref->array;   # Let compiler sort it out
	    }
	} else {
	    $code_inc += $tref->{code_inc};
	}
	if ($netref->type eq "sc_clock") {
	    $fileref->printf("${aindent}  {const bool& tempClk=%s;\n",
			     $accessor);
	    $fileref->printf("${aindent}   ");
	    $accessor = "tempClk";
	} else {
	    $fileref->printf("${aindent}  {");
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
	    $fileref->printf("${indent}  }\n");
	}
    }
    foreach my $tref (@{$tracesref->{cells}}) {
	my ($subcode_inc, $subcode_math) 
	    = _write_tracer_change_recurse($self, $fileref, $tref, $level+1);
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
