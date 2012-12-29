package Graph::Service::Foursquare;
use 5.008_001;

our $VERSION = '0.01';

use Mouse;
use JSON qw/decode_json/;
use URI;
use DateTime;
use Log::Minimal;
use LWP::UserAgent;

has "oauth_token"  => ( is => "ro", isa => "Str", required => 1 );
has "ua" => ( is => "ro", isa => "LWP::UserAgent", lazy_build => 1 );

sub get {
    my ($self) = @_;

    my $items = $self->_get(100, 0);

    my @datetimes;
    for my $item (@$items) {
        push @datetimes, DateTime->from_epoch( epoch => $item->{createdAt}, time_zone => $item->{timeZone} );
    }

    \@datetimes;
}

sub _get {
    my ($self, $limit, $offset) = @_;
    my $uri = URI->new("https://api.foursquare.com/v2/users/self/checkins");
    $uri->query_form( oauth_token => $self->oauth_token, limit => $limit, offset => $offset );

    infof $uri;
    my $res = $self->ua->get($uri);
    croak $res->status_line unless $res->is_success;

    my $json = decode_json($res->decoded_content);
    my $items = $json->{response}{checkins}{items};

    unless ( @$items < 1 ) {
        my $_items = $self->_get($limit, $offset + $limit);
        push @$items, @$_items;
    }

    return $items;
}

sub _build_ua {
    LWP::UserAgent->new;
}

no Mouse;
__PACKAGE__->meta->make_immutable();

1;
__END__

=head1 NAME

Graph::Service::Foursquare - Perl extention to do something

=head1 VERSION

This document describes Graph::Service::Foursquare version 0.01.

=head1 SYNOPSIS

    use Graph::Service::Foursquare;

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

=head2 Functions

=head3 C<< hello() >>

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

<<YOUR NAME HERE>> E<lt><<YOUR EMAIL ADDRESS HERE>>E<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, <<YOUR NAME HERE>>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
