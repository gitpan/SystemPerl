#!/usr/local/bin/perl -w

use Cwd;
use IO::File;
BEGIN { require "t/test_utils.pl"; }
use strict;

if (!$ENV{SYSTEMC} || !-d $ENV{SYSTEMC}) {
    die "%Error: The SYSTEMC environment variable needs to point to your SystemC distribution.\n";
}
$ENV{SYSTEMC_KIT} ||= $ENV{SYSTEMC};  # Where the source tree is

if (!-r "$ENV{SYSTEMC_KIT}/src/systemc/datatypes/bit/sc_bv_base.h") {
    die "%Error: Unknown version of SystemC,";
}

patch ("patch-2-0-1", $ENV{SYSTEMC_KIT});
if (-d "$ENV{SYSTEMC}/include") {	# May not exist if user hasn't installed systemc
    patch ("patch-2-0-1-include");
}

if (-r "/usr/include/c++/3.2.2/backward/strstream") {
    (-w "/usr/include/c++/3.2.2/backward/strstream")
	or die "%Error: Can't create patch, you need to be running as root\n";
    patch ("patch-2-0-1-gcc322");
} else {
    print "Patch patch-2-0-1-gcc322 unneeded\n";
}

sub patch {
    my $pname = shift;
    my $root = $ENV{SYSTEMC};

    my $pfile = getcwd()."/${pname}.diff";
    my $patchedfile = "$ENV{SYSTEMC}/systemperl_patched_$pname";
    $patchedfile = "$ENV{SYSTEMC}/systemperl_patched" if $pname eq "patch-2-0-1";

    if (-r $patchedfile) {
	print "Patch $pname already applied\n";
	return; 
    }

    print "Patching using $pfile\n";
    run_system("cd $root && pwd");
    run_system("cd $root && patch -b -p0 <$pfile");

    IO::File->new($patchedfile,"w")->close();    # Touch
}
