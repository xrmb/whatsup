#!/usr/bin/env perl

use Cwd;
use lib (Cwd::abs_path(__FILE__.'/..'));

use Whatsup;

use strict;


my $pin = Whatsup->new->{'dht22_pin'};
for(;;)
{
  my $dht22 = `dht22 -p $pin 2>&1`;
  if($dht22 =~ /Humidity: ([\d\.]+).*Temperature: ([\d\.]+)/s)
  {
    #print("h: $1, t: $2\n");
    Whatsup->record(app => 'dht22', temperature => $2*10, humidity => $1*10);
    last;
  }
  sleep(1);
  next;
}