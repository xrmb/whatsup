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

  if(ref($json) ne 'HASH')
  {
    $json = { error => 'json error '.$@ };
  }
  else
  {
    my $args = $m->current_args();
    my %args = @$args;
    delete($args{json});
    @$args = %args;
    $json = $m->call_next(%$json);
  }

  $m->out(encode_json($json));
  if($json->{error})
  {
    $m->abort($json->{code} ||500);
  }
</%INIT>
