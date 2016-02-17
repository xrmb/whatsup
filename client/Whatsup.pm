package Whatsup;

use strict;

use Sys::Hostname;
use LWP;
use JSON;
use File::Temp;



my $inst;

sub new
{
  my ($class, %args) = @_;

  if($inst) { return $inst; }

  my $cfg;
  my $fh;
  if(open($fh, '<', __FILE__.'/../config.dat'))
  {
    $cfg = { split(/[\t\n\r]+/, join('', grep { /^[^;#]/ } <$fh>)) };
    close($fh);
  }
  else
  {
    warn('cant open config.dat');
  }

  my $self = {};

  $self->{host} = $args{host} || $cfg->{host} || hostname() || warn('no host');
  $self->{app} = $args{app};
  $self->{service} = $cfg->{service} || warn('no service');
  $self->{noqueue} = $args{noqueue} || 0;

  $inst = bless($self, $class);
  return $inst;
}



sub record
{
  my ($self, %args) = @_;
  if(!ref($self)) { $self = __PACKAGE__->new(%args); }

  foreach my $k (qw(host app))
  {
    $args{$k} ||= $self->{$k};
    $args{$k} || warn("no $k") && return __LINE__;
  }
  $args{time} ||= time();

  my $json = to_json(\%args);

  my $uri = $self->{service}.'add/';
  my $req = HTTP::Request->new('POST', $uri);
  $req->header('Content-Type' => 'application/json');
  $req->content($json);

  my $lwp = LWP::UserAgent->new();
  my $res = $lwp->request($req);

  if($res->code() != 200)
  {
    warn(sprintf("service: %d %s %s\n", $res->code(), $uri, $res->content()));
    if(!$self->{noqueue})
    {
      my $dir = __FILE__.'/../queue';
      unless(-d $dir) { mkdir($dir) || warn('cant make queue dir') && return __LINE__; }
      my $fh = File::Temp->new(DIR => $dir, TEMPLATE => $args{app}.'_XXXXXX', SUFFIX => '.json', UNLINK => 0);
      print($fh $json);
    }
    return __LINE__;
  }

  return 0;
}



1;
