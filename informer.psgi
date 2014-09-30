use strict;
use warnings;

use Informer;

my $app = Informer->apply_default_middlewares(Informer->psgi_app);
$app;

