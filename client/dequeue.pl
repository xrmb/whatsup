#!/usr/bin/env perl

use JSON;
use Cwd;

use lib (Cwd::abs_path(__FILE__.'/..'));
use Whatsup;

use strict;


if($ARGV[0] eq 'create') { exit system(qq|schtasks /create /tn "$ARGV[1]\\whatsup\\dequeue" /sc minute /mo 300 /tr "$^X |.Cwd::abs_path(__FILE__).qq|"|); }
if($ARGV[0] eq 'delete') { exit system(qq|schtasks /delete /tn "$ARGV[1]\\whatsup\\dequeue"|); }


$| = 1;


my $dh;
opendir($dh, Cwd::abs_path(__FILE__.'/../queue')) || die;
my @r = sort { (stat($a))[9] <=> (stat($b))[9] } map { Cwd::abs_path(__FILE__."/../queue/$_") } grep { /\.json$/ } readdir($dh);
closedir($dh);


my $whatsup = Whatsup->new(noqueue => 1);
foreach my $r (@r)
{
  print("$r ... ");

  my $fh;
  open($fh, '<', $r) || die;
  my $json;
  eval { $json = JSON->new->decode(join('', <$fh>)); };
  close($fh);

  if(!$json || $@)
  {
    warn($@);
    next;
  }

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
}

exit 0;
