#!/usr/local/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use lib '.';
use lib '..';
use IO::File;
use SystemC::Parser;

print "ok 1\n";
mkdir 'test_dir', 0777;

######################################################################
package Trialparser;
@ISA = qw(SystemC::Parser);

sub _common {
    my $comment = shift;
    my $self = shift;
    print $::fdump "Parser.pm::$comment: ",$self->filename,":",$self->lineno
	,": '",join("','", @_),"'\n";
}

sub text {
    my $self = shift;
    #print $::fdump ("Parser.pm::TEXT: ",$self->filename,":",$self->lineno,
    #	   ": '",join("','", @_),"'\n");
    $self->writetext($_[0]);
}

sub auto {	_common ('AUTO',@_); }
sub module {	_common ('MODULE',@_); }
sub ctor {	_common ('CTOR',@_); }
sub cell {	_common ('CELL',@_); }
sub pin {	_common ('PIN',@_); }
sub signal {	_common ('SIGNAL',@_); }
sub preproc_sp {_common ('PREPROC_SP',@_); }
sub enum_value {_common ('ENUM_VALUE',@_); }

sub writetext {
    my $self = shift;
    my $text = shift;
    my $fn = $self->filename;
    my $ln = $self->lineno();
    if ($self->{lastline} != $ln) {
	if ($self->{lastfile} ne $fn) {
	    print $::fh "#line $ln \"$fn\"\n";
	} else {
	    print $::fh "#line $ln\n";
	}
	$self->{lastfile} = $fn;
	$self->{lastline} = $ln;
    }
    print $::fh $text;
    while ($text =~ /\n/g) {
	$self->{lastline}++;
    }
}

package main;
######################################################################

{
    # We'll write out all text, to make sure nothing gets dropped
    $fh = IO::File->new (">test_dir/test.out");
    $fdump = IO::File->new (">test_dir/test.parse");
    my $sp = Trialparser->new();
    $sp->{lastfile} = "test.sp";
    $sp->{lastline} = 1;
    $sp->read (filename=>"test.sp");
    $fh->close();
    $fdump->close();
}
print "ok 2\n";

{
    # Ok, let's make sure the right data went through
    my $f1 = wholefile ("test.sp") or die;
    my $f2 = wholefile ("test_dir/test.out") or die;
    my @l1 = split ("\n", $f1);
    my @l2 = split ("\n", $f2);
    for (my $l=0; $l<($#l1 | $#l2); $l++) {
	($l1[$l] eq $l2[$l]) or die "not ok 3: Line $l mismatches\n$l1[$l]\n$l2[$l]\n";
    }
}
print "ok 3\n";

sub wholefile {
    my $file = shift;
    my $fh = IO::File->new ($file) or die "%Error: $! $file";
    my $wholefile;
    {   local $/;
	undef $/;
	$wholefile = <$fh>;
    }
    $fh->close();

    $wholefile =~ s/[ \t]*#sp[^\n]*\n//mg;
    $wholefile =~ s/[ \t]*#line[^\n]*\n//mg;
    $wholefile =~ s![ \t]*// Beginning of SystemPerl[^*]*// End of SystemPerl[^\n]+\n!!mg;

    return $wholefile;
}
