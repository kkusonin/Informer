use strict 'vars';
use utf8;
use Config::General;
use Data::Dumper;

my $cfg = Config::General->new('informer.conf');

my %config = $cfg->getall;

my $dcfg = $config{Dialer};

foreach (keys %$dcfg) {
    print $_, ' => ', $dcfg->{$_},"\n";
}

