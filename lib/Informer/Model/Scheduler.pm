package Informer::Model::Scheduler;
use strict;
use base qw/Catalyst::Model::Adaptor/;

__PACKAGE__->config(
    class => 'Informer::Scheduler',
);

1;
