package Graph::Service;
use 5.008_001;

our $VERSION = '0.01';

use Mouse;
use Module::Load;
use File::Spec;
use Path::Class;
use FindBin;

has "output_dir" => ( is => "ro", isa => "Str", required => 1 );
has "target" => ( is => "ro", isa => "Str", required => 1 );
has "config" => ( is => "ro", isa => "HashRef", default => sub { +{} }, );

sub run {
    my ($self) = @_;

    my $class =  "Graph::Service::" . $self->target;
    load $class;
    my $config = $self->config->{$self->target} || {};

    my $target_instance = $class->new(%$config);
    my $hash = $self->_prepare_datetime($target_instance->get);

    my $tmpdir = File::Spec->tmpdir();
    my $csv_file = file($tmpdir, "$class.csv");

    $self->_save_as_csv($csv_file, $hash);

    my $graph_r_path = File::Spec->catfile($FindBin::Bin, "graph.r");
    my $output_path = File::Spec->catfile($self->output_dir, $self->target . ".png");

    system("R", "--quiet", "--slave", "--vanilla", "-f", $graph_r_path, "--args", $csv_file, $output_path);

    unlink $csv_file;
}

sub _prepare_datetime {

    my ($self, $datetimes) = @_;

    my $hash;
    for my $datetime (@$datetimes) {
        my $year = $datetime->strftime("%Y");
        my $date = $datetime->strftime("%m-%d");
        $hash->{$year} ||= {};
        $hash->{$year}{$date} ||= 0;
        $hash->{$year}{$date}++;
    }

    my @time = localtime;
    my $current_year = $time[5] + 1900;

    for my $year ( sort keys %$hash ) {

        my @sorted_dates = sort(keys(%{$hash->{$year}}));

        unless ( defined $hash->{$year}{"01-01"} ) {
            my ($month, $day) = split /-/, $sorted_dates[0];

            my $dt = DateTime->new(
                year => $year,
                month => $month,
                day => $day,
            );
            $dt->set_time_zone($self->config->{time_zone}) if $self->config->{time_zone};

            $hash->{$year}{ $dt->subtract( days => 1 )->strftime("%m-%d") } = 0;
            $hash->{$year}{"01-01"} = 0;
        }

        if ( $current_year != $year and ! defined $hash->{$year}{"12-31"} ) {
            $hash->{$year}{"12-31"} = $hash->{$year}{$sorted_dates[$#sorted_dates]};
        }
    }

    $hash;
}

sub _save_as_csv {
    my ($self, $file, $hash) = @_;

    my $fh = $file->openw or die $!;

    $fh->print("year,date,count\n");
    for my $year ( sort keys %$hash ) {
        for my $date ( sort keys %{$hash->{$year}} ) {
            $fh->print(sprintf("%s,2000-%s,%d\n", $year,$date,$hash->{$year}{$date}));
        }
    }

    $fh->close;
}

no Mouse;
__PACKAGE__->meta->make_immutable();

1;
