# SystemC - SystemC Perl Interface
# See copyright, etc in below POD section.
######################################################################

package SystemC::Netlist::CoverPoint;
use Class::Struct;
use Carp;

use Verilog::Netlist;
use Verilog::Netlist::Subclass;
@ISA = qw(SystemC::Netlist::CoverPoint::Struct
	  Verilog::Netlist::Subclass);
$VERSION = '1.310';
use strict;

# allow 64-bit values without bonking
no warnings 'portable';

# The largest value for which we will use the faster lookup table
# to compute bin number (as opposed to if statements)
use constant MAX_BIN_LOOKUP_SIZE => 256;

# longest allowed user-defined string
#use constant MAX_USER_STRING_LEN => 256;
use constant MAX_USER_STRING_LEN => 5000;

struct('Bin'
       =>[name          => '$', #'	# name of bin
	  ranges   	=> '@', #'	# ranges
	  values  	=> '@', #'	# individual values
	  isIllegal     => '$', #'	# is it an illegal bin (assert)
	  isIgnore      => '$', #'	# is it an ignore bin (no need to cover)
	  ]);

structs('new',
	'SystemC::Netlist::CoverPoint::Struct'
	=>[name     	=> '$', #'	# coverpoint name
	   connection  	=> '$', #'	# class member to which we connect
	   description  => '$', #'      # description of the point
	   page         => '$', #'      # HTML page name; default group's page
	   defaultName  => '$', #'	# Name of default bin
	   type         => '$', #'	# type of coverpoint
	   num_bins     => '$', #'	# number of bins
	   bins         => '@', #'	# list of bin data structures
	   maxValue     => '$', #'	# max specified value
	   minValue     => '$', #'	# min specified value
	   enum         => '$', #'	# if an enum, what's the enum name?
	   ignoreFunc   => '$', #'	# if present, the function name to compute ignores
	   illegalFunc  => '$', #'	# if present, the function name to compute illegals
	   isCross      => '$', #'	# is this point a cross
	   crossMember  => '$', #'	# is this point a member of another cross
	   radix        => '$', #'	# for standard bins, with what radix to number them
	   rows         => '@', #'	# (cross) list of rows
	   cols   	=> '@', #'	# (cross) list of columns
	   tables   	=> '@', #'	# (cross) list of tables
	   #
	   attributes	=> '%', #'	# Misc attributes for systemperl
	   #
	   module	=> '$', #'	# Module containing statement
	   filename 	=> '$', #'	# Filename this came from
	   lineno	=> '$', #'	# Linenumber this came from
	   ]);

######################################################################
#### Accessors

sub logger { return $_[0]->module->logger; }

######################################################################
#### Module additions

package SystemC::Netlist::Module;

sub close_new_coverpoint {
    my $self = shift;

    # add to group
    my $currentCovergroup = $self->current_covergroup();
    $currentCovergroup->add_point($self->attributes("_openCoverpoint"));

    # allow next call to make a new one
    $self->attributes("_openCoverpoint",undef);
}

sub current_coverpoint {
    my $self = shift;

    if (!defined $self->attributes("_openCoverpoint")) {
	# Create a new coverage point
	my $coverpointref = new SystemC::Netlist::CoverPoint
	    (module   => $self,
	     lineno   => $self->lineno,
	     filename => $self->filename,
	     num_bins => 1,
	     name     => "",
	     description => "",
	     defaultName => "",
	     maxValue => 0,
	     minValue => 0,
	     crossMember => 0,
	     radix => 10,
	     );
	$self->attributes("_openCoverpoint",$coverpointref);
    }
    return $self->attributes("_openCoverpoint");
}

######################################################################
#### Automatics (Preprocessing)
package SystemC::Netlist::CoverPoint;

sub current_bin {
    my $self = shift;

    if (!defined $self->attributes("_openBin")) {
	$self->attributes("_openBin",
			  Bin->new(isIllegal => 0,
				   isIgnore => 0,
				   )
			  );
    }
    return $self->attributes("_openBin");
}

sub coverpoint_sample_text {
    my $self = shift;
    my $groupname = shift;

    my $pointname = $self->name;
    my $out;

    if ($self->crossMember) {
	$out .= "/* point name = $pointname is a crossMember - no separate sample needed */\n";
    } elsif ($self->isCross) {
	$out .= "/* cross name = $pointname */\n";
	$out .= "{ ++_sp_cg_".$groupname."_".$pointname;

	my @dimensions;
	push @dimensions, @{$self->rows};
	push @dimensions, @{$self->cols};
	push @dimensions, @{$self->tables};

	foreach my $dimension (@dimensions) {
	    $out .= "[_sp_cg_".$groupname."_".$dimension->name;
	    $out .= "_computeBin(".$dimension->connection.")]";
	}
	$out .= "; }\n";
    } else {
	$out .= "/* point name = $pointname */\n";
	#$out .= "{ printf(\"val %d -> bin %d\\n\",(int)".$coverpointref->connection.".read(),(int)_sp_cg_".$groupname."_".$pointname."_computeBin(".$coverpointref->connection.")); fflush(stdout); }\n";
	$out .= "{ ++_sp_cg_".$groupname."_".$pointname."[_sp_cg_".$groupname."_".$pointname."_computeBin(".$self->connection.")]; }\n";
    }

    return $out;
}

