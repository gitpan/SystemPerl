# SystemC - SystemC Perl Interface
# $Id: AutoTrace.pm,v 1.9 2001/08/23 18:49:02 wsnyder Exp $
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
$VERSION = '0.430';
use strict;

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

    foreach my $netref ($modref->nets_sorted()) {
	next if ($netref->name =~ /^_/);	# Skip leading _ signals
	my $ignore = 0;
	#$ignore = "Memory Vector" if $netref->array();
	$ignore = "Unknown width" if !$netref->width();
	$ignore = "Wide Memory Vector"  if ($netref->array() && (($netref->width()||0)>32));

	my $accessor;	# Function call to get the value of the signal
	$accessor = $nethier.'->'.$netref->name;
	if ($netref->array) {
	    $accessor .= "[i]";
	}
	if (($netref->width||0) > 32) {
	    $accessor .= "[0]";
	}
	if (!$netref->simple_type) {
	    if ($netref->port && $netref->port->direction eq "out") {
		# This is nasty, and might even result in bad data
		# It also requires a library patch
		if (!$modref->netlist->{allow_output_tracing}) {
		    $ignore ||= "Can't read output ports";
		} else {
		    $accessor .= ".const_signal()->get_cur_value()";
		}
	    } else {
		$accessor .= ".read()";
	    }
	}
	my $code_inc = 0;
	if (!$ignore) {
	    $code_inc = (int($netref->width()/32) + 1);
	}
	push @{$tvarref}, {
	    modref => $modref,
	    netref => $netref,
	    level  => $level,
	    nethier => $nethier,
	    modhier => $modhier,
	    code_inc => $code_inc,
	    ignore => $ignore,
	    accessor => $accessor,
	};
    }
    if ($recurse) {
	foreach my $cellref ($modref->cells_sorted()) {
	    _tracer_setup($cellref->submod, $tvarref,
			  $recurse,
			  $level+1, $nethier."->".$cellref->name,
			  $modhier.".".$cellref->name,
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
	 "    tfp->spTrace()->addCallback (&${mod}::traceInit, &${mod}::traceChange, this);\n",);
    $fileref->print ("    if (levels > 0) {\n",);
    foreach my $cellref ($self->cells_sorted) {
	my $name = $cellref->name;
	(my $namenobra = $name) =~ tr/\[\]/()/;
	if ($cellref->submod->_autotrace()) {
	    $fileref->printf ("        this->${name}->trace (tfp, levels-1, options);  // Is-a %s\n",
				     $cellref->submod->name);
	}
    }
    $fileref->print ("    }\n",
		     "}\n",);
}

sub _write_tracer_init {
    my $modref = shift;
    my $fileref = shift;
    my $tr = shift; my @tracevars = @{$tr};
    
    my $mod = $modref->name;
    $fileref->print("void ${mod}::traceInit (SpTraceVcd* vcdp, void* userthis, uint32_t code)\n");
    $fileref->print("{\n");
    $fileref->print("  // Callback from vcd->open()\n");
    if ($#tracevars >= 0) {
	$fileref->print("  int c=code;\n");
	$fileref->print("  ${mod}* t=(${mod}*)userthis;\n");
	$fileref->print("  string prefix = t->name();\n");
    }
    my $last_modhier = undef;
    foreach my $tref (@tracevars) {
	my $modref = $tref->{modref};
	my $netref = $tref->{netref};
	my $indent = "  "x$tref->{level};
	my $accessor = $tref->{accessor};
	if (!defined $last_modhier || $last_modhier ne $tref->{modhier}) {
	    $last_modhier = $tref->{modhier};
	    $fileref->printf("${indent}vcdp->module(prefix+\"%s\");  // Is-a %s\n"
			     , $tref->{modhier}, $modref->name);
	}
	if ($netref->array) {
	    $fileref->printf("${indent}  for (int i=0; i<%s; ++i) {\n"
			     ,$netref->array);
	    $indent .= "  ";
	}

	if ($tref->{ignore}) {
	    $fileref->printf("${indent}  //IGNORED: %s: Type=%s  Array=%s\n"
			     ,$tref->{ignore},$netref->type||"",$netref->array||'');
	    $fileref->printf("${indent}  //{");
	} else {
	    $fileref->printf("${indent}  {");
	}
	if ($netref->type eq "sc_clock") {
	    $fileref->printf("const bool& tempClk=%s;\n", $accessor);
	    $fileref->printf("${indent}   ");
	    $accessor = "tempClk";
	}
	my $width = $netref->width || 1;
	my $arraynum = ($netref->array ? " i":"-1");
	$fileref->printf("");
	if ($width == 1) {
	    $fileref->printf("vcdp->declBit  (c,\"%s\",%s,&(%s)"
			     ,$netref->name, $arraynum, ${accessor});
	} elsif ($width <= 32) {
	    $fileref->printf("vcdp->declBus  (c,\"%s\",%s,&(%s),%d,%d"
			     ,$netref->name, $arraynum, ${accessor},$netref->msb, $netref->lsb);
	} else {
	    $fileref->printf("vcdp->declArray(c,\"%s\",%s,&(%s),%d,%d",
			     ,$netref->name, $arraynum, ${accessor},$netref->msb, $netref->lsb);
	}
	$fileref->printf("); c+=%s;}",$tref->{code_inc});
	$fileref->printf(" // Is-a: %s\n", $netref->type);
	if ($netref->array) {
	    $indent = "  "x$tref->{level};
	    $fileref->printf("${indent}  }\n");
	}
    }
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
    if ($#tracevars >= 0) {
	$fileref->print("  int c=code;\n");
	$fileref->print("  ${mod}* t=(${mod}*)userthis;\n");
    }
    foreach my $tref (@tracevars) {
	my $netref = $tref->{netref};
	next if $tref->{ignore};
	my $indent = "  "x$tref->{level};
	my $accessor = $tref->{accessor};

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
