#!/usr/bin/perl
use strict 'vars';
use autodie;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Config::General;
use Const::Fast;
use Informer::Schema;
use Informer::Dialer;

const my $CONF		=> 'informer.conf';
const my $RUN_LIMIT	=> 60;
const my $CHANNELS	=> 10;

my $conf = Config::General->new("$FindBin::Bin/../$CONF");
my %cfg = $conf->getall;

sub ast_get_calls {
    my $group = shift || qr{^\w+\/};
    open AST, 'asterisk -rx "core show channels" |';
    my @channels = <AST>;
    my $active = grep { /$group/ } @channels;
    return $active;
}

my $schema = Informer::Schema->connect($cfg{'Model'}->{'InformerDB'}->{'connect_info'});
my $dialer = Informer::Dialer->new($cfg{Dialer});

my $start = time;

while (1) {
    my $active = ast_get_calls('SIP');
    my $free   = $CHANNELS - $active;
    my @tasks = $schema->resultset('Task')->ready_to_call;
    
    if (@tasks) {
        foreach my $task (@tasks) {
            last unless $free-- > 0;
            print "Dial outgoing for: " . $task->id;
	    eval {$task->place_next_call($dialer)};
	    sleep 1;
	    my $now = time;
            last if $now - $start >= $RUN_LIMIT;
        }
    }
    sleep 5;
    
    my $now = time;
    last if $now - $start >= $RUN_LIMIT;
}