sub cross_build {
    my $self = shift;
    my $fileref = shift;
    my $type = shift;

    if ($type eq "start_rows") {
	print "start rows\n" if $SystemC::Netlist::Debug;
	$self->attributes("dimension","rows");
    } elsif ($type eq "start_cols") {
	print "start cols\n" if $SystemC::Netlist::Debug;
	$self->attributes("dimension","cols");
    } elsif ($type eq "start_table") {
	print "start table\n" if $SystemC::Netlist::Debug;
	$self->attributes("dimension","tables");
    } elsif ($type eq "item") {
	my $item = shift;
	print "item $item\n" if $SystemC::Netlist::Debug;

	# check that $item is a coverpoint we already know about
	my $currentCovergroup = $self->module->current_covergroup();
	foreach my $point (@{$currentCovergroup->coverpoints}) {
	    if ($point->name eq $item) {
		$point->crossMember(1);
		my $dimension = $self->attributes("dimension");
		if ($dimension eq "rows") {
		    push @{$self->rows}, $point;
		} elsif ($dimension eq "cols") {
		    push @{$self->cols}, $point;
		} elsif ($dimension eq "tables") {
		    push @{$self->tables}, $point;
		} else {
		    $self->error("CoverPoint internal error: dimension == $dimension\n");
		}
		return; # if we never get a match, fall through to the error below
	    }
	}
	$self->error("Netlist::File: cross parsed an unrecognized coverpoint: $item\n");
    } else {
	$self->error("Netlist::File: cross parsed an unexpected type: $type\n");
    }
}

