use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN {
    use_ok 'Catalyst::Test', 'Informer'
}

use HTTP::Request::Common;
use JSON;
use Config::General;

my ($request, $response);

my @data = (
    [ 100, '1234567/14', 9219226874, 5 ],
    [ 101, '1234567/14', 9219226874, 6 ],
    [ 102, '1234567/14', 9219226874, 7 ],
    [ 102, '1234568/14', 9219226874, 8 ],
);

my @tasks = map { { 
    ReqID           => $_->[0],
    ReqNumber       => $_->[1],
    Phone           => $_->[2],
    DurationInDays  => $_->[3],
}} @data;

my $msg = encode_json(\@tasks);

$request  = POST(
    'http://localhost/task/add',
    'Content-Type'     => 'application/json',
    'Content-Length'   => length $msg,
    'Content'          => $msg,
);

ok(
    $response = request($request),
    'Request for adding new tasks',
);
ok($response->is_success, 'Response successful 2xx');
is $response->content_type, 'application/json', 'Response Content is JSON';
like $response->content, qr/ADDED/, 'Some tasks were added';
like $response->content, qr/ERROR/, 'And some not';
