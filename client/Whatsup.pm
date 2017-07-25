package Whatsup;

use strict;

use Sys::Hostname;
#use LWP;
use HTTP::Tiny;
use JSON::PP;
use File::Temp;
use DBI;
use Cwd;



my $inst;

sub new
{
  my ($class, %args) = @_;

  if($inst) { return $inst; }

  my $cfg = {};
  my $cfgfn = Cwd::abs_path(__FILE__.'/../config.dat');
  if(open(my $fh, '<', $cfgfn))
  {
    $cfg = { split(/[\t\n\r]+/, join('', grep { /^[^;#]/ } <$fh>)) };
    close($fh);
  }
  else
  {
    warn("cant open $cfgfn ($!)");
  }

  my $self = $cfg;

  $self->{host} = $args{host} || $cfg->{host} || hostname() || warn('no host');
  $self->{app} = $args{app};
  $self->{auth} = $cfg->{auth} || warn('no auth');
  $self->{service} = $cfg->{service} || warn('no service');
  $self->{db} = $cfg->{db};
  $self->{noqueue} = $args{noqueue} || 0;

  $inst = bless($self, $class);
  return $inst;
}



sub local_record
{
  my ($self, %args) = @_;
  if(!ref($self)) { $self = __PACKAGE__->new(%args); }

  my $host = $args{host} || $self->{host} || return (undef, __LINE__, 'need host');
  my $app = $args{app} || return (undef, __LINE__, 'need app');
  my $time = $args{time} || time();

  my $dbh = DBI->connect('dbi:SQLite:dbname='.$self->{db}, '', '') || return (undef, __LINE__, 'connect error');

  my $q = qq|INSERT INTO `records` (`host`, `app`, `time`, `received`, `key`, `value`) VALUES (?, ?, ?, ?, ?, ?)|;
  my $sth = $dbh->prepare($q) || return (undef, __LINE__, 'prepare error');

  my $any = 0;
  foreach my $key (sort(keys(%args)))
  {
    next if($key =~ /^(app|host|time|auth)$/);
    #warn join(', ', $host, $app, $time, time(), $key, int($args{$key}));
    if(!$sth->execute($host, $app, $time, time(), $key, int($args{$key})))
    {
      warn($sth->errstr());
    }

    $any++;
  }

  if(!$any)
  {
    #warn join(', ', $host, $app, $time, time());
    if(!$sth->execute($host, $app, $time, time(), undef, undef))
    {
      warn($sth->errstr());
    }
  }

  return (undef, 0, 'ok');
}



sub record
{
  my ($self, %args) = @_;
  if(!ref($self)) { $self = __PACKAGE__->new(%args); }

  foreach my $k (qw(host app auth))
  {
    $args{$k} ||= $self->{$k};
    $args{$k} || warn("no $k") && return __LINE__;
  }
  $args{time} ||= time();


  my $err;
  my $status;
  my $content;
  if($self->{db})
  {
    (undef, $err, $status) = $self->local_record(%args);
  }
  else
  {
    my $json = encode_json(\%args);

    my $uri = $self->{service}.'add/';

    my $ua = new HTTP::Tiny();
    my $res = $ua->post($uri, { headers => {'Content-Type' => 'application/json'}, content => $json});
    #my $req = HTTP::Request->new('POST', $uri);
    #$req->header('Content-Type' => 'application/json');
    #$req->content($json);

    #my $lwp = LWP::UserAgent->new();
    #my $res = $lwp->request($req);

    $content = $res->{content};
    $status = $res->{status};
    $err = $res->{status} != 200;
  }

  if($err)
  {
    warn(sprintf("service: %d %s\n", $status, $content));
    if(!$self->{noqueue})
    {
      delete($args{auth});
      my $json = encode_json(\%args);

      my $dir = __FILE__.'/../queue';
      unless(-d $dir) { mkdir($dir) || warn('cant make queue dir') && return __LINE__; }
      my $fh = File::Temp->new(DIR => $dir, TEMPLATE => $args{app}.'_XXXXXX', SUFFIX => '.json', UNLINK => 0);
      print($fh $json);
    }
    return wantarray ? (__LINE__, $content) : __LINE__;
  }

  return wantarray ? (0, $content) : 0;
}



1;