sub coverpoint_build {
    my $self = shift;
    my $fileref = shift;
    my $type = shift;

    if ($type eq "binval") {
	my $val_str = shift;
	print "Netlist::File: coverpoint parsed binval: $val_str\n" if $SystemC::Netlist::Debug;
	my $bin = $self->current_bin();
	push @{$bin->values}, $val_str;

	if ($self->attributes("in_multi_bin")) {

	    $bin->name($self->attributes("multi_bin_basename")
		       ."_"
		       .$self->attributes("multi_bin_count"));
	    $self->attributes("multi_bin_count",
			      1 + $self->attributes("multi_bin_count"));
	}

	$bin->isIllegal(1) if ($self->attributes("in_illegal"));
	$bin->isIgnore(1)  if ($self->attributes("in_ignore"));

	# add this bin to the point
	push @{$self->bins}, $bin;
	# undef it so that the next bin will be fresh
	$self->attributes("_openBin",undef);

    } elsif ($type eq "binrange") {
	my $lo_str = shift;
	my $hi_str = shift;
	print "Netlist::File: coverpoint parsed binrange: $lo_str:$hi_str\n" if $SystemC::Netlist::Debug;
	my $bin = $self->current_bin();
	push @{$bin->ranges}, "$hi_str,$lo_str";

	if ($self->attributes("in_multi_bin")) {
	    $bin->name($self->attributes("multi_bin_basename")
		       ."_"
		       .$self->attributes("multi_bin_count"));
	    $self->attributes("multi_bin_count",
			      1 + $self->attributes("multi_bin_count"));
	}

	$bin->isIllegal(1) if ($self->attributes("in_illegal"));
	$bin->isIgnore(1)  if ($self->attributes("in_ignore"));

	# add this bin to the point
	push @{$self->bins}, $bin;
	# undef it so that the next bin will be fresh
	$self->attributes("_openBin",undef);
    } elsif ($type eq "illegal") {
	my $binname = shift;
	print "Netlist::File: coverpoint parsed illegal bin, name = $binname\n" if $SystemC::Netlist::Debug;
	my $bin = $self->current_bin();
	$bin->name($binname);
	$self->attributes("in_illegal",1);
	$self->attributes("in_ignore",0);
    } elsif ($type eq "ignore") {
	my $binname = shift;
	print "Netlist::File: coverpoint parsed ignore bin, name = $binname\n" if $SystemC::Netlist::Debug;
	my $bin = $self->current_bin();
	$bin->name($binname);
	$self->attributes("in_illegal",0);
	$self->attributes("in_ignore",1);
    } elsif ($type eq "ignore_func") {
	my $func = shift;
	$self->ignoreFunc($func);
    } elsif ($type eq "illegal_func") {
	my $func = shift;
	$self->illegalFunc($func);
    } elsif ($type eq "normal") {
	my $binname = shift;
	print "Netlist::File: coverpoint parsed normal bin, name = $binname\n" if $SystemC::Netlist::Debug;

	if (length($binname) > MAX_USER_STRING_LEN) {
	    my $max = MAX_USER_STRING_LEN;
	    $self->error ("SP_COVERGROUP \"$binname\" string too long (max $max chars)\n");
	}

	my $bin = $self->current_bin();
	$bin->name($binname);
	$self->attributes("in_illegal",0);
	$self->attributes("in_ignore",0);
    } elsif ($type eq "default") {
	print "Netlist::File: coverpoint parsed default\n" if $SystemC::Netlist::Debug;
	my $bin = $self->current_bin();
	$self->defaultName($bin->name);
	$bin->isIllegal(1) if ($self->attributes("in_illegal"));
	$bin->isIgnore(1)  if ($self->attributes("in_ignore"));

    } elsif ($type eq "single") {
	print "Netlist::File: coverpoint parsed single\n" if $SystemC::Netlist::Debug;
    } elsif ($type eq "multi_begin") {
	print "Netlist::File: coverpoint parsed multi_begin\n" if $SystemC::Netlist::Debug;
	my $bin = $self->current_bin();
	$self->attributes("in_multi_bin",1);
	$self->attributes("multi_bin_count",0);
	$self->attributes("multi_bin_basename",$bin->name);
    } elsif ($type eq "multi_begin_num") {
	my $num_ranges = shift;
	print "Netlist::File: coverpoint parsed multi_begin_num\n" if $SystemC::Netlist::Debug;
	my $bin = $self->current_bin();
	$self->attributes("in_multi_bin",1);
	$self->attributes("multi_bin_num_ranges",$num_ranges); # we use this in multi_bin_end
	$self->attributes("multi_bin_count",0);
	$self->attributes("multi_bin_basename",$bin->name);
    } elsif ($type eq "multi_end") {
	print "Netlist::File: coverpoint parsed multi_end\n" if $SystemC::Netlist::Debug;
	$self->attributes("in_multi_bin",0);
    } elsif ($type eq "multi_auto_end") {
	print "Netlist::File: coverpoint parsed multi_auto_end\n" if $SystemC::Netlist::Debug;
	$self->attributes("in_multi_bin",0);

	# there's a single bin with a range; we want to
	# convert it into a bunch of individual bins of size 1
	my $bin = pop @{$self->bins};

	my $range = pop @{$bin->ranges};
	$range =~ /(\S+),(\S+)/;

	my $hi_str = $1;
	my $lo_str = $2;
	my $lo = $self->validate_value($lo_str,$fileref);
	my $hi = $self->validate_value($hi_str,$fileref);

	if ($self->attributes("multi_bin_num_ranges")) {
	    $self->make_standard_bins($self->attributes("multi_bin_num_ranges")
				      ,$lo,$hi,$self->attributes("multi_bin_basename"));
	} else {
	    $self->make_standard_bins(($hi - $lo + 1),$lo,$hi,$self->attributes("multi_bin_basename"));
	}
	$self->attributes("multi_bin_num_ranges",0);
    } elsif ($type eq "standard") {
	print "Netlist::File: coverpoint parsed standard\n" if $SystemC::Netlist::Debug;
	# only the default bin
	$self->num_bins(1);
    } elsif ($type eq "standard_bins_range") {
	my $binsize_str = shift;
	my $lo_str = shift;
	my $hi_str = shift;
	print "Netlist::File: coverpoint parsed standard_bins_range, size = $binsize_str, lo = $lo_str, hi = $hi_str\n" if $SystemC::Netlist::Debug;
	my $binsize = $self->validate_value($binsize_str,$fileref);
	my $lo = $self->validate_value($lo_str,$fileref);
	my $hi = $self->validate_value($hi_str,$fileref);

	$self->make_standard_bins($binsize,$lo,$hi,$self->name);
    } elsif ($type eq "standard_bins") {
	my $binsize_str = shift;
	print "Netlist::File: coverpoint parsed standard_bins, size = $binsize_str\n" if $SystemC::Netlist::Debug;
	my $binsize = $self->validate_value($binsize_str,$fileref);
	# FIXME default 1024 is a hack
	# we should look up the size from the sp_ui etc.
	$self->make_standard_bins($binsize,0,1023,$self->name);
    } elsif ($type eq "bins") {
	print "Netlist::File: coverpoint parsed explicit bins\n" if $SystemC::Netlist::Debug;
	$self->num_bins(scalar(@{$self->bins})+1); # +1 for default
    } elsif ($type eq "enum") {
	my $enum = shift;
	print "Netlist::File: coverpoint parsed enum bins, enum = $enum\n" if $SystemC::Netlist::Debug;
	$self->enum($enum);
	# we don't actually make the bins for enums until output time.
    } elsif ($type eq "page") {
	my $page = shift;
	print "Netlist::File: coverpoint parsed page = $page\n" if $SystemC::Netlist::Debug;
	if (length($page) > MAX_USER_STRING_LEN) {
	    my $max = MAX_USER_STRING_LEN;
	    $self->error ("SP_COVERGROUP \"$page\" string too long (max $max chars)\n");
	}
	$self->page($page);
    } elsif ($type eq "description") {
	my $desc = shift;
	print "Netlist::File: coverpoint parsed description = $desc\n" if $SystemC::Netlist::Debug;
	if (length($desc) > MAX_USER_STRING_LEN) {
	    my $max = MAX_USER_STRING_LEN;
	    $self->error ("SP_COVERGROUP \"$desc\" string too long (max $max chars)\n");
	}
	$self->description($desc);
    } elsif ($type eq "option") {
	my $var = shift;
	my $val = shift;

	if (length($var) > MAX_USER_STRING_LEN) {
	    my $max = MAX_USER_STRING_LEN;
	    $self->error ("SP_COVERGROUP \"$var\" string too long (max $max chars)\n");
	}

	if ($var eq "radix") {
	    if (($val == 16) ||
		($val == 10) ||
		($val == 2)) {
		$self->radix($val);
	    } else {
		$self->error("Unrecognized radix option \"$val\"; I know about 2/10/16\n");
	    }
	} else {
	    $self->error("Unrecognized coverpoint option \"$var = $val\"\n");
	}
    } else {
	$self->error("Netlist::File: coverpoint parsed an unexpected type: $type\n");
    }
}

