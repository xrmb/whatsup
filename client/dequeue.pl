#!perl

use JSON;

use Whatsup;

use strict;

$|=1;


my $dh;
opendir($dh, 'queue') || die;
my @r = sort { (stat($a))[9] <=> (stat($b))[9] } map { "queue/$_" } grep { /\.json$/ } readdir($dh);
closedir($dh);


my $whatsup = Whatsup->new(noqueue => 1);
foreach my $r (@r)
{
  print("$r ... ");

  my $fh;
  open($fh, '<', $r) || die;
  my $json = JSON->new->decode(join('', <$fh>));
  close($fh);

  if($whatsup->record(%$json) == 0)
  {
    print("ok\n");
    unlink($r);
  }
  else
  {
    print("error\n");
  }

  sleep(1);
  #exit;
}
