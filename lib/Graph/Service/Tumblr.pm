package Graph::Service::Tumblr;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use Mouse;
use OAuth::Lite::Consumer;
use JSON qw/decode_json/;
use URI;
use Log::Minimal;
use DateTime;

has "consumer"            => ( is => "ro", isa => "OAuth::Lite::Consumer", lazy_build => 1 );
has "token"               => ( is => "ro", isa => "OAuth::Lite::Token", lazy_build => 1 );
has "consumer_key"        => ( is => "ro", isa => "Str", required => 1 );
has "consumer_secret"     => ( is => "ro", isa => "Str", required => 1 );
has "access_token"        => ( is => "ro", isa => "Str", required => 1 );
has "access_token_secret" => ( is => "ro", isa => "Str", required => 1 );
has "blog"                => ( is => "ro", isa => "Str", required => 1 );
has "time_zone"           => ( is => "ro", isa => "Str", required => 1 );

sub get {
    my ($self) = @_;

    my $items = $self->_get(20,0);

    my @datetimes;
    for my $item (@$items) {
        push @datetimes, DateTime->from_epoch( epoch => $item->{timestamp}, time_zone => $self->time_zone );
    }

    \@datetimes;
}

sub _get {
    my ($self, $limit, $offset) = @_;

    my $uri = URI->new("http://api.tumblr.com/v2/blog/" . $self->blog . "/posts");
    $uri->query_form( api_key => $self->consumer_key, limit => $limit, offset => $offset );

    infof $uri;

    my $res = $self->consumer->request(
        method => "GET",
        url => $uri,
        token => $self->access_token,
    );

    die $res->status_line unless $res->is_success;
    my $json = decode_json($res->decoded_content);
    my $items = $json->{response}{posts};

    unless ( @$items < 1 ) {
        my $_items = $self->_get($limit, $offset + $limit);
        push @$items, @$_items;
    }

    return $items;
}

sub _build_token {
    my $self = shift;
    OAuth::Lite::Token->new(
        token   => $self->access_token,
        secret  => $self->access_token_secret,
    );
}

sub _build_consumer {
    my $self = shift;
    OAuth::Lite::Consumer->new(
        consumer_key => $self->consumer_key,
        consumer_secret => $self->consumer_secret,
        site => "http://www.tumblr.com",
        request_token_path => "/oauth/request_token",
        authorize_path => "/oauth/authorize",
        access_token_path => "/oauth/access_token",
    );
}

no Mouse;
__PACKAGE__->meta->make_immutable();

1;
__END__

=head1 NAME

Graph::Service::Tumblr - Perl extention to do something

=head1 VERSION

This document describes Graph::Service::Tumblr version 0.01.

=head1 SYNOPSIS

    use Graph::Service::Tumblr;

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
