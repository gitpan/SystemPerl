# $Revision: 1.7 $$Date: 2005-03-02 11:34:26 -0500 (Wed, 02 Mar 2005) $$Author: wsnyder $
######################################################################
#
# Copyright 2001-2005 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
######################################################################

package SystemC::Coverage;
use IO::File;
use Carp;

require Exporter;
@ISA = ('Exporter');
@EXPORT = qw( covline );

use strict;
use vars qw($VERSION $Debug);

use vars qw($_Default_Self);

######################################################################
#### Configuration Section

$VERSION = '1.171';

use constant DEFAULT_FILENAME => 'logs/coverage.pl';

######################################################################
######################################################################
######################################################################
#### Creation

sub new {
    my $class = shift;
    my $self = {
	filename => DEFAULT_FILENAME,
	coverage => {},	# {coverage_key}=count
	filedata => {},	# {filename} = {counts => {line}=count, needed},
    };
    bless $self, $class;
    $_Default_Self = $self;
    $self->clear();
    return $self;
}

######################################################################
#### Reading

sub read {
    my $self = shift;
    my %params = ( filename => $self->{filename},
		   @_
		   );
    $_Default_Self = $self;
    # Read in the coverage file

    print "SystemC::Coverage::read $params{filename}\n" if $Debug;
    $params{filename} or croak "%Error: Undefined filename,";

    $! = $@ = undef;
    my $rtn = do $params{filename};
    (!$@) or die "%Error: $params{filename}: $@,";
    (!$!) or die "%Error: $params{filename}: $!,";
}

######################################################################
#### Saving

sub write {
    my $self = shift;
    my %params = ( filename => $self->{filename},
		   @_
		   );
    # Write out the coverage array

    $params{filename} or croak "%Error: Undefined filename,";
    my $fh = IO::File->new($params{filename},"w") or croak "%Error: $! $params{filename},";

    print $fh "# -*- Mode:perl -*-\n";
    print $fh "package SystemC::Coverage;\n";
    foreach my $key (sort keys %{$self->{coverage}}) {
	my $val = $self->{coverage}{$key};
	my @splitkey = map { _write_format_key($_); } (split /%/, $key);
	printf $fh "inc(%s, %7d);\n", join(",",@splitkey), $val;
    }

    printf $fh "\n1;\n";	# So eval will succeed
    $fh->close();
}

sub _write_format_key {
    #INTERNAL use
    my $pkey = $_[0];
    if ($pkey =~ /^-?[0-9]+$/) {
	return sprintf ("0x%08x", $pkey);
    } else {
	return "'$pkey'";
    }
}

######################################################################
#### Incrementing utilities

sub inc {
    my $self = (ref $_[0] ? shift : $_Default_Self);
    my $key = shift;
    my @left = @_;
    while (defined $left[1]) {
        $key .= '%'.shift @left;
    }
    $self->{coverage}{$key} += $left[0];
}

sub covline {
    my $self = (ref $_[0] ? shift : $_Default_Self);
    my ($what,$hier,$filename,$lineno,$cmt,$cnt) = @_;
    my $key = join('%',$what,$hier,$filename,$lineno,$cmt);
    # Increment per-line counts by specified value
    # Used only by first-time read of a SystemPerl written coverage file
    $self->{coverage}{$key} += $cnt;
}

######################################################################
#### Clearing

sub clear {
    my $self = shift;
    # Clear the coverage array
    $self->{coverage} = {};
    $self->{filedata} = {};
}

######################################################################
#### Line-number based utilities

sub split_line {
    return split /%/, $_[0];
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Coverage - Coverage analysys utilities

=head1 SYNOPSIS

  use SystemC::Coverage;

  $Coverage = new SystemC::Coverage;
  $Coverage->read (filename=>'cov1');
  $Coverage->read (filename=>'cov2');
  $Coverage->write (filename=>'cov_together');

=head1 DESCRIPTION

SystemC::Coverage provides utilities for reading and writing coverage data,
usually produced by the SP_AUTO_COVER function of the SystemPerl package.

The coverage data is stored in a global hash called %Coverage, thus
subsequent reads will increment the same global structure.

=head1 METHODS

=over 4

=item clear

Clear the coverage variables

=item inc (args..., value)

Increment the coverage statistics, entering keys for every value.  The last
value is the increment amount.

=item read (filename=>I<filename>)

Read the coverage data from the file, with error checking.

=item write (filename=>I<filename>)

Write the coverage variables to the file in a form where they can be read
back by simply evaluating the file.

=back

=head1 SEE ALSO

vcoverage

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut

######################################################################
