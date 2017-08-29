#!/usr/bin/env perl

use Cwd;
use lib (Cwd::abs_path(__FILE__.'/..'));

use Whatsup;

use strict;

my $test = grep(/test/, @ARGV);

my $err = 0;
my $bin = Whatsup->new->{'dht22_bin'} || die 'need dht22_bin';
my $pin = Whatsup->new->{'dht22_pin'} || die 'need dht22_pin';
my $name = Whatsup->new->{'dht22_name'} || die 'need dht22_name';
for(;;)
{
  my $out;
  if($bin =~ /lol/)
  {
    $out = `$bin $pin 2>&1`;
    if($out =~ /Humidity = (?<h>[\d\.]+).*Temperature = (?<t>[\d\.]+)/s)
    {
      if($test)
      {
        print("$name.humidity: $+{h}, $name.temperature: $+{t}\n");
      }
      else
      {
        Whatsup->record(app => 'dht22', "$name.temperature" => int($+{t}*10), "$name.humidity" => int($+{h}*10));
      }
      last;
    }
  }
  elsif($bin =~ /dht22/)
  {
    $out = `$bin -p $pin 2>&1`;
    if($out =~ /Humidity: (?<h>[\d\.]+).*Temperature: (?<t>[\d\.]+)/s)
    {
      if($test)
      {
        print("$name.humidity: $+{h}, $name.temperature: $+{t}\n");
      }
      else
      {
        Whatsup->record(app => 'dht22', "$name.temperature" => int($+{t}*10), "$name.humidity" => int($+{h}*10));
      }
      last;
    }
  }
  else
  {
    die 'dht22_bin not supported';
  }
  sleep(1);
  $err++;
  print(STDERR "error: $out\n");
  last if($err > 5);
  next;
}

exit 0;
