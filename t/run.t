#!/usr/bin/env perl -T

use lib 't/tests';
use Test::Task;
#use Test::Scheduler;
#use Test::Dialer;

Test::Class->runtests;
