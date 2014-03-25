package OpenAccess::Example;
use Mojo::Base 'Mojolicious::Controller';
use DBI;
use Data::Dumper;

sub welcome {
  my $self = shift;
  my @a;
  my $dbh = DBI->connect('DBI:mysql:openaccess', 'root', 'toor') || die "Could not connect to database: $DBI::errstr";
  $dbh->do('set names utf8');
  my $sth = $dbh->prepare("SELECT u.id, u.name, u.surname, u.tag, l.created FROM users as u JOIN log as l on l.tag=u.tag GROUP BY u.id ORDER BY l.created DESC LIMIT 10");
  $sth->execute();
  my $a = $sth->fetchall_hashref("tag");
  warn Dumper $a;
  $self->render(
  	users => $a,
}

1;
