package Informer::Dialer;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use File::Basename;
use File::Copy qw ( move );
use File::Spec::Functions;
use File::Temp qw( tempfile );

has channel => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1
);

has timeout => (
    is        => 'rw',
    isa       =>'Int',
    default   => 60
);

has spool   => (
    is        => 'ro',
    isa       => 'Str',
    init_arg  => 'spool_dir',
    default   => '/var/spool/asterisk/outgoing'
);

has context => (
    is        => 'ro',
    isa       => 'Str',
    default   => 'default'
);

has extension => (
    is        => 'ro',
    isa       => 'Str',
    default   => 's'
);

has priority  => (
    is        => 'ro',
    isa       => 'Str',
    default   => '1'
);

sub originate {
    my ($self, $args) = @_;

    my ($fh, $filename) = tempfile('callXXXXX');

    # Write call file in temporary directory
    my ($ch_type, $ch_id) = split '/', $self->channel;
    (my $phone_number = delete $args->{phone_number}) or 
        Carp::croak "Phone number missing";

    print $fh "Channel: $ch_type/" . $phone_number . "\@$ch_id\n";
    print $fh 'Context: '   . $self->context   . "\n";
    print $fh 'Extension: ' . $self->extension . "\n";
    print $fh 'Priority: '  . $self->priority  . "\n";

    foreach my $var (sort keys %$args) {
        print $fh 'Set: ' . uc($var) . '=' . $args->{$var} . "\n";
    }
    close $fh;

    my $basename = basename($filename);

    # Move call file to spool directory
    move $filename, catfile($self->spool, $basename);

    return $basename;
}

__PACKAGE__->meta->make_immutable;

1;
