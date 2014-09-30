package Informer::Reporter;
use Moose;
use LWP::UserAgent;
use HTTP::Request::Common;
use Const::Fast;
use JSON;

const my $USER_AGENT => 'ResultSender';
const my $UA_TIMEOUT => 5;

has 'url' => (
    is        => 'rw',
    required  => 1,
);

has 'ua' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    builder => '_init_ua',
);

sub _init_ua  { 
    LWP::UserAgent->new(
        agent   => $USER_AGENT,
        timeout => $UA_TIMEOUT,
    )
}


sub send {
    my ($self, $results)  = @_;

    if (ref $results ne 'ARRAY') {
        $results = [ $results ];
    }
    
    my $res = $self->ua->request(
        POST $self->url,
        Content_Type  => 'application/json',
        Content       => encode_json $results,
    );

    return $res->is_success;
}

__PACKAGE__->meta->make_immutable;

