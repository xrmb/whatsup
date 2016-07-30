#perl

use strict;

use LWP;
use JSON;
use Cwd;

use Whatsup;


if($ARGV[0] eq 'create') { exit system(qq|schtasks /create /tn "$ARGV[1]\\whatsup\\tixati" /st 00:00 /sc minute /mo 60 /tr "$^X |.Cwd::abs_path(__FILE__).qq|"|); }
if($ARGV[0] eq 'delete') { exit system(qq|schtasks /delete /tn "$ARGV[1]\\whatsup\\tixati"|); }


my $w = new Whatsup(app => 'tixati');


my ($proto, $user, $pass, $host, $port) = ($w->{tixati_url} =~ m!^(\w*)://(\w+):(\w+)@(.*?):(\d+)!);
my $req = HTTP::Request->new('GET', $w->{tixati_url});

my $ua = LWP::UserAgent->new();
$ua->credentials("$host:$port", 'Tixati Web Interface', $user, $pass);
my $res = $ua->request($req);

die if($res->code() != 200);

my $data = JSON->new->utf8->decode($res->content());
my %whatsup;
foreach my $e (@$data)
{
  #warn JSON->new->pretty(1)->encode($e);

  next if(exists($e->{ignore}));
  next if($e->{pieces_remaining} != 0);
  next if($e->{availability} == 0);
  next if($e->{status} !~ /seeding/i);

  ($e->{avail_seeds}, $e->{avail_peers}) = ($e->{status} =~ /\d+ \((\d+)\) \d+ \((\d+)\)/);

  printf("%s\n\tout:\t%s\n\tavail:\t%d\n\tpeers:\t%d\n\n", $e->{name}, to_number($e->{out_bytes_total}), $e->{availability}*10000, $e->{peers}*1);

  my $name = $e->{name};
  $whatsup{"avail_$name"} = int($e->{availability}*10000);
  $whatsup{"avail_peers_$name"} = int($e->{avail_peers}*1);
  $whatsup{"avail_seeds_$name"} = int($e->{avail_seeds}*1);
  $whatsup{"out_$name"} = to_number($e->{out_bytes_total});

  warn JSON->new->pretty(1)->encode($e);
}

if($ARGV[0] ne 'test')
{
  $w->record(%whatsup);
}

sub to_number
{
  my ($n) = @_;
  $n =~ s/[, ]//g;
  if($n =~ s/K$//)
  {
    $n *= 1024;
  }
  return $n*1;
}
