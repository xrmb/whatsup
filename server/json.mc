<%ARGS>
  $json => '{}'
</%ARGS>
<%INIT>
  use JSON;
  #use JSON::PP;

  eval
  {
    $json = JSON->new->decode($json) || {};
    #$json = JSON->new->allow_singlequote->allow_barekey->decode($json) || {};
  };

  my $error;
  if(ref($json) ne 'HASH' && ref($json) ne 'ARRAY')
  {
    $json = { error => 'json error '.$@ };
  }
  else
  {
    my $args = $m->current_args();
    my %args = @$args;
    delete($args{json});
    @$args = %args;
    if(ref($json) eq 'HASH')
    {
      ($json, $error) = $m->call_next(%$json);
    }
    if(ref($json) eq 'ARRAY')
    {
      ($json, $error) = $m->call_next(data => $json);
    }
  }

  $r->content_type('application/json');
  $m->out(encode_json($json));

  if($error)
  {
    $r->headers_out->{Status} = $error;
    $m->abort($r->headers_out->{Status});
  }
  elsif(ref($json) eq 'HASH' && $json->{error})
  {
    $r->headers_out->{Status} = $json->{code} || 500;
    $m->abort($r->headers_out->{Status});
  }
</%INIT>
