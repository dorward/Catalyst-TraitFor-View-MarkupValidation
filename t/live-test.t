#!/usr/bin/env perl

BEGIN {
    use Test::MockObject;
    use WebService::Validator::HTML::W3C::Error;
    my $import;
    my $mock = Test::MockObject->new();
    $mock->fake_module(
        'WebService::Validator::HTML::W3C',
        new => sub {
            my $ref   = shift;
            my $class = ref $ref || $ref;
            my $obj   = {};
            bless $obj, $class;
            return $obj;
        },
        validate => sub {
            my $self = shift;
            my %args = @_;
            $self->{document} = $args{string};
        },
        is_valid => sub {
            my $self = shift;
            if ($self->{document} =~ m/invalid/ixs) {
                return 0;
            }
            return 1;
        },
        errors => sub {
            my $err = WebService::Validator::HTML::W3C::Error->new({
                          line => 1,
                          col  => 1,
                          msg  => "Mock validation error",
                      });
            return [ $err ];
            }
    );
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
$mech->{catalyst_debug} = 1;

$mech->get_ok( 'http://localhost/main', 'Get main page (valid document)' );
$mech->content_like( qr/Test Document/is, 'Check this is (probably) the right page' );
$mech->get_ok( 'http://localhost/invalid', 'Get invalid page' );
$mech->content_like( qr/Invalid/is, 'Check this is (probably) the right page' );
$mech->content_like( qr/Mock validation error/is, 'Got validity report' );

done_testing;