sub validate_value {
    my $self = shift;
    my $str = shift;
    my $fileref = shift;

    if ($str =~ /^0x[0-9a-fA-F]+$/) { # hex number
	#print "recognized hex $str as ". (hex $str)."\n";
	return hex $str;
    } elsif ($str =~ /^\d+$/) { # decimal number
	#print "recognized dec $str\n";
	return $str;
    } elsif ($str =~ /^(\w+)::(\w+)$/) { # enum
	my $enumclass = $1;
	my $enumname = $2;

	# do we recognize the enum name?
	my $netlist = $fileref->netlist();
	my $vals = $netlist->{_enums}{$enumclass};
	if (!defined $vals) {
	    $self->error("parsed what looks like an enum but is an unrecognized enum class: ${enumclass}\n");
	    return 0;
	}
	my $val = $vals->{"en"}{$enumname};
	if (!defined $val) {
	    $self->error("parsed a recognized enum type but an unrecognized value: ${enumclass}::${enumname}\n");
	    return 0;
	}
	return $val;
    } else {
	$self->error("parsed coverpoint bin value not a decimal or hex number: $str");
	return 0;
    }
}


sub make_standard_bins {
    my $self = shift;
    my $num_bins = shift;
    my $lo_range = shift;
    my $hi_range = shift;
    my $name = shift;

    my $span = $hi_range - $lo_range + 1;

    if ($span < $num_bins) {
	$self->error("more bins specified ($num_bins) than values in range ($lo_range:$hi_range)\n");
    }

    my $radix_char = "d";
    $radix_char = "x" if ($self->radix == 16);
    $radix_char = "d" if ($self->radix == 10);
    $radix_char = "b" if ($self->radix == 2);
    # add just the right number of leading zeros
    my $s = sprintf("%".$radix_char,$num_bins-1+$lo_range);
    my $digits = length $s;
    my $s2 = sprintf("%".$radix_char,$num_bins-1);
    my $name_digits = length $s2;

    # make bins
    for(my $i=0;$i<$num_bins;$i++) {
	my $bin = $self->current_bin();
	my $lo = int(($span / $num_bins) * $i) + $lo_range;
	my $hi = (int(($span / $num_bins) * ($i+1)) - 1) + $lo_range;

	push @{$bin->ranges}, sprintf("%u,%u",$hi,$lo); # force unsigned

	if ($span == $num_bins) {
	    # no names required!
	    $bin->name(sprintf("%0".$digits.$radix_char,$i+$lo_range));
	} else {
	    $bin->name(sprintf("%s_%0".$name_digits.$radix_char,$name,$i));
	}

	push @{$self->bins}, $bin;
	# undef it so that the next bin will be fresh
	$self->attributes("_openBin",undef);
    }
    $self->num_bins(scalar(@{$self->bins})+1); # +1 for default
}

sub make_auto_enum_bins {
    my $self = shift;
    my $fileref = shift;
    my $enum = $self->enum;

    my $netlist = $fileref->netlist();
    if (!defined $netlist) {
	$self->error("Internal error: no netlist!\n");
    }

    # do we recognize the enum name?
    my $vals = $netlist->{_enums}{$enum};
    if (!defined $vals) {
	$self->error("Netlist::File: coverpoint parsed 'auto_enum_bins' with an unrecognized enum class: $enum\n");
	return;
    }

    my $enumtype = "en";
    if (!defined $vals->{$enumtype}) {
	$self->error("Netlist::File: coverpoint parsed 'auto_enum_bins' and couldn't find either an auto-enum or a ${enum}::en\n");
	return;
    }

    foreach my $valsym (sort {$vals->{$enumtype}{$a} <=> $vals->{$enumtype}{$b}}
			(keys %{$vals->{$enumtype}})) {
	my $val = $vals->{$enumtype}{$valsym};

	my $bin = $self->current_bin();
	push @{$bin->values}, sprintf("%u",$val); # force unsigned
	if ($val < $self->minValue) { $self->minValue($val);}
	if ($val > $self->maxValue) { $self->maxValue($val);}

	$bin->name($valsym);

	# add this bin to the point
	push @{$self->bins}, $bin;
	# undef it so that the next bin will be fresh
	$self->attributes("_openBin",undef);
    }

    $self->num_bins(scalar(@{$self->bins})+1); # +1 for default
}

#################################
# Write SystemC

