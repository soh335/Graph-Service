package Graph::Service::iPhoto;

use Mouse;
use DBI;
use DateTime::Format::Strptime;

has "db" => ( is => "ro", isa => "Str", required => 1 );
has "time_zone" => ( is => "ro", isa => "Str" );

sub get {
    my ($self) = @_;

    my $dbh = DBI->connect("dbi:SQLite:dbname=".$self->db, '', '', {
            AutoCommit => 1,
            RaiseError => 1,
        });

    my $times = $dbh->selectcol_arrayref("select datetime(photoDate + julianday('2000-01-01 00:00:00')) from SqPhotoInfo");

    $dbh->disconnect;

    my @datetimes;
    my $strp = DateTime::Format::Strptime->new( pattern => "%Y-%m-%d %T" );
    for my $time (@$times) {
        my $datetime = $strp->parse_datetime($time);
        $datetime->set_time_zone( $self->time_zone ) if $self->time_zone;
        push @datetimes, $datetime;
    }

    \@datetimes;
}

no Mouse;
__PACKAGE__->meta->make_immutable();

1;
