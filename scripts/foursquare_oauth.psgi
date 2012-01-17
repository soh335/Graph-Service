use strict;
use warnings;

use OAuth::Lite2::Client::WebServer;
use Plack::Request;
use Plack::Response;
use FindBin;
use File::Spec;

my $config_file = File::Spec->catfile($FindBin::Bin, "..", "config.pl");
die "not exist $config_file " unless -e $config_file;
my $config  = do $config_file;

die "Foursquare config in $config_file" unless defined $config->{Foursquare};
my $id = $config->{Foursquare}{id} or die "not exist Foursquare id in $config_file";
my $secret = $config->{Foursquare}{secret} or die "not exist Foursquare secret in $config_file";

my $client = OAuth::Lite2::Client::WebServer->new(
    id                => $id,
    secret            => $secret,
    authorize_uri     => "https://ja.foursquare.com/oauth2/authorize",
    access_token_uri  => "https://ja.foursquare.com/oauth2/access_token",
);
my $redirect_uri = "http://localhost:5000";

my $app = sub {
    my $env = shift;

    my $req = Plack::Request->new($env);
    my $code = $req->query_parameters->{code};
    my $res = Plack::Response->new;

    if ( $code ) {
        my $access_toekn = $client->get_access_token(
            code  => $code,
            redirect_uri  => $redirect_uri,
        );

        $res->status(200);
        $res->content_type('text/plain');
        $res->body("oauth_token:$access_toekn->access_token");
    }
    else {
        my $redirect_uri = $client->uri_to_redirect( redirect_uri => $redirect_uri );
        $res->redirect($redirect_uri);
    }

    $res->finalize;
};
