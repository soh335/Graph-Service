use strict;
use warnings;

use OAuth::Lite::Consumer;
use Plack::Response;
use Plack::Request;
use Plack::Builder;
use FindBin;
use File::Spec;

my $config_file = File::Spec->catfile($FindBin::Bin, "..", "config.pl");
die "not exist $config_file " unless -e $config_file;
my $config  = do $config_file;

die "Tumblr config in $config_file" unless defined $config->{Tumblr};
my $consumer_key = $config->{Tumblr}{consumer_key} or die "not exist Tumblr consumer_key in $config_file";
my $consumer_secret = $config->{Tumblr}{consumer_secret} or die "not exist Tumblr consumer_secret in $config_file";

my $consumer = OAuth::Lite::Consumer->new(
    consumer_key => $consumer_key,
    consumer_secret => $consumer_secret,
    site => "http://www.tumblr.com",
    request_token_path => "/oauth/request_token",
    authorize_path => "/oauth/authorize",
    access_token_path => "/oauth/access_token",
);
my $callback_url = "http://localhost:5000";

my $app = sub {
    my $env = shift;

    my $req = Plack::Request->new($env);
    my $oauth_verifier = $req->query_parameters->{oauth_verifier};
    my $res = Plack::Response->new;
    my $session = $env->{'psgix.session'};

    if ( $oauth_verifier ) {
        my $request_token = $session->{request_token};
        my $access_token = $consumer->get_access_token(
            token => $request_token,
            verifier => $oauth_verifier,
        );

        $res->status(200);
        $res->content_type("text/plain");
        $res->body(sprintf("access_token:%s\naccess_token_secret:%s\n", $access_token->token, $access_token->secret))
    }
    else {
        my $request_token = $consumer->get_request_token;
        $session->{request_token} = $request_token;
        $res->redirect($consumer->url_to_authorize(
                token => $request_token,
            ));
    }

    $res->finalize;
};

builder {
    enable 'Session';
    $app;
};
