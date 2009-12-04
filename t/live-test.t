#!/usr/bin/env perl


BEGIN {
    use Test::MockObject::Extends;
    use WebService::Validator::HTML::W3C;
    my $object = WebService::Validator::HTML::W3C->new();
    $object = Test::MockObject::Extends->new( $object );
    $object->set_true( 'parent_method' )
         ->set_always( -grandparent_method => 1 )
         ->clear();
    $object->mock( 'validate',
        sub { 'impurifying precious bodily fluids' } );
}

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');

done_testing;
