package Test::Dialer;

use Test::Most;
use base qw(Test::Class);
use File::Temp qw( tempdir );
use File::Spec;
use Data::Dumper;
use autodie;


sub class { 'Informer::Dialer' }

sub startup : Tests(startup => 3) {
    my $test  = shift;
    my $class = $test->class;

    eval "use $class";
    die $@ if $@;

    can_ok $class, 'new';
    ok my $dialer = $class->new(
        channel => 'Local/dialing',
        context => 'test'
    ),
        '...and constructor must succeed';
    isa_ok $dialer, 'Informer::Dialer';
}

sub setup : Tests(setup) {
    my $test            = shift;
    my $class           = $test->class;
    my $dir             = tempdir(CLEANUP => 1);
    $test->{spool}      = $dir;
    $test->{dialer}     = $class->new(
        channel   => 'Local/dialing',
        timeout   => 60,
        spool_dir => $dir,
        context   => 'informing'
    );
}    

sub originate : Tests {
    my $test    = shift;
    my $dialer  = $test->{dialer};
    my $dir     = $test->{spool};
    
    my $info = {
        phone_number  => '9219226874',
        sessionid     => 'ABCDE-FGHIJ-12345',
        taskid        => 25,
        information   => 'silence/1&header&1&2&3&dash&4&5&footer1',
    };

    can_ok $dialer, 'originate';
    
    ok my $cid = $dialer->originate($info), 
        '..and originate must succeed';

    ok -e (my $call_file =  File::Spec->catfile($dir, $cid)), 
        '...and call file exists';
    # Test contents of created file    
    my $cf = do {
        local $/;
        open my $fh, '<', $call_file;
        <$fh>;
    };
    my $contents = <<'END_CF';
Channel: Local/9219226874@dialing
Context: informing
Extension: s
Priority: 1
Set: INFORMATION=silence/1&header&1&2&3&dash&4&5&footer1
Set: SESSIONID=ABCDE-FGHIJ-12345
Set: TASKID=25
END_CF

    cmp_ok $cf, 'eq', $contents, '...and call file has right contents';

    delete $info->{phone_number};
    throws_ok { $dialer->originate($info) }
        qr/^Phone number missing/,
        '...and originate throws exception if no phone_number is set';
}

1;


