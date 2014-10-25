# SystemC - SystemC Perl Interface
# $Id: Subclass.pm,v 1.4 2001/04/03 21:26:02 wsnyder Exp $
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

package SystemC::Netlist::Subclass;
use Class::Struct;
require Exporter;
use strict;

use vars qw($Warnings $Errors %_Error_Unlink_Files @ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(structs);
$Warnings = $Errors = 0;

# Maybe in the future
#struct ('SystemC::Netlist::Subclass'
#	 =>[name     	=> '$', #'	# Name of the element
#	    filename 	=> '$', #'	# Filename this came from
#	    lineno	=> '$', #'	# Linenumber this came from
#	    ]);

######################################################################
#### Member functions

######################################################################
#### Error Handling
# Class::Struct is great, but it can't have a @ISA... Sigh.
# Thus you can't just call a $netlist_object->warn ("message...");

sub warn {
    my $self = shift;
    $self = shift if ref $_[0];	# Optional reference to object
    CORE::warn "%Warning: ".($self->filename||"").":".($self->lineno||"").": ".join('',@_);
    $Warnings++;
}

sub error {
    my $self = shift;
    $self = shift if ref $_[0];	# Optional reference to object
    CORE::warn "%Error: ".($self->filename||"").":".($self->lineno||"").": ".join('',@_);
    $Errors++;
}

sub exit_if_error {
    exit(10) if ($Errors || $Warnings);
}

sub unlink_if_error {
    $_Error_Unlink_Files{$_[0]} = 1;
}

END {
    $? = 10 if ($Errors || $Warnings);
    if ($?) {
	CORE::warn "Exiting due to errors\n";
	foreach my $file (keys %_Error_Unlink_Files) { unlink $file; }
    }
}

######################################################################
######################################################################
######################################################################
# DANGER WILL ROBINSON!
# Prior to perl 5.6, Class::Struct's new didn't bless the arguments,
# or allow parameter initialization!  We'll override it!

sub structs {
    Class::Struct::struct (@_);
    if ($] < 5.6) {
	# Now override what class::struct created
	my $baseclass = $_[0];
	(my $overclass = $baseclass) =~ s/::Struct$//;
	eval "
            package $overclass;
            sub new {
		my \$class = shift;
		my \$self = new $baseclass;
		bless \$self, \$class;
		while (\@_) {
		    my \$param = shift; my \$value = shift;
		    eval (\"\\\$self->\$param(\\\$value);\");  # Slow, sorry.
		}
		return \$self;
	    }";
    }
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Netlist::Subclass - Common routines for all classes

=head1 SYNOPSIS

  use SystemC::Netlist::Subclass;
  package SystemC::Netlist::Something;
  @ISA = qw(SystemC::Netlist::Subclass);

  ...

  $self->warn();

=head1 DESCRIPTION

SystemC::Netlist::Subclass is used as a base class for all structures.
It is mainly used so that $self->warn() and $self->error() will produce
consistent results.

=head1 MEMBER FUNCTIONS

=over 4

=item $self->warn (I<Text...>)

Print a warning in a standard format.  

=item $self->error (I<Text...>)

Print an error in a standard format.  

=item $self->exit_if_error()

Exits the program if any errors were detected.

=item $self->unlink_if_error (I<filename>)

Requests the given file be deleted if any errors are detected.  Used for
temporary files.

=back

=head1 SEE ALSO

L<SystemC::Netlist>

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
