package Informer::Scheduler;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use DateTime;

has limit => (
    is        => 'ro',
    isa       => 'Int',
    required  => 1,
);

has start => (
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { { days => 0, hours => 0} },
);

has table => (
    is        => 'ro',
    isa       => 'ArrayRef',
    default   => sub { {} },
);

sub schedule {
    my ($self, $c, $l) = @_;
    my $start = $self->start;
    
    my $limit = ($l) ? $l : $self->limit;

    return DateTime->now(time_zone => 'local')->add( $start ) if !$c;

    Carp::croak "Maximum attempts number has been reached" unless ($c < $limit);

    my $table = $self->table;
    my $shift = $table->[($c - 1) % scalar(@$table)];

    my %shift = map { 
        (ref $shift->{$_}) 
            ? ($_ => $shift->{$_}->{from} + int(rand($shift->{$_}->{to} - $shift->{$_}->{from})))
            : ($_ => $shift->{$_});
    } keys %$shift;

    return DateTime->today(time_zone => 'local')->add( %shift );
}

__PACKAGE__->meta->make_immutable;

1;
