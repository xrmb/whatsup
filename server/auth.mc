<%ARGS>
  $for
  $auth
</%ARGS>
<%INIT>
  my $fh;
  open($fh, '<', 'auth.dat') || return;
  my $auth = { split(/[\t\n\r]+/, join('', grep { /^[^;#]/ } <$fh>)) };
  close($fh);

  return $auth->{$for} eq $auth;
</%INIT>
