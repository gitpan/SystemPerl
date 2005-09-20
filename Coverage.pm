# $Id: Coverage.pm 6461 2005-09-20 18:28:58Z wsnyder $
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
@EXPORT = qw( inc );

use strict;
use SystemC::Coverage::Item;
use vars qw($VERSION $Debug);

use vars qw($_Default_Self);

######################################################################
#### Configuration Section

$VERSION = '1.230';

use constant DEFAULT_FILENAME => 'logs/coverage.pl';

######################################################################
######################################################################
######################################################################
#### Creation

sub new {
    my $class = shift;
    my $self = {
	filename => DEFAULT_FILENAME,
	strings => {},  # value/key = id#
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
    # Use a temp file, so it's less likely a abort in the middle of writing will trash data.

    $params{filename} or croak "%Error: Undefined filename,";
    my $tempfilename = $params{filename}.".tmp";
    unlink $tempfilename;
    my $fh = IO::File->new($tempfilename,"w") or croak "%Error: $! $tempfilename,";

    print $fh "# -*- Mode:perl -*-\n";
    print $fh "package SystemC::Coverage;\n";
    foreach my $key (sort keys %{$self->{coverage}}) {
	my $item = SystemC::Coverage::Item->new($key, $self->{coverage}{$key});
	printf $fh $item->write_string."\n";
    }

    printf $fh "\n1;\n";	# So eval will succeed
    $fh->close();

    rename $tempfilename, $params{filename};
}

######################################################################
#### Incrementing utilities

sub inc {
    my $self = (ref $_[0] ? shift : $_Default_Self);
    my ($string,$count) = SystemC::Coverage::Item::_dehash(@_);
    $self->{coverage}{$string} += $count;
}

######################################################################
#### Clearing

sub clear {
    my $self = shift;
    # Clear the coverage array
    $self->{strings} = {};
    $self->{coverage} = {};
    $self->{filedata} = {};
}

######################################################################
#### Accessors

sub items {
    my $self = shift;
    my @items;
    foreach my $key (keys %{$self->{coverage}}) {
	my $item = SystemC::Coverage::Item->new($key, $self->{coverage}{$key});
	push @items, $item;
    }
    return @items;
}

sub items_sorted {
    my $self = shift;
    return sort {$a->[0] cmp $b->[0]} $self->items;
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Coverage - Coverage analysis utilities

=head1 SYNOPSIS

  use SystemC::Coverage;

  $Coverage = new SystemC::Coverage;
  $Coverage->read (filename=>'cov1');
  $Coverage->read (filename=>'cov2');
  $Coverage->write (filename=>'cov_together');

=head1 DESCRIPTION

SystemC::Coverage provides utilities for reading and writing coverage data,
usually produced by the SP_COVER_INSERT or SP_AUTO_COVER function of the
SystemPerl package.

The coverage data is stored in a global hash called %Coverage, thus
subsequent reads will increment the same global structure.

=head1 METHODS

=over 4

=item clear

Clear the coverage variables

=item inc (args..., count=>value)

Increment the coverage statistics, entering keys for every value.  The last
value is the increment amount.  See SystemC::Coverage::Item for the list of
standard named parameters.

=item items

Return all coverage items, as a list of SystemC::Coverage::Item objects.

=item items_sorted

Return all coverage items in sorted order, as a list of
SystemC::Coverage::Item objects.

=item new  ([filename=>I<filename>])

Make a new empty coverage container.

=item read ([filename=>I<filename>])

Read the coverage data from the file, with error checking.

=item write ([filename=>I<filename>])

Write the coverage variables to the file in a form where they can be read
back by simply evaluating the file.

=back

=head1 SEE ALSO

vcoverage,
SystemC::Coverage::Item

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut

######################################################################
