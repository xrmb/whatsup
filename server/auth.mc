<%ARGS>
  $for
  $auth
</%ARGS>
<%INIT>
  my $fh;
  open($fh, '<', $ENV{DOCUMENT_ROOT}.$m->current_comp()->dir_path().'/auth.dat') || warn('cant open auth.dat') && return;
  my %auth = split(/[\t\n\r]+/, join('', grep { /^[^;#]/ } <$fh>));
  close($fh);

  return $auth{$for} eq $auth;
</%INIT>
