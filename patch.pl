#!/usr/bin/perl -w

use Cwd;
use IO::File;
BEGIN { require "t/test_utils.pl"; }
use strict;

if (!$ENV{SYSTEMC} || !-d $ENV{SYSTEMC}) {
    warn "%Error: The SYSTEMC environment variable needs to point to your SystemC distribution.\n";
    die  "%Error: and the SYSTEMC_KIT environment variable needs to point to your SystemC original kit.\n";
}
$ENV{SYSTEMC_KIT} ||= $ENV{SYSTEMC};  # Where the source tree is

if (!-r "$ENV{SYSTEMC_KIT}/src/systemc/datatypes/bit/sc_bv_base.h") {
    die "%Error: Unknown version of SystemC,";
}

patch ("patch-2-0-1", $ENV{SYSTEMC_KIT},
       "$ENV{SYSTEMC_KIT}/src/systemc/datatypes/bit/sc_bv_base.h",
       qr/For SystemPerl/);

if (-d "$ENV{SYSTEMC}/include") {	# May not exist if user hasn't installed systemc
    patch ("patch-2-0-1-include", $ENV{SYSTEMC},
	   "$ENV{SYSTEMC}/include/systemc/datatypes/bit/sc_bv_base.h",
	   qr/For SystemPerl/);
}

if (-r "/usr/include/c++/3.2.2/backward/strstream") {
    patch ("patch-2-0-1-gcc322", $ENV{SYSTEMC},
	   "/usr/include/c++/3.2.2/backward/strstream",
	   qr/SC_IOSTREAM_H/);
} else {
    print "Patch patch-2-0-1-gcc322 unneeded\n";
}

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

    IO::File->new($patchedfile,"w")->close();    # Touch, as SystemPerl looks for patch existance
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
