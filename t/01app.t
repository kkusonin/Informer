#!C:\Perl64\perl\bin\perl.exe
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Informer';

ok( request('/')->is_success, 'Request should succeed' );

done_testing();
