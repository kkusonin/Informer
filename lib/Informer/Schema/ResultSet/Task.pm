package Informer::Schema::ResultSet::Task;
use strict 'vars';
use warnings;
use base 'DBIx::Class::ResultSet';
use DateTime;

sub ready_to_call {
    my ($self, $rows) = @_;

    my $dtp = $self->result_source
                   ->schema
                   ->storage
                   ->datetime_parser;

    my $now = DateTime->now(time_zone => 'local');

    return $self->search(
        {
            'next_call_time' => { '<=' => $dtp->format_datetime($now) },
            'status.final'   => 0,
            'status.value'   => { '!=' => 'INCALL' }
        },
        {
            join      => 'status',
            rows      => $rows,
            order_by  => 'next_call_time'
        });

}

sub ready_to_report {
    my ($self, $rows) = @_;

    return $self->search({
            'status.final'  => 1,
            'reported'      => 0,
        },
        {
            join      => 'status',
            rows      => $rows,
            order_by  => 'update_time'
        });
}

1;
