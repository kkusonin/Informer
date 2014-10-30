package Informer::Controller::Task;
use Moose;
use DateTime;
use namespace::autoclean;
use Const::Fast;

BEGIN { extends 'Catalyst::Controller::REST'; }

=head1 NAME

Informer::Controller::Task - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

sub tasks_add_POST :Path('/task/add') :Args(0) {
    my ( $self, $c ) = @_;
    
    my @result;

    $c->log->debug("Request data: " . $c->req->data);
    foreach my $request_data (@{$c->req->data}) {
        my $id = $request_data->{ReqID};
        eval {
            my $task = $c->model('InformerDB::Task')->create({
                id              => $id,
                phone_number    => $request_data->{Phone},
                rec_number      => $request_data->{ReqNumber},
                scheduler       => $c->model('Scheduler'),
            });
            push @result, { ReqID => $id, Result => 'ADDED' };
        };
        if ($@) {
            $c->log->debug($@);
            push @result, { ReqID => $id, Result => 'ERROR' };
        }
    }
 
    $self->status_ok($c, entity => \@result);
}

sub tasks_cancel_POST : Path('/task/cancel') {
    my ( $self, $c ) = @_;

    my @result;

    $c->log->debug("Request data: " . $c->req->data);
    foreach my $request_data (@{$c->req->data}) {
        my $id = $request_data->{ReqID};
        eval {
            my $task = $c->model('InformerDB::Task')->find($id);
            $task->cancel;
            push @result, { ReqID => $id, Result => 'CANCELED' };
        };
        if ($@) {
            push @result, { ReqID => $id, Result => 'ERROR' };
        }
    }
    
     $self->status_ok($c, entity => \@result);
 }


sub update_task_POST :Path('/task') :Args(1) {
    my ($self, $c, $id) = @_;
    
    eval {
	    my $task      = $c->model('InformerDB::Task')->find($id);
	    my $scheduler = $c->model('Scheduler');
	    my $reporter  = $c->model('Reporter');

	    $task->reporter($reporter);
	    $task->scheduler($scheduler);
	    
	    my $status_str = $c->request->params->{status};
	    my $cause = $c->request->params->{cause};

	    $task->complete_last_call($status_str, $cause);
    };
    $self->status_ok(
        $c,
        entity => {},
    );
}

=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__PACKAGE__->config(default => 'application/json');

__PACKAGE__->meta->make_immutable;

1;
