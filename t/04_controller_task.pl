use strict 'vars';
use utf8;
use Test::Most qw(no_plan);
use Informer::Schema;
use Informer::Dialer;
use Informer::Scheduler;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;

BEGIN {use_ok 'Informer::Controller::Task'; }

my $schema = Informer::Schema->connect(
    'dbi:mysql:informer',
    'informer',
    'recLS12qh!',
    { RaiseError => 1, mysql_enable_utf8 => 1 }
);

my $tasks = $schema->resultset('Task');

my $dialer = Informer::Dialer->new(
    channel   => 'Local/dialing',
    timeout   => 60,
    spool_dir => File::Temp::tempdir(CLEANUP => 1),
    context   => 'informing'
);

my $scheduler = Informer::Scheduler->new({
    limit => 7,
    start => { days => 0, hours => 0 },
    table => [
        { days => 1, hours => { from =>  9, to => 13 }, minutes => { from => 0, to => 58 } },
        { days => 1, hours => { from => 17, to => 22 }, minutes => { from => 0, to => 58 } },
        { days => 1, hours => { from => 13, to => 17 }, minutes => { from => 0, to => 58 } },
    ],
});


my $req = [
    {
        ReqID     => 100,
        ReqNumber => '1934567/24',
        Phone     => 9219226874,
    },
    {
        ReqID     => 101,
        ReqNumber => '1934568/24',
        Phone     => 9219226874,
    },
];

my $ua = LWP::UserAgent->new(
    timeout => 10
);

print "Sending request...\n";

my $response = $ua->request(
    POST  'http://127.0.0.1:3000/task/add',
    Content_Type  => 'application/json',
    Content       => encode_json $req,
);

ok $response->is_success, 'Add tasks request must succeed';
ok $response->decoded_content =~ /ADDED/, 
    '...and at least one task must be added';
ok $response->decoded_content !~ /ERROR/, 
    '...and no task with error';

my $task1 = $tasks->find(100);
my $task2 = $tasks->find(101);

ok $task1 && $task2,
    '..and tasks exist in database';

$response = $ua->request(
    POST 'http://127.0.0.1:3000/task/cancel',
    Content_Type    => 'application/json',
    Content         => encode_json [ { ReqID => 100 } ],
);

ok $response->is_success, 'Cancel tasks request must succeed';
ok $response->decoded_content =~ /CANCELED/,
    '...and task must be canceled';
diag($response->decoded_content);
$task1->discard_changes;
ok $task1->canceled,
    '...and task must be canceled in database';

$task2->place_next_call($dialer);

$response = $ua->request(
    POST 'http://127.0.0.1:3000/task/101?status=NOANSWER&cause=16'
);

ok $response->is_success, 'Update task request must succeed';

$task2->discard_changes;

ok $task2->status->value eq 'NOANSWER',
    '...and task status must be updated';
diag($task2->next_call_time);

### delete created tasks

$tasks->find(100)->delete;
$tasks->find(101)->delete;