sub _write_coverpoint_decl {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    my $covergroupref = shift;

    # only now (when all the autoenums have been parsed) do we make the enum bins
    if (defined $self->enum) {
	$self->make_auto_enum_bins($fileref);
    }

    if ($self->isCross) {
	# write the cross stuff
	my @dimensions;
	push @dimensions, @{$self->rows};
	push @dimensions, @{$self->cols};
	push @dimensions, @{$self->tables};

	# declare the coverpoint
	$fileref->printf ("%sSpZeroed<uint32_t>\t_sp_cg_%s_%s",
			  $prefix,
			  $covergroupref->name,
			  $self->name);
	foreach my $dimension (@dimensions) {
	    $fileref->printf ("[%d]",$dimension->num_bins);
	}
	$fileref->printf (";\t// SP_COVERGROUP declaration\n");

	###########################################################################
	# write the function returning the ignoredness
	###########################################################################
	$fileref->printf ("%sbool _sp_cg_%s_%s_ignored(",
			  $prefix,
			  $covergroupref->name,
			  $self->name);
	my @args;
	foreach my $dimension (@dimensions) {
	    my $dimname = $dimension->name;
	    push @args, "uint64_t $dimname";
	}
	my $argsWithCommas = join(', ',@args);
	$fileref->printf ("%s) { \t// SP_COVERGROUP declaration\n",$argsWithCommas);

	$fileref->printf ("%s  return (0 // if any dimension is ignored\n",$prefix);
	foreach my $dimension (@dimensions) {
	    $fileref->printf ("%s         || _sp_cg_%s_%s_ignored(%s)\n",
			      $prefix,
			      $covergroupref->name,
			      $dimension->name,
			      $dimension->name);
	}
	if ($self->ignoreFunc) {
	    my @args2;
	    foreach my $dimension (@dimensions) {
		my $dimname = $dimension->name;
		my $str = "_sp_cg_".$covergroupref->name."_".$dimension->name."_getArbitraryValue(${dimname})";
		push @args2, $str;
	    }
	    my $args2WithCommas = join(', ',@args2);
	    $fileref->printf ("%s         || %s(%s) // or if my func says it should be ignored\n",
			      $prefix,$self->ignoreFunc,$args2WithCommas);
	}
	$fileref->printf ("%s         );\n",$prefix);
	$fileref->printf ("%s}\n",$prefix);

	###########################################################################
	# write the function returning the illegality
	###########################################################################
	$fileref->printf ("%sbool _sp_cg_%s_%s_illegal(",
			  $prefix,
			  $covergroupref->name,
			  $self->name);
	my @args3;
	foreach my $dimension (@dimensions) {
	    my $dimname = $dimension->name;
	    push @args3, "uint64_t $dimname";
	}
	$argsWithCommas = join(', ',@args3);
	$fileref->printf ("%s) { \t// SP_COVERGROUP declaration\n",$argsWithCommas);

	$fileref->printf ("%s  return (0 // if any dimension is illegal\n",$prefix);
	foreach my $dimension (@dimensions) {
	    $fileref->printf ("%s         || _sp_cg_%s_%s_illegal(%s)\n",
			      $prefix,
			      $covergroupref->name,
			      $dimension->name,
			      $dimension->name);
	}
	if ($self->illegalFunc) {
	    my @args2;
	    foreach my $dimension (@dimensions) {
		my $dimname = $dimension->name;
		my $str = "_sp_cg_".$covergroupref->name."_".$dimension->name."_getArbitraryValue(${dimname})";
		push @args2, $str;
	    }
	    my $args2WithCommas = join(', ',@args2);
	    $fileref->printf ("%s         || %s(%s) // or if my func says it should be illegal\n",
			      $prefix,$self->illegalFunc,$args2WithCommas);
	}
	$fileref->printf ("%s          );\n",$prefix);
	$fileref->printf ("%s}\n",$prefix);

    } else { # not a cross
	if (!$self->crossMember) {
	    # declare the coverpoint (only if not a crossMember)
	    $fileref->printf ("%sSpZeroed<uint32_t>\t_sp_cg_%s_%s[%d];\t// SP_COVERGROUP declaration\n",
			      $prefix,
			      $covergroupref->name,
			      $self->name,
			      $self->num_bins);
	}

	###########################################################################
	# write the function returning an arbitrary value per bin
	###########################################################################
	$fileref->printf ("%suint64_t _sp_cg_%s_%s_getArbitraryValue(uint64_t bin) { \t// SP_COVERGROUP declaration\n",
			  $prefix,
			  $covergroupref->name,
			  $self->name);

	my $bin_num = 0;
	foreach my $bin (@{$self->bins}) {
	    if (scalar @{$bin->values}) {
		my @vals = @{$bin->values};
		my $arbitrary_val = $vals[0];

		# if it's not an enum, then add ULL to allow 64-bit numbers
		$arbitrary_val .= "ULL" unless ($arbitrary_val =~ /^(\w+)::(\w+)$/);

		$fileref->printf ("%s  if (bin == %s) return %s; // an arbitrary value in bin %s\n",
				  $prefix,$bin_num,$arbitrary_val,$bin->name);
	    } elsif (scalar @{$bin->ranges}) {
		my @ranges = @{$bin->ranges};
		$ranges[0] =~ /(\S+),(\S+)/;
		my $hi_str = $1;

		# if it's not an enum, then add ULL to allow 64-bit numbers
		$hi_str .= "ULL" unless ($hi_str =~ /^(\w+)::(\w+)$/);

		$fileref->printf ("%s  if (bin == %s) return %s; // an arbitrary value in bin %s\n",
				  $prefix,$bin_num,$hi_str,$bin->name);
	    } else {
		my $binname = $bin->name;
		$self->error("CoverPoint internal error: bin $binname has no values or ranges!\n");
	    }
	    $bin_num++;
	}
	if ($self->defaultName eq "") {
	    $fileref->printf ("%s  if (bin == %s) return 0; // the unnamed default bin - the return value doesn't matter\n",
			      $prefix,$bin_num);
	} else {
	    $fileref->printf ("%s  if (bin == %s) return 0; // the default bin (%s) - the return value doesn't matter\n",
			      $prefix,$bin_num,$self->defaultName);
	}
 	$fileref->printf ("%s  SP_ERROR_LN(\"%s\",%d,\"Internal error: Illegal bin value for point %s\");\n",
			  $prefix,$fileref->name,$covergroupref->module->lineno,$self->name);
 	$fileref->printf ("%s  return 0;\n", $prefix);
	$fileref->printf ("%s}\n", $prefix);

	###########################################################################
	# write the function returning the ignoredness
	###########################################################################
	$fileref->printf ("%sbool _sp_cg_%s_%s_ignored(uint64_t bin) { \t// SP_COVERGROUP declaration\n",
			  $prefix,
			  $covergroupref->name,
			  $self->name);
	$fileref->printf ("%s  static int _s_bin_to_ignore[] = {",$prefix);
	my @lookupTable = (0) x ($self->num_bins);

	$bin_num = 0;
	foreach my $bin (@{$self->bins}) {
	    $lookupTable[$bin_num] = $bin->isIgnore;
	    $bin_num+=1;
	}
	# now printf the table
	for (my $i = 0; $i < $self->num_bins; $i++) {
	    $fileref->printf ("%d,",$lookupTable[$i]);
	}
	$fileref->printf ("};\n");
	if ($self->ignoreFunc) {
	    $fileref->printf ("%s  if (%s(_sp_cg_%s_%s_getArbitraryValue(bin))) { return true; }\n",
			      $prefix,$self->ignoreFunc,
			      $covergroupref->name,
			      $self->name);
	}

 	$fileref->printf ("%s  if (bin >= %d) { SP_ERROR_LN(\"%s\",%d,\"Internal error: Illegal bin value in %s_ignore\"); return true; }\n",
 			  $prefix,$self->num_bins,
 			  $fileref->name,$covergroupref->module->lineno,$self->name);
	$fileref->printf ("%s  return (_s_bin_to_ignore[bin]);\n%s}\n",
			  $prefix,$prefix);

	###########################################################################
	# write the function returning the illegality
	###########################################################################
	$fileref->printf ("%sbool _sp_cg_%s_%s_illegal(uint64_t bin) { \t// SP_COVERGROUP declaration\n",
			  $prefix,
			  $covergroupref->name,
			  $self->name);
	$fileref->printf ("%s  static int _s_bin_to_illegal[] = {",$prefix);

	@lookupTable = (0) x ($self->num_bins);

	$bin_num = 0;
	foreach my $bin (@{$self->bins}) {
	    $lookupTable[$bin_num] = $bin->isIllegal;
	    $bin_num+=1;
	}
	# now printf the table
	for (my $i = 0; $i < $self->num_bins; $i++) {
	    $fileref->printf ("%d,",$lookupTable[$i]);
	}
	$fileref->printf ("};\n");
	if ($self->illegalFunc) {
	    $fileref->printf ("%s  if (%s(_sp_cg_%s_%s_getArbitraryValue(bin))) { return true; }\n",
			      $prefix,$self->illegalFunc,
			      $covergroupref->name,
			      $self->name);
	}
 	$fileref->printf ("%s  if (bin >= %d) { SP_ERROR_LN(\"%s\",%d,\"Internal error: Illegal bin value in %s_illegal\"); return true; }\n",
 			  $prefix,$self->num_bins,
 			  $fileref->name,$covergroupref->module->lineno,$self->name);
	$fileref->printf ("%s  return (_s_bin_to_illegal[bin]);\n%s}\n",
			  $prefix,$prefix);

	###########################################################################
	# write the function returning the bin name
	###########################################################################
	$fileref->printf ("%sstatic const char* _sp_cg_%s_%s_binName(uint64_t point) { \t// SP_COVERGROUP declaration\n",
			  $prefix,
			  $covergroupref->name,
			  $self->name);
	$fileref->printf ("%s  static const char* _s_bin_to_name[] = {",$prefix);
	foreach my $bin (@{$self->bins}) {
	    $fileref->printf ("\"%s\",",$bin->name);
	}
	$fileref->printf ("\"%s\"",$self->defaultName);
	$fileref->printf ("};\n");
	$fileref->printf ("%s  return (_s_bin_to_name[point]);\n%s}\n",$prefix,$prefix);

	foreach my $bin (@{$self->bins}) {
	    my @values = @{$bin->values};
	    foreach my $value_str (@values) {
		my $val = $self->validate_value($value_str,$fileref);
		if ($val < $self->minValue) { $self->minValue($val);}
		if ($val > $self->maxValue) { $self->maxValue($val);}
	    }

	    my @ranges = @{$bin->ranges};
	    foreach my $range (@ranges) {
		$range =~ /(\S+),(\S+)/;
		my $hi_str = $1;
		my $lo_str = $2;
		my $lo = $self->validate_value($lo_str,$fileref);
		my $hi = $self->validate_value($hi_str,$fileref);

		if ($lo < $self->minValue) { $self->minValue($lo);}
		if ($hi < $self->minValue) { $self->minValue($hi);}
		if ($lo > $self->maxValue) { $self->maxValue($lo);}
		if ($hi > $self->maxValue) { $self->maxValue($hi);}
	    }
	}

	###########################################################################
	# write the function computing which bin to increment
	###########################################################################
	if (($self->minValue < 0) || ($self->maxValue > MAX_BIN_LOOKUP_SIZE)) {

	    $fileref->printf ("%sint _sp_cg_%s_%s_computeBin(uint64_t point) { \t// SP_COVERGROUP declaration\n",
			      $prefix,
			      $covergroupref->name,
			      $self->name);
	    $bin_num = 0;
	    foreach my $bin (@{$self->bins}) {
		$fileref->printf ("%s  if (0\n",$prefix);

		my @values = @{$bin->values};
		foreach my $value_str (@values) {

		    # if it's not an enum, then add ULL to allow 64-bit numbers
		    $value_str .= "ULL" unless ($value_str =~ /^(\w+)::(\w+)$/);

		    $fileref->printf ("%s     || (point == %s)\n",$prefix,$value_str);
		}
		my @ranges = @{$bin->ranges};
		foreach my $range (@ranges) {
		    $range =~ /(\S+),(\S+)/;
		    my $hi_str = $1;
		    my $lo_str = $2;
		    my $lo = $self->validate_value($lo_str,$fileref);
		    my $hi = $self->validate_value($hi_str,$fileref);

		    # if it's not an enum, then add ULL to allow 64-bit numbers
		    $lo .= "ULL" unless ($lo =~ /^(\w+)::(\w+)$/);
		    $hi .= "ULL" unless ($hi =~ /^(\w+)::(\w+)$/);

		    $fileref->printf ("%s     || ((point >= %s) && (point <= %s))\n", $prefix,$lo, $hi);
		}

		if ($bin->isIllegal) {
		    $fileref->printf ("%s     ) { SP_ERROR_LN(\"%s\",%d,\"Illegal bin %s hit\"); return 0; } // %s\n", $prefix,$fileref->name,$covergroupref->module->lineno,$bin->name,$bin->name);
		} else {
		    $fileref->printf ("%s     ) return %d; // %s\n", $prefix,$bin_num,$bin->name);
		}
		$bin_num+=1;
	    }
	    # else the default bucket
	    $fileref->printf ("%s  return %d; // default\n%s}\n",$prefix,$bin_num,$prefix);
	} else { # all values in range, use a lookup table
	    # FIXME illegals
	    $fileref->printf ("%sstatic int _sp_cg_%s_%s_computeBin(uint64_t point) { \t// SP_COVERGROUP declaration\n",
			      $prefix,
			      $covergroupref->name,
			      $self->name);
	    $fileref->printf ("%s  static int _s_value_to_bin[] = {",$prefix);
	    # start with all default, which is bin number $self->num_bins - 1
	    # 0 thru $self->maxValue inclusive
	    my @lookupTable = ($self->num_bins-1) x ($self->maxValue+1);

	    # now populate the lookup table
	    my $bin_num = 0;
	    foreach my $bin (@{$self->bins}) {
		my @values = @{$bin->values};
		foreach my $value_str (@values) {
		    my $value = $self->validate_value($value_str,$fileref);
		    $lookupTable[$value] = $bin_num;
		}
		my @ranges = @{$bin->ranges};
		foreach my $range (@ranges) {
		    $range =~ /(\S+),(\S+)/;
		    my $hi_str = $1;
		    my $lo_str = $2;
		    my $lo = $self->validate_value($lo_str,$fileref);
		    my $hi = $self->validate_value($hi_str,$fileref);
		    for (my $i = $lo; $i <= $hi; $i++) {
			$lookupTable[$i] = $bin_num;
		    }
		}
		$bin_num+=1;
	    }
	    # now printf the table
	    for (my $i = 0; $i <= $self->maxValue; $i++) {
		$fileref->printf ("%d,",$lookupTable[$i]);
	    }
	    $fileref->printf ("};\n");
	    $fileref->printf ("%s  if ((point > %d) | (point < %d)) return %d; // default\n",
			      $prefix,
			      $self->maxValue,
			      $self->minValue,
			      $self->num_bins-1);
	    $fileref->printf ("%s  return (_s_value_to_bin[point]);\n%s}\n",
			      $prefix,$prefix);
	}
    }
}

