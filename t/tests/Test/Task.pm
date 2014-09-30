package Test::Task;

use Test::Most;
use Informer::Dialer;
use Informer::Reporter;
use Informer::Schema;
use Informer::Scheduler;
use DateTime;
use Data::Dumper;
use base qw(Test::Class);

sub class { 'Informer::Schema::Result::Task' }

sub startup : Tests(startup => 2) {
    my $test  = shift;
    my $class = $test->class;

    eval "use $class";
    die $@ if $@;

    my $schema = Informer::Schema->connect(
        'dbi:mysql:informer',
        'informer',
        'informer',
        { RaiseError => 1, mysql_enable_utf8 => 1 }
    ) or die "Can't connect database";

    $test->{schema} = $schema;
    (my $r      = ref $test) =~ s/^Test:://; 
    my $rs      = $schema->resultset($r);
    
    can_ok $rs, 'new';
    can_ok $rs, 'create';
    
    $test->{scheduler} = Informer::Scheduler->new({
        limit => 7,
        start => { days => 0, hours => 0 },
        table => [
            { days => 1, hours => { from =>  9, to => 13 }, minutes => { from => 0, to => 58 } },
            { days => 1, hours => { from => 17, to => 22 }, minutes => { from => 0, to => 58 } },
            { days => 1, hours => { from => 13, to => 17 }, minutes => { from => 0, to => 58 } },
        ],
    });
    
    $test->{dialer} = Informer::Dialer->new(
        channel   => 'Local/dialing',
        timeout   => 60,
        spool_dir => File::Temp::tempdir(CLEANUP => 1),
        context   => 'informing'
    );

    $test->{reporter} = Informer::Reporter->new(url => 'http://127.0.0.1:5555');

}

sub setup : Tests(setup) {
    my $test      = shift;
    my $schema  = $test->{schema};
    (my $r      = ref $test) =~ s/^Test:://; 
    my $rs      = $schema->resultset($r);

    $test->{new_task} = $rs->create({
        id            => 100,
        rec_number    => '1/7543/14',
        phone_number  => '8123097960',
        scheduler     => $test->{scheduler},
    }); 
    $test->{now} = DateTime->now(time_zone => 'local');
    $test->{task1} = $rs->create({
        id            => 101,
        rec_number    => '1/7543/14',
        phone_number  => '8123097960',
        scheduler     => $test->{scheduler},
    });
};

sub teardown : Tests(teardown) {
    my $test  = shift;
    my $new_task  = $test->{new_task};

    $new_task->delete;
    $test->{task1}->delete;
}

sub constructor : Test(4) {
    my $test    = shift;
    my $new_task    = $test->{new_task};  
    my $class   = $test->class;
    
    isa_ok $new_task, $class, "...and task class is $class";
    cmp_ok $new_task->phone_number, 'eq', '8123097960', "...and it has phone_number";
    cmp_ok $new_task->rec_number, 'eq', '1/7543/14', "...and it has rec_number";
    cmp_ok $new_task->id, '>=', 1, "...and it has unique id";
}

sub calls : Tests(2) {
    my $test  = shift;
    my $new_task  = $test->{new_task};

    can_ok $new_task, 'calls';
    cmp_ok $new_task->calls, '==', 0;
}

sub status : Tests(3) {
    my $test  = shift;
    my $new_task  = $test->{new_task};

    can_ok $new_task, 'status';
    cmp_ok $new_task->status_id, '==', 0, '...and status of a new task is 0';
    cmp_ok $new_task->status->value, 'eq', 'NEW', '...and status value of a new task is NEW';
}

sub last_call : Tests(2) {
    my $test  = shift;
    my $new_task  = $test->{new_task};

    can_ok $new_task, 'last_call';
    is $new_task->last_call, undef, '...and last call of new task is undefined';
}
sub completed : Tests(2) {
    my $test      = shift;
    my $new_task  = $test->{new_task};
    can_ok $new_task, 'completed';
    ok !$new_task->completed, '...and new task is not completed';
}

