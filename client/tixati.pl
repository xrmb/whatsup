#perl

use LWP;
use JSON;
use Cwd;
use HTML::Entities;

use lib (__FILE__.'/..');
use Whatsup;

use strict;


if($ARGV[0] eq 'create') { exit system(qq|schtasks /create /tn "$ARGV[1]\\whatsup\\tixati" /st 00:00 /sc minute /mo 60 /tr "$^X |.Cwd::abs_path(__FILE__).qq|"|); }
if($ARGV[0] eq 'delete') { exit system(qq|schtasks /delete /tn "$ARGV[1]\\whatsup\\tixati"|); }


my $w = new Whatsup(app => 'tixati');


my ($proto, $user, $pass, $host, $port) = ($w->{tixati_url} =~ m!^(\w*)://(\w+):(\w+)@(.*?):(\d+)!);
my $req = HTTP::Request->new('GET', $w->{tixati_url}.'/torrents_data');

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

  my $peers = JSON->new->utf8->decode($res->content());
  $e->{peers} = 0;
  $e->{seeds} = 0;
  foreach my $p (@$peers)
  {
    next if(exists($p->{ignore}));
    $p->{statusclass_alt} = { map { $_ => 1 } split(/_/, $p->{statusclass_alt}) };
    if($p->{statusclass_alt}{complete})
    {
      $e->{seeds}++;
    }
    if($p->{statusclass_alt}{online} && !$p->{statusclass_alt}{complete})
    {
      $e->{peers}++;
    }
  }

  printf("%s\n\tout:\t%s\n\tavail:\t%d\n\tpeers:\t%d\n\tseeds:\t%d\n\n", $e->{name}, to_number($e->{out_bytes_total}), $e->{availability}*10000, $e->{peers}, $e->{seeds});


  my $name = decode_entities($e->{name});
  $whatsup{"avail_$name"} = int($e->{availability}*10000);
  $whatsup{"peers_$name"} = $e->{peers}*1;
  $whatsup{"seeds_$name"} = $e->{seeds}*1;
  $whatsup{"out_$name"} = to_number($e->{out_bytes_total});

  $req = HTTP::Request->new('GET', join('/', $w->{tixati_url}, 'transfers', $e->{guid}, 'data'));
  $res = $ua->request($req);
  die if($res->code() != 200);

  #warn JSON->new->pretty(1)->encode($data);
  #warn JSON->new->pretty(1)->encode($e);
}

#print JSON->new->pretty(1)->encode(\%whatsup);
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
