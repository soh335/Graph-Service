use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Graph::Service;
use File::Spec;

my $target = shift;
die "should pass first argument as target" unless $target;

my $output_dir = shift;
die "should pass second argument as outputdir" unless $output_dir;

my $config_file = File::Spec->catfile($FindBin::Bin, "..", "config.pl");
my $config = -e $config_file ? do $config_file : {};

Graph::Service->new(
    output_dir => $output_dir,
    target => $target,
    config => $config,
)->run;
