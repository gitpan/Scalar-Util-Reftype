#!/usr/bin/env perl -w
use strict;
use Test::More qw( no_plan );
use Scalar::Util::Reftype;

is( reftype( []    )->array , 1, 'Testing ARRAY' );
is( reftype( {}    )->hash  , 1, 'Testing HASH'  );
is( reftype( \$0   )->scalar, 1, 'Testing SCALAR');
is( reftype( sub{} )->code  , 1, 'Testing CODE'  );
is( reftype( []    )->hash  , 0, 'Testing hash   on ARRAY' );
is( reftype( {}    )->array , 0, 'Testing array  on HASH'  );
is( reftype( \$0   )->code  , 0, 'Testing code   on SCALAR');
is( reftype( sub{} )->scalar, 0, 'Testing scalar on CODE'  );

my $scalar;
my $sref = \$scalar;

my $scalaro = bless $sref   , 'Foo';
my $arrayo  = bless []      , 'Foo';
my $hasho   = bless {}      , 'Foo';
my $codeo   = bless sub {}  , 'Foo';
my $globo   = bless \*STDOUT, 'Foo';
my $refo    = bless \$sref  , 'Foo';
#my $ioo     = bless , 'Foo'; #IO
#my $regexpo = bless , 'Foo'; # Regexp

is( reftype( $scalaro )->scalar_object, 1, 'Object is a  SCALAR object' );
is( reftype( $arrayo  )->array_object,  1, 'Object is an ARRAY  object' );
is( reftype( $hasho   )->hash_object,   1, 'Object is a  HASH   object' );
is( reftype( $codeo   )->code_object,   1, 'Object is a  CODE   object' );
is( reftype( $globo   )->glob_object,   1, 'Object is a  GLOB   object' );
is( reftype( $refo    )->ref_object,    1, 'Object is a  REF    object' );
#is( reftype( $ioo     )->hash_object,   1, 'Object is a IO object'     );
#is( reftype( $regexpo )->hash_object,   1, 'Object is a REGEXP object' );

is( reftype( $scalaro )->container, 'Foo', 'Object is an instance of Foo (container)' );
is( reftype( $scalaro )->class    , 'Foo', 'Object is an instance of Foo (class)' );
is( reftype( \$0      )->container,    '', 'Non-blessed returns empty string');

is( reftype(''   )->array, 0, 'Test non-ref (empty string)' );
is( reftype(undef)->array, 0, 'Test non-ref (undef)' );
is( reftype(0    )->array, 0, 'Test non-ref (zero)' );

is( reftype('foobar')->array, 0, 'Test non-ref' );
