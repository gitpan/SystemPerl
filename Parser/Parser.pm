#$Id: Parser.pm,v 1.9 2001/03/31 20:23:37 wsnyder Exp $
######################################################################
#
# This program is Copyright 2001 by Wilson Snyder.
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
#                                                                           
######################################################################

package SystemC::Parser;
use Carp;

require DynaLoader;
@ISA = qw(DynaLoader);

use strict;

######################################################################
#### Configuration Section

bootstrap SystemC::Parser;

######################################################################
#### Accessors

sub new {
    my $class = shift;
    my $self = { strip_autos=>0,
		 @_};

    bless $self, $class;
    return $self;
}

sub read {
    my $self = shift;
    my %param = (@_);
    $self->_read_xs($param{filename}, $param{strip_autos}||$self->{strip_autos});
}

#In Parser.XS:
# sub read_xs {class}
# sub filename {class}
# sub lineno {class}

######################################################################
#### Called by the parser

sub auto {}
sub cell {}
sub ctor {}
sub enum_value {}
sub module {}
sub pin {}
sub preproc_sp {}
sub signal {}
sub text {}

sub error {
    my ($self,$text,$token)=@_;
    my $fileline = $self->filename.":".$self->lineno;
    croak ("%Error: $fileline: $text\n"
	   ."%Error: ".(" "x length($fileline)).": At token '$token'\nStopped");
}

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

SystemC::Parser - Parse SystemC Files

=head1 SYNOPSIS

    package Trialparser;
    @ISA = qw(SystemC::Parser);

    sub module {
	my $self = shift;
	my $module = shift;
	print $self->filename.":".$self->lineno().": ";
	print "Contains the module declaration for $module\n";
    }

    package main;
    my $sp = Trialparser->new();
    $sp->read ("test.sp");

=head1 DESCRIPTION

C<SystemC::Parser> reads SystemC files, and parses out the netlist
interconnectivity and other information.  As the tokens are recognized,
callbacks are invoked.  Note that the parser is designed to work on
UNPREPROCESSED files.

=head1 MEMBER FUNCTIONS

=over 4

=item $self->new()

Creates a new parser element.

=item $self->read(I<filename>)

Reads the filename and invokes necessary callbacks.

=back

=head1 ACCESSOR FUNCTIONS

=over 4

=item $self->filename()

Returns the filename of the most recently returned object.  May not match
the filename passed on the command line, as #line directives are honored.

=item $self->lineno()

Returns the line number at the beginning of the most recently returned
object.

=back

=head1 CALLBACKS

=over 4

=item $self->auto  (I<text>)

Auto is called with the text matching /*AUTOINST*/, etc.

=item $self->cell  (I<instance>, I<type>)

Cell is called when SP_CELL is recognized.  Parameters are the instance and
type of the cell.

=item $self->ctor  (I<modulename>)

Ctor is called when CP_CTOR is recognized.  Parameter is the modulename.

=item $self->enum_value  (I<enum_type>, I<enum_name>)

Enum value is called with the enum type and name for a enumeration
value.

=item $self->error (I<error_text>, I<token>)

Error is called when the parser hits a error.  Token is the last unparsed
token, which often gives a good indication of the error position.

=item $self->module  (I<modulename>)

Module is called when SC_MODULE is recognized.

=item $self->pin  (I<cell>, I<pin>, I<pin_bus>, I<signal>, I<signal_bus>)

Pin is called when SP_PIN is recognized.

=item $self->preproc_sp  (I<text>)

Preproc is called when a #sp line is recognized.

=item $self->signal  (I<type>, I<type_bus>,I<name>,I<name_bus>)

Signal is called on port declarations or sc_signal declarations.
The busses are any [] subscripts after the type names.

=item $self->text  (I<text>)

Text is called for all text not otherwise recognized.  Dumping all
text to a file will produce the original file, minus any #sp and
stipped // Auto inserted comments.

=back

=head1 SEE ALSO

C<SystemC::Netlist>

=head1 DISTRIBUTION

The latest version is available from CPAN and from C<http://veripool.com/>.

=head1 AUTHORS

Wilson Snyder <wsnyder@wsnyder.org>

=cut