sub next_call_time : Tests(3) {
    my $test      = shift;
    my $new_task  = $test->{new_task};

    can_ok $new_task, 'next_call_time';
    isa_ok $new_task->next_call_time, 'DateTime';

    my $delta = $new_task->next_call_time - $test->{now};

    cmp_ok abs($delta->in_units('seconds')), '<=', 1,
        '...and new task must be called immediately';
}

sub ready_to_call : Tests(2) {
    my $test      = shift;
    my $new_task  = $test->{new_task};
    
    can_ok $new_task, 'ready_to_call';
    ok $new_task->ready_to_call,
        '...and new task is ready to call';
}

sub call_info : Tests(3) {
    my $test  = shift;
    my $task  = $test->{new_task};

    can_ok $task, 'call_info';
    isa_ok $task->call_info, 'HASH';
    my $cf = $task->call_info;
    my $pattern = "-" . $task->id . '-' . ($task->calls + 1);

    
    ok {
        $cf->{phone_number} eq $task->phone_number
        &&  $cf->{rec_id} == $task->id
        &&  $cf->{rec_number} eq $task->rec_number
        &&  $cf->{sessionid} =~ /^\d+-$pattern/
    };
}

sub place_next_call : Tests(6) {
    my $test      = shift;
    my $task      = $test->{new_task};
    my $dialer    = $test->{dialer};

    can_ok $task, 'place_next_call';
    $task->place_next_call($dialer);
    ok !$task->ready_to_call, 
        '...and task with call in progress is not ready to place next call';
    cmp_ok $task->calls, '==', 1, 
        '...and there is call';
    ok $task->incall, 
        '...and task is in call state';
    cmp_ok $task->last_call->status->value, 'eq', 'INCALL',
        '..and call status is INCALL';
    throws_ok { $task->place_next_call($dialer) }
        qr/^Impossible to call/,
        '...and no more calls can be placed';
} 

sub complete_last_call : Tests {
    my $test      = shift;
    my $task      = $test->{new_task};
    my $scheduler = $test->{scheduler};
    my $dialer    = $test->{dialer};
    
    can_ok $task, 'complete_last_call';

    my @statuses = $task->result_source
                        ->schema
                        ->resultset('Status')
                        ->search(
                            {
                                final => 0,
                                value => { '!=' => 'NEW'},
                            }
                        );
    foreach my $c ( 1 .. $scheduler->limit - 1) {
        ok $task->place_next_call($dialer);
        my $status = $statuses[$c % scalar(@statuses)];
        ok $task->complete_last_call($status->value);
        cmp_ok $task->status->value, 'eq', $status->value,
            "...and task status is equal " .  $status->value;
        cmp_ok $task->last_call->status->value, 'eq', $status->value,
            '...and same last call status';
        $task->reset_time;
    }
    $task->place_next_call($dialer);
    ok $task->complete_last_call('BUSY');
    cmp_ok $task->status->value, 'eq', 'MAXCALL',
        '...and task status is MAXCALL';
}

sub cancel : Tests(7) {
    my $test  = shift;
    my $task  = $test->{new_task};
    my $dialer = $test->{dialer};
    can_ok $task, 'cancel';

    ok $task->cancel;
    cmp_ok $task->status->value, 'eq', 'CANCELED',
        '...and task status is CANCELED';
    throws_ok { $task->place_next_call($dialer) }
        qr/^Impossible to call/,
        "...and canceled task can't place calls";

    my $task1 = $test->{task1};
    $task1->place_next_call($dialer);
    ok $task1->cancel;
    cmp_ok $task1->status->value, 'eq', 'INCALL';
    $task1->complete_last_call('NOANSWER');
    cmp_ok $task1->status->value, 'eq', 'CANCELED';
}

1;
