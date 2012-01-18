package Graph::Service::Exif;

use Mouse;
use DateTime::Format::Strptime;
use File::Zglob;
use Image::ExifTool qw/:Public/;
use Log::Minimal;

has "path" => ( is => "ro", isa => "Str", required => 1 );
has "pattern" => ( is => "ro", isa => "Str", default => sub { "%Y:%m:%d %T" } );
has "time_zone" => ( is => "ro", isa => "Str" );
has "exif_time_field_name" => ( is => "ro", isa => "Str", default => sub { "DateTimeOriginal" } );

sub get {
    my ($self) = @_;

    my @files = zglob($self->path);
    my $strp = DateTime::Format::Strptime->new( pattern => $self->pattern );

    my @datetimes;

    local $| = 1;
    my $i = 0;
    my @error;

    for my $file (@files) {
        printf "%0.1f%%\r", (++$i / @files) * 100;
        next unless -f $file;
        my $info = ImageInfo( $file );
        my $datetime = $strp->parse_datetime($info->{$self->exif_time_field_name});
        unless ( $datetime ) {
            push @error, $file;
            next;
        }
        $datetime->set_time_zone( $self->time_zone ) if $self->time_zone;
        push @datetimes, $datetime;
    }

    infof "all: %d  error: %d", scalar @files, scalar @error;
    for my $file (@error) {
        infof "error: $file";
    }

    \@datetimes;
}

no Mouse;
__PACKAGE__->meta->make_immutable();

1;
