package AWS::XRay::Segment;

use 5.012000;
use strict;
use warnings;

use JSON::XS ();
use Time::HiRes ();

my $header = qq|{"format":"json","version":1}\n|;
my $json   = JSON::XS->new;

sub new {
    my $class = shift;
    my $src   = shift;

    return bless {}, "${class}::NoTrace" if !$AWS::XRay::ENABLED;

    my $segment = {
        id         => AWS::XRay::new_id(),
        start_time => Time::HiRes::time(),
        trace_id   => $AWS::XRay::TRACE_ID,
        %$src,
    };
    if (my $parent_id = $AWS::XRay::SEGMENT_ID) {
        # This is a sub segment.
        $segment->{parent_id} = $parent_id;
        $segment->{type}      = "subsegment";
        $segment->{namespace} = "remote";
    }
    bless $segment, $class;
}

sub send {
    my $self = shift;
    $self->{end_time} //= Time::HiRes::time();
    my $sock = AWS::XRay::sock() or return;
    $sock->print($header, $json->encode({%$self}));
}

package AWS::XRay::Segment::NoTrace;

sub send {
    # do not anything
}

1;
