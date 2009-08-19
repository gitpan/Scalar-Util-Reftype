package Scalar::Util::Reftype;
use strict;
use vars qw( $VERSION @ISA $OID @EXPORT @EXPORT_OK );
use constant PRIMITIVES => qw(  Regexp IO SCALAR ARRAY HASH CODE GLOB REF );
use subs qw( container class reftype type blessed object );
use overload bool     => '_bool',
             fallback => 1,
            ;
use re           ();
use Scalar::Util ();
use Exporter     ();

$VERSION = '0.30';
@ISA       = qw( Exporter );
@EXPORT    = qw( reftype  );
@EXPORT_OK = qw( type     );

BEGIN {
    $OID = -1;
    foreach my $type ( PRIMITIVES ) {
        constant->import( 'TYPE_' . $type,             ++$OID );
        constant->import( 'TYPE_' . $type . '_OBJECT', ++$OID );
    }
}

use constant CONTAINER => ++$OID;
use constant BLESSED   => ++$OID;
use constant OVERRIDE  => ++$OID;
use constant MAXID     =>   $OID;

BEGIN {
    *class  = \*container;
    *type   = \*reftype;
    *object = \*blessed;
    no strict 'refs';
    my @types = grep  { s{ \A TYPE_ (.+?) \z }{$1}xms }
                keys %{ __PACKAGE__ . '::' };
    foreach my $meth ( @types ) {
        *{ lc $meth } = sub {
            my $self = shift;
            my $id   = 'TYPE_' . $meth;
            return $self->[ $self->$id ];
        }
    }

    # http://perlmonks.org/?node_id=665339
    if ( ! defined &re::is_regexp ) {
        require Data::Dump::Streamer;
        *re::is_regexp = sub($) {
            Data::Dump::Streamer::regex( $_[0] )
        }
    }
}

sub reftype { __PACKAGE__->new->analyze( @_ ) }

sub new {
    my $class = shift;
    my $self  = [ map { 0 } 0..MAXID ];
    $self->[CONTAINER] = '';
    bless  $self, $class;
    return $self;
}

sub analyze {
    my $self  = shift;
    my $thing = shift || return $self;
    my $ref   = CORE::ref($thing) || return $self;
    my($id, $type);

    foreach $type ( PRIMITIVES ) {
        $id = $ref eq $type                 ? sprintf( 'TYPE_%s',        $type )
            : $self->_object($thing, $type) ? sprintf( 'TYPE_%s_OBJECT', $type )
            :                                 undef
            ;
        if ( $id ) {
            $self->[ $self->$id() ] = 1 if ! $self->[OVERRIDE];
            # IO refs are always objects
            $self->[TYPE_IO]        = 1 if $id eq 'TYPE_IO_OBJECT';
            $self->[CONTAINER]      = $ref if $self->[BLESSED];
            last;
        }
    }
    return $self;
}

sub container { shift->[CONTAINER] }
sub blessed   { shift->[BLESSED]   }

sub _object {
    my($self, $object, $type)= @_;
    my $blessed = Scalar::Util::blessed($object) || return;
    my $rt      = Scalar::Util::reftype($object);
    $self->[BLESSED] = 1;
    if ( $rt eq 'IO' ) { # special case: IO
        $self->[TYPE_IO_OBJECT] = 1;
        $self->[TYPE_IO]        = 1;
        $self->[OVERRIDE]       = 1;
        return 1;
    }
    if ( re::is_regexp( $object ) ) { # special case: Regexp
        $self->[TYPE_Regexp_OBJECT] = 1;
        $self->[OVERRIDE]           = 1;
        return 1;
    }
    return if $rt ne $type; #  || ! ( $blessed eq 'IO' && $blessed eq $type );
    return 1;
}

sub _bool {
    require Carp;
    Carp::croak(
         "reftype() objects can not be used in boolean contexts. "
        ."Please call one of the test methods on the return value instead. "
        ."Example: `print 42 if reftype( \$thing )->array;`"
    );
}

1;

__END__

=pod

=head1 NAME

Scalar::Util::Reftype - Alternate reftype() interface

=head1 SYNOPSIS

    use Scalar::Util::Reftype;
    
    foo() if reftype( "string" )->hash;   # foo() will never be called
    bar() if reftype( \$var    )->scalar; # bar() will be called
    baz() if reftype( []       )->array;  # baz() will be called
    xyz() if reftype( sub {}   )->array;  # xyz() will never be called
    
    $obj  = bless {}, "Foo";
    my $rt = reftype( $obj );
    $rt->hash;        # false
    $rt->hash_object; # true
    $rt->class;       # "Foo"

=head1 DESCRIPTION

This document describes version C<0.30> of C<Scalar::Util::Reftype>
released on C<19 August 2009>.

This is an alternate interface to C<Scalar::Util>'s C<reftype> function.
Instead of manual type checking you can just call methods on the result
to see if matches the desired type.

=head1 FUNCTIONS

=head2 reftype EXPR

Exported by default.

Returns an object with which you can call various test methods. Unless
specified otherwise, all of the test methods return either zero (false)
or one (true) based on the C<EXPR> you have specified.

=head3 scalar

=head3 array

=head3 hash

=head3 code

=head3 glob

=head3 ref

=head3 io

=head3 regexp

=head3 scalar_object

=head3 array_object

=head3 hash_object

=head3 code_object

=head3 glob_object

=head3 ref_object

=head3 io_object

=head3 regexp_object

=head3 class

Returns the name of the class the object based on if C<EXPR> is an object.
Returns an empty string otherwise.

=head1 METHODS

The module uses an OO backend which you won't be needing. Please use the
C<reftype> function.

=head2 new

=head2 analyze EXPR

=head1 CAVEATS

perl versions 5.10 and newer includes the function C<re::is_regexp> to detect
if a reference is a regex or not. While it is possible to detect normal regexen
in older perls, there is no simple way to detect C<bless>ed regexen. Blessing
a regex hides it from normal probes. If you are under perl C<5.8.x> or older,
you'll need to install (in fact, it's in the prerequisities list so any
automated tool --like cpan shell-- will install it automatically)
C<Data::Dump::Streamer> which provides the C<regex> function similar to
C<re::is_regexp>.

=head1 SEE ALSO

L<Scalar::Util>, L<Data::Dump::Streamer>, L<re>,
L<http://perlmonks.org/?node_id=665339>.

=cut
