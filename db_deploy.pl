#!/usr/bin/perl
use strict 'vars';
use utf8;
use Informer::Schema;

my $schema = Informer::Schema->connect(
    'dbi:mysql:informer',
    'root',
    'KulWe2da',
    { RaiseError => 1, mysql_enable_utf8 => 1 }
) or die "Can't connect database";

$schema->deploy( { add_drop_table => 1 } );

$schema->resultset('Status')->populate([
        [qw(id value description final)],
        [ 0,        'NEW',            'Task is not processed yet', 0 ],
        [ 1,   'NOANSWER',                         'Not answered', 0 ],
        [ 2,    'WRONGPN',                 'Phone number invalid', 1 ],
        [ 3,    'MAXCALL', 'Call attempts limit has been reached', 1 ],
        [ 4,       'BUSY',                            'Line busy', 0 ],
        [ 5,         'SC',                              'Success', 1 ],
        [ 6,         'NE',               'Talk time is too short', 0 ],
        [ 7, 'CONGESTION',                     'Call setup error', 0 ],
        [ 8,   'CANCELED',                    'Task was canceled', 1 ],
        [ 9,     'INCALL',                     'Call in progress', 0 ],
    ]);

