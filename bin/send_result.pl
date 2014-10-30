#!/usr/bin/perl
use strict 'vars';
use autodie;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Config::General;
use Const::Fast;
use Informer::Schema;
use Informer::Reporter;

const my $CONF		=> 'informer.conf';

my $conf = Config::General->new("$FindBin::Bin/../$CONF");
my %cfg = $conf->getall;

#use Data::Dumper;
#print Dumper($cfg{'Model'}->{'InformerDB'});
#exit 0;

my $schema = Informer::Schema->connect($cfg{'Model'}->{'InformerDB'}->{'connect_info'});
my $reporter = Informer::Reporter->new($cfg{'Model'}->{'Reporter'}->{'args'});


my @tasks = $schema->resultset('Task')->ready_to_report;
    
if (scalar @tasks) {
    my @results = map {$_->result} @tasks;

    $reporter->send(\@results);
    foreach (@tasks) {
        $_->update({reported => 1});
    }
}
