#!/usr/bin/perl -w

use Cwd;
use IO::File;
BEGIN { require "t/test_utils.pl"; }
use strict;
our $Debug;

if (!$ENV{SYSTEMC} || !-d $ENV{SYSTEMC}) {
    warn "%Error: The SYSTEMC environment variable needs to point to your SystemC distribution.\n";
    warn "%Error: and the SYSTEMC_KIT environment variable needs to point to your SystemC original kit.\n";
    die  "%Error: (SYSTEMC_KIT is not needed, if you run from the distribution dir).\n";
}
$ENV{SYSTEMC_KIT} ||= $ENV{SYSTEMC};  # Where the source tree is

if (!-r "$ENV{SYSTEMC_KIT}/src/systemc/datatypes/bit/sc_bv_base.h"
    && !-r "$ENV{SYSTEMC_KIT}/src/sysc/datatypes/bit/sc_bv_base.h") {
    die "%Error: Unknown version of SystemC,";
}

my $ver_2_1_v1    = 20050714;
my $ver_2_1_beta1 = 20041012;
my $ver_2_0_1     = 20040101;

if (sc_version() >= $ver_2_1_v1) {
    patch ("patch-2-1-v1", $ENV{SYSTEMC_KIT},
	   "$ENV{SYSTEMC_KIT}/src/sysc/datatypes/bit/sc_bv_base.h",
	   qr/For SystemPerl/);

    if (-d "$ENV{SYSTEMC}/include/sysc/datatypes") {	# May not exist if user hasn't installed systemc
	patch ("patch-2-1-v1-include", $ENV{SYSTEMC},
	       "$ENV{SYSTEMC}/include/sysc/datatypes/bit/sc_bv_base.h",
	       qr/For SystemPerl/);
    }
} else {
    patch ("patch-2-0-1", $ENV{SYSTEMC_KIT},
	   "$ENV{SYSTEMC_KIT}/src/systemc/datatypes/bit/sc_bv_base.h",
	   qr/For SystemPerl/);

    if (-d "$ENV{SYSTEMC}/include/systemc/datatypes") {	# May not exist if user hasn't installed systemc
	patch ("patch-2-0-1-include", $ENV{SYSTEMC},
	       "$ENV{SYSTEMC}/include/systemc/datatypes/bit/sc_bv_base.h",
	       qr/For SystemPerl/);
    }
}

if (sc_version() <= $ver_2_0_1
    && -r "/usr/include/c++/3.2.2/backward/strstream") {
    patch ("patch-2-0-1-gcc322", $ENV{SYSTEMC},
	   "/usr/include/c++/3.2.2/backward/strstream",
	   qr/SC_IOSTREAM_H/);
} else {
    print "Patch patch-2-0-1-gcc322 unneeded\n";
}

######################################################################

sub patch {
    my $pname = shift;
    my $root = shift;
    my $testfilename = shift;
    my $testre = shift;

    my $origfile = wholefile($testfilename);
    if ($origfile =~ /$testre/) {
	print "Patch $pname already applied\n";
	return; 
    }

    (-w $testfilename)
	or die "%Error: Can't create patch, you need to be running as root (to write files needing patches)\n";

    my $pfile = getcwd()."/${pname}.diff";
    my $patchedfile = "$ENV{SYSTEMC}/systemperl_patched_$pname";
    $patchedfile = "$ENV{SYSTEMC}/systemperl_patched" if $pname eq "patch-2-0-1";

    print "Patching using $pfile\n";
    run_system("cd $root && pwd");
    run_system("cd $root && patch -b -p0 <$pfile");

    IO::File->new($patchedfile,"w")->close();    # Touch, as SystemPerl looks for patch existence
}

sub wholefile {
    my $file = shift;
    my $fh = IO::File->new ($file) or die "%Error: $! $file";
    my $wholefile;
    {   local $/;
	undef $/;
	$wholefile = <$fh>;
    }
    $fh->close();
    return $wholefile;
}

our $Sc_Version;
sub sc_version {
    my $self = shift;
    # Return version of SystemC in use
    $ENV{SYSTEMC} or die "%Error: SYSTEMC env var not set,";
    if (!$Sc_Version) {
	my $fh;
	foreach my $fn ("$ENV{SYSTEMC_KIT}/src/sysc/kernel/sc_ver.h",	# 2.1.v1+
			"$ENV{SYSTEMC}/include/sysc/kernel/sc_ver.h",	# 2.1.v1+
			"$ENV{SYSTEMC_KIT}/src/systemc/kernel/sc_ver.h",# before 2.1.v1
			"$ENV{SYSTEMC}/include/systemc/kernel/sc_ver.h",# before 2.1.v1
			"$ENV{SYSTEMC}/include/sc_ver.h") {
	    $fh = IO::File->new($fn) if -r $fn;
	    last if $fh;
	}
	if ($fh) {
	    while (defined (my $line = $fh->getline)) {
		if ($line =~ /^\s*#\s*define\s+SYSTEMC_VERSION\s+(\S+)/) {
		    $Sc_Version = $1;
		    print "SC_VERSION = $1\n" if $Debug;
		    last;
		}
	    }
	}
    }
    defined $Sc_Version
	or die "%Error: Can't determine SystemC version";
    return $Sc_Version;
}

