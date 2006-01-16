# $Id: Item.pm 11992 2006-01-16 18:59:58Z wsnyder $
######################################################################
#
# Copyright 2001-2006 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# General Public License or the Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
######################################################################

package SystemC::Coverage::Item;
use Carp;

use strict;
use vars qw($VERSION $Debug $AUTOLOAD);

######################################################################
#### Configuration Section

$VERSION = '1.250';

our %Keys =
    (#     sorted by compressed----v
     "count"	 => { compressed=>"c", default=>'0'},
     "filename"	 => { compressed=>"f", default=>'undef',},
     "hier"	 => { compressed=>"h", default=>'""',},
     "lineno"	 => { compressed=>"l", default=>'0',},
     "column"	 => { compressed=>"n", default=>'0'},
     "comment"	 => { compressed=>"o", default=>'""',},
     "type"	 => { compressed=>"t", default=>'""',},
     "threash"	 => { compressed=>"s", default=>'undef',},
     );

our %DecompressKey;
while (my ($key, $val) = each %Keys) { $DecompressKey{$val->{compressed}}=$key; }
our %CompressKey;
while (my ($key, $val) = each %Keys) { $CompressKey{$key}=($val->{compressed}||$key); }

######################################################################
######################################################################
######################################################################
#### Creation

sub new {
    my $class = shift;
    my $self = [shift, shift];  # Key and count value
    return bless $self, $class;
}

sub DESTROY {}

sub _dehash {
    # Convert a hash to a pair of elements suitable for new()
    my @args = @_;

    my $count = 0;
    my %keys;
    for (my $i=0; $i<=$#args; $i+=2) {
	my $key = $args[$i];
	my $val = $args[$i+1];
	if ($key eq "c" || $key eq "count") {
	    $count = $val;
	    next;
	}
	# Compress keys
	$key = $CompressKey{$key} || $key;
	$keys{$key} = $val;
    }

    my $string = "";
    foreach my $key (sort (keys %keys)) {
	my $val = $keys{$key};
	$string .= "\001".$key."\002".$val;
	#print "Set $key $val\n" if $Debug;
    }
    #print "RR $string $count\n" if $Debug;
    return ($string, $count);
}

######################################################################
#### Special accessors

sub count {
    return $_[0]->[1];
}

sub key {
    # Sort key
    return $_[0]->[0];
}

sub hash {
    # Return hash of all keys and values
    my %hash;
    while ($_[0]->[0] =~ /\001([^\002]+)\002([^\001]+)/g) {
	my $key=$DecompressKey{$1}||$1;
	$hash{$key}=$2;
    }
    return \%hash;
}

######################################################################
#### Special methods

sub count_inc {
    $_[0]->[1] += $_[1];
}

sub write_string {
    my $self = shift;
    my $str = "inc(";
    my $comma = "";
    while ($self->[0] =~ /\001([^\002]+)\002([^\001]+)/g) {
	my $key = $1;
	my $val = $2;
	$key = "'".$key."'" if length($key)!=1;
	$str .= "${comma}${key}=>'$val'";
	$comma = ",";
    }
    $str .= $comma."c=>".$self->count;
    $str .= ");";
    return $str;
}

######################################################################
#### Normal accessors

# This makes functions that look like:
sub AUTOLOAD {
    my $func = $AUTOLOAD;
    if ($func =~ s/^SystemC::Coverage::Item:://) {
	my $key = $CompressKey{$func}||$func;
	my $def = $Keys{$func}{default}; $def = 'undef' if !defined $def;
	my $f = ("package SystemC::Coverage::Item;"
		 ."sub $func {"
		 ."  if (\$_[0]->[0] =~ /\\001${key}\\002([^\\001]+)/) {"
		 ."    return \$1;"
		 ."  } else {"
		 ."    return ".$def.";"
		 ."  }"
		 ."}; 1;");
	#print "DEF $func $f\n";
	eval $f or die;
	goto &$AUTOLOAD;
    } else {
	croak "Undefined SystemC::Coverage::Item subroutine $func called,";
    }
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Coverage::Item - Coverage analysis item

=head1 SYNOPSIS

  use SystemC::Coverage;

  $Coverage = new SystemC::Coverage;
  foreach my $item ($Coverage->items()) {
      print $item->count;
  }

=head1 DESCRIPTION

SystemC::Coverage::Item provides data on a single coverage point.

=head1 METHODS

=over 4

=item count_inc (inc)

Increment the item's count by the specified value.

=item hash

Return a reference to a hash of key/value pairs.

=item key

Return a key suitable for sorting.

=back

=head1 ACCESSORS

=over 4

=item column

Column number for the item.

=item comment

Textual description for the item.

=item count

Return the count for this point.

=item filename

Filename of the item.

=item hier

Hierarchy path name for the item.

=item lineno

Line number for the item.

=item type

Type of coverage (block, line, fsm, etc.)

=back

=head1 SEE ALSO

C<SystemC::Coverage>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut

######################################################################
