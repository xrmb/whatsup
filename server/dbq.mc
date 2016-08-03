<%ARGS>
  $q
  @exe => ()
  $exec => 1
</%ARGS>
<%INIT>
  use DBI;

  my $db = $ENV{DOCUMENT_ROOT}.$m->current_comp()->dir_path().'/db.sqlite';
  my $dbh = DBI->connect('dbi:SQLite:dbname='.$db, '', '') || return (undef, { error => __LINE__ });

  my $sth = $dbh->prepare($q) || return (undef, { error => __LINE__ });
  if($exec)
  {
    $sth->execute(@exe) || return (undef, { error => __LINE__, msg => $dbh->errstr() });
  }

  return $sth;
</%INIT>
