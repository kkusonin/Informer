package Test::Scheduler;

use Test::Most;
use base qw(Test::Class);
use DateTime;

sub class { 'Informer::Scheduler' }

sub startup : Tests(startup => 1) {
    my $test  = shift;
    my $class = $test->class;

    eval "use $class";
    die $@ if $@;

    bail_on_fail;
    can_ok $class, 'new';
    restore_fail;
}

sub setup : Tests(setup) {
    my $test  = shift;
    my $class = $test->class;

    $test->{scheduler} = $class->new({
        limit => 7,
        start => { days => 0, hours => 0 },
        table => [
            { days => 1, hours => { from =>  9, to => 13 }, minutes => { from => 0, to => 58 } },
            { days => 1, hours => { from => 17, to => 22 }, minutes => { from => 0, to => 58 } },
            { days => 1, hours => { from => 13, to => 17 }, minutes => { from => 0, to => 58 } },
        ],
    });

}

sub limit : Tests(2) {
    my $test      = shift;
    my $scheduler = $test->{scheduler};

    can_ok $scheduler, 'limit';
    cmp_ok $scheduler->limit, '==', 7, "...and limit is equal constructor's arg";
}

sub schedule : Tests {
    my $test      = shift;
    my $scheduler = $test->{scheduler};

    can_ok $scheduler, 'schedule';
    my $now = DateTime->now(time_zone => 'local');

    my $dt1 = $now->clone->truncate( to => 'day' )->add( days => 1, hours =>  9);
    my $dt2 = $now->clone->truncate( to => 'day' )->add( days => 1, hours => 13);
    my $dt3 = $now->clone->truncate( to => 'day' )->add( days => 1, hours => 17);
    my $dt4 = $now->clone->truncate( to => 'day' )->add( days => 1, hours => 22);

    isa_ok $scheduler->schedule(0), 'DateTime';
    cmp_ok $scheduler->schedule(0), '>=', $now;
    cmp_ok $scheduler->schedule(0), '==', DateTime->now(time_zone => 'local')->add( days => 0, hours => 0 );
    cmp_ok $scheduler->schedule(1), '>=', $dt1;
    cmp_ok $scheduler->schedule(1), '<=', $dt2;
    cmp_ok $scheduler->schedule(2), '>=', $dt3;
    cmp_ok $scheduler->schedule(2), '<=', $dt4;
    cmp_ok $scheduler->schedule(3), '>=', $dt2;
    cmp_ok $scheduler->schedule(3), '<=', $dt3;
    cmp_ok $scheduler->schedule(4), '>=', $dt1;
    cmp_ok $scheduler->schedule(4), '<=', $dt2;
    cmp_ok $scheduler->schedule(5), '>=', $dt3;
    cmp_ok $scheduler->schedule(5), '<=', $dt4;
    cmp_ok $scheduler->schedule(6), '>=', $dt2;
    cmp_ok $scheduler->schedule(6), '<=', $dt3;
    throws_ok { $scheduler->schedule(7) }
        qr/^Maximum attempts number has been reached/;
}






                
    




1;
