package Graph::Service::HatenaBookmark;
use 5.008_001;

our $VERSION = '0.01';

use Mouse;
use LWP::UserAgent;
use LWP::Authen::Wsse;
use Log::Minimal;
use XML::LibXML;
use DateTime::Format::W3CDTF;
use Path::Class;
use FindBin;
use Carp;

has "username"  => ( is => "ro", isa => "Str", required => 1 );
has "password"  => ( is => "ro", isa => "Str", required => 1 );
has "timeout"   => ( is => "ro", isa => "Int", default => sub { 60 * 5 } );

sub get {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->credentials('b.hatena.ne.jp:80', '', $self->username, $self->password);
    $ua->timeout($self->timeout);
    my $res = $ua->get('http://b.hatena.ne.jp/dump');

    croak $res->status_line unless $res->is_success;

    my $dom = XML::LibXML->load_xml( string => $res->decoded_content );
    my @issueds = $dom->getElementsByTagName('issued');

    my @datetimes;

    for my $issue (@issueds) {
        my $datetime = DateTime::Format::W3CDTF->parse_datetime( $issue->textContent );
        push @datetimes, $datetime;
    }

    \@datetimes
}

no Mouse;
__PACKAGE__->meta->make_immutable();

1;
