use strict 'vars';
use Asterisk::AGI;
$| = 1;

my $agi = Asterisk::AGI->new;
my %agienv = $agi->ReadParse;

my ($req_number, $year) = $ARGV[0] =~ /^(.*\/)(\d{2})/;

my $info = join '&', map { ($_ eq '/') ? 'dash' : $_} (split('', $req_number), $year);

$agi->set_variable('INFORMATION', 'silence/1&header&' . $info . '&footer');

exit 0;


