package Informer::Model::Reporter;
use strict;
use base qw/Catalyst::Model::Adaptor/;

__PACKAGE__->config(
    class => 'Informer::Reporter',
);

1;
