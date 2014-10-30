use utf8;
package Informer::Schema::Result::Task;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Informer::Schema::Result::Task

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<tasks>

=cut

__PACKAGE__->table("tasks");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 phone_number

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 16

=head2 status_id

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 entry_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 update_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 rec_id

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 rec_number

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 dur_days

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 next_call_time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 canceled

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 reported

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
  "phone_number",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 16 },
  "status_id",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "entry_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "update_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "rec_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "rec_number",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "dur_days",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "next_call_time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "canceled",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "reported",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 calls

Type: has_many

Related object: L<Informer::Schema::Result::Call>

=cut

__PACKAGE__->has_many(
  "calls",
  "Informer::Schema::Result::Call",
  { "foreign.task_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 status

Type: belongs_to

Related object: L<Informer::Schema::Result::Status>

=cut

__PACKAGE__->belongs_to(
  "status",
  "Informer::Schema::Result::Status",
  { id => "status_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-10-30 14:48:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wbC1Zgs/CGWI3jPFmOyZ3g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
has scheduler => (
    is  => 'rw',
    isa => 'Maybe[Informer::Scheduler]'
);

has reporter => (
    is  => 'rw',
    isa => 'Maybe[Informer::Reporter]'
);

sub new {
    my ( $class, $attrs ) = @_;

    $attrs->{status_id} = 0 unless defined $attrs->{status_id};

    my $scheduler = delete $attrs->{scheduler};
    my $reporter  = delete $attrs->{reporter};
    
    my $self = $class->next::method($attrs);

    $self->scheduler($scheduler);
    $self->reporter($reporter);
    $self->next_call_time($scheduler->schedule(0)) if defined $scheduler;

    return $self;
}

sub last_call {
    my $self  = shift;

    return $self->calls->search(
        {},
        {
            order_by => { -desc => 'start_time' },
            rows => 1,
        },
    )->single;
}

sub completed {
    $_[0]->status->final;
}

sub incall {
    my $self = shift;
    return $self->last_call && !$self->last_call->end_time;
}

sub ready_to_call {
    my $self  = shift;
    return !$self->completed && !$self->incall &&
            $self->next_call_time <= DateTime->now(time_zone => 'local');
}

sub call_info {
    my $self = shift;

    my $uid = time . '-' . $self->id . '-' . ($self->calls + 1);

    return { 
        phone_number  => $self->phone_number,
        taskid        => $self->id,
        rec_number    => $self->rec_number,
        sessionid     => $uid,
    }
}

sub reset_time {
    $_[0]->update({ next_call_time => DateTime->now(time_zone => 'local')});
}

sub place_next_call {
    my ($self, $dialer) = @_;
    
    Carp::croak "Impossible to call" if !$self->ready_to_call;

    my $cid = $dialer->originate($self->call_info);
    my $status = $self->status_for('INCALL');
                         
    $self->update({status_id => $status->id })
         ->create_related(
        'calls',
        {
            start_time  => DateTime->now(time_zone => 'local'),
            status_id   => $status->id,
        }
    );
    return $cid;
}

sub complete_last_call {
    my ($self, $status_val, $cause) = @_;

    $cause = 0 unless defined $cause;

    my $status =  $self->status_for($status_val);
    
    $self->update({status_id => $status->id})
         ->last_call->update({
                 end_time => DateTime->now(time_zone => 'local'),
                 status_id  => $status->id,
                 cause      => $cause,
             });


    if (defined (my $reporter = $self->reporter) && !$status->final) {
        $reporter->send($self->result);
    }

    my $callnum = $self->calls;
    if ($status->final) {
        $self->update;
    }
    elsif ($callnum < $self->scheduler->limit) {
        $self->update({
            next_call_time => $self->scheduler->schedule($callnum, $self->dur_days),
        });
    }
    else {
        $status = $self->status_for('MAXCALL');
        $self->update({ status_id => $status->id });
    }

    if ($self->canceled) {
        $status = $self->status_for('CANCELED');
        $self->update({ status_id => $status->id });
    }

    $status->id;
}

sub status_for {
    my ($self, $value) = @_;

    return  $self->result_source
                 ->schema
                 ->resultset('Status')
                 ->single({ value   => $value });
}


sub cancel {
    my $self = shift;
    
    if ($self->incall) {
        $self->update({ canceled => 1 });
    }
    else {
        my $status = $self->status_for('CANCELED');
        $self->update({ status_id => $status->id, canceled => 1});
    }
}

sub result {
    my ($self) = @_;

    use Tie::IxHash;
    tie my %result, 'Tie::IxHash';
    $result{ReqID}          = $self->id;
    $result{ResultID}       = $self->status->id;
    $result{ResultDescript} = $self->status->description;
    $result{ResultDate}     = $self->update_time->strftime("%H:%M:%S %d-%m-%Y");

    return \%result;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