sub _write_coverpoint_ctor {
    my $self = shift;
    my $fileref = shift;
    my $prefix = shift;
    my $modref = shift;
    my $covergroupref = shift;

    # if self->page is undefined, use group page
    my $page = $self->page || $covergroupref->page;
    $page =~ s/"//g;
    $page = "{no-page}" if $page eq '';
    $page = "sp_group/${page}/".$self->name;

    # if neither exists, use empty quotes
    my $description = $self->description || "\"\"";

    if ($self->isCross) {
	# write the cross stuff
	my @dimensions;
	push @dimensions, @{$self->rows};
	push @dimensions, @{$self->cols};
	push @dimensions, @{$self->tables};

	my $indent = "";
	foreach my $dimension (@dimensions) {
	    $indent .= "  "; # indent two more spaces

	    my $num_bins = $dimension->num_bins;
	    if ($dimension->defaultName eq "") {
		# don't make a bin for default unless it was specifically called for
		$num_bins--;
	    }

	    $fileref->printf("%sfor(int _sp_cg_%s=0;_sp_cg_%s<%d;_sp_cg_%s++) {\n",
			     $indent,$dimension->name,$dimension->name,
			     $num_bins,$dimension->name);
	}
	$indent .= "  ";
	# don't insert illegals and ignores
	my @ignoreVars;
	foreach my $dimension (@dimensions) {
	    my $dimname = $dimension->name;
	    push @ignoreVars, "_sp_cg_${dimname}";
	}
	$fileref->printf("%sif (!_sp_cg_%s_%s_ignored(%s) && !_sp_cg_%s_%s_illegal(%s)) {\n",
			 $indent,
			 $covergroupref->name,
			 $self->name,
			 join(', ',@ignoreVars),
			 $covergroupref->name,
			 $self->name,
			 join(', ',@ignoreVars));
	$fileref->printf('%s  SP_COVER_INSERT(&_sp_cg_%s_%s',
			 $indent,
			 $covergroupref->name,
			 $self->name);
	foreach my $dimension (@dimensions) {
	    $fileref->printf ("[_sp_cg_%s]",$dimension->name);
	}
	$fileref->printf(',"filename","%s"', $self->filename);
	$fileref->printf(',"lineno","%s"', $self->lineno);
	$fileref->printf(',"groupname","%s"', $covergroupref->name);
	$fileref->printf(',"per_instance","%s"', $covergroupref->per_instance);
	$fileref->printf(',"groupcmt",%s', $description); # quotes already present
	$fileref->printf(',"pointname","%s"', $self->name);
	$fileref->printf(',"hier",name()');
	# fields so the auto-table-generation code will recognize it
	$fileref->printf(',"page","%s"', $page);

	# FIXME old-style
	$fileref->printf(',"table", "%s"', $self->name);

	my $rownum = 0;
	foreach my $row (@{$self->rows}) {
	    $fileref->printf(',"row%d_name","%s"',
			     $rownum,
			     $row->name);
	    $fileref->printf(',"row%d",_sp_cg_%s_%s_binName(_sp_cg_%s)',
			     $rownum,
			     $covergroupref->name,
			     $row->name,
			     $row->name);
	    $rownum++;
	}
	my $colnum = 0;
	foreach my $col (@{$self->cols}) {
	    $fileref->printf(',"col%d_name","%s"',
			     $colnum,
			     $col->name);
	    $fileref->printf(',"col%d",_sp_cg_%s_%s_binName(_sp_cg_%s)',
			     $colnum,
			     $covergroupref->name,
			     $col->name,
			     $col->name);
	    $colnum++;
	}
	# unused so far
	my $tablenum = 0;
	foreach my $table (@{$self->tables}) {
	    $fileref->printf(',"table%d_name","%s"',
			     $tablenum,
			     $table->name);
	    $fileref->printf(',"table%d",_sp_cg_%s_%s_binName(_sp_cg_%s)',
			     $tablenum,
			     $covergroupref->name,
			     $table->name,
			     $table->name);
	    $tablenum++;
	}
	$fileref->printf(");");
	$fileref->printf("\n");
	$fileref->printf("%s}\n",$indent);
	foreach my $dimension (@dimensions) {
	    $fileref->printf("}\n");
	}
    } elsif (!$self->crossMember) {
	my $num_bins = $self->num_bins;
	if ($self->defaultName eq "") {
	    # don't make a bin for default unless it was specifically called for
	    $num_bins--;
	}
	$fileref->printf("{ for(int i=0;i<%d;i++) {\n",$num_bins);
	$fileref->printf("    if (!_sp_cg_%s_%s_ignored(i) && !_sp_cg_%s_%s_illegal(i)) {\n",
			 $covergroupref->name, $self->name,
			 $covergroupref->name, $self->name);
	$fileref->printf('      ');
	$fileref->printf('SP_COVER_INSERT(&_sp_cg_%s_%s[i]',
			 $covergroupref->name,
			 $self->name);
	$fileref->printf(',"filename","%s"', $self->filename);
	$fileref->printf(',"lineno","%s"', $self->lineno);
	$fileref->printf(',"groupname","%s"', $covergroupref->name);
	$fileref->printf(',"per_instance","%s"', $covergroupref->per_instance);
	$fileref->printf(',"groupcmt",%s', $description); # quotes already present
	$fileref->printf(',"pointname","%s"', $self->name);
	$fileref->printf(',"hier",name()');
	# fields so the auto-table-generation code will recognize it
	$fileref->printf(',"page","%s"', $page);
	$fileref->printf(',"table", "%s"', $self->name);
	$fileref->printf(',"row0",_sp_cg_%s_%s_binName(i)',
			 $covergroupref->name,
			 $self->name);
	$fileref->printf(',"row0_name","%s"',
			 $self->name);
	$fileref->printf(");");
	$fileref->printf("\n");
	$fileref->printf("} } }\n");
    } else {
	# else this is a 1-d which is a member of a cross; don't insert any points
    }
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::CoverPoint - Coverage point routines

=head1 DESCRIPTION

SystemC::Netlist::CoverPoint implements coverpoints associated with
the SP_COVERGROUP features. It is called from SystemC::Netlist::Module.

=head1 DISTRIBUTION

SystemPerl is part of the L<http://www.veripool.org/> free SystemC software
tool suite.  The latest version is available from CPAN and from
L<http://www.veripool.org/systemperl>.

Copyright 2001-2009 by Wilson Snyder.  This package is free software; you
can redistribute it and/or modify it under the terms of either the GNU
Lesser General Public License or the Perl Artistic License.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>,
Bobby Woods-Corwin <me@alum.mit.edu>

=head1 SEE ALSO

L<SystemC::Netlist::Module>
L<SystemC::Netlist::CoverGroup>
