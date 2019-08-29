#!/usr/bin/env perl

use Cwd;
use lib (Cwd::abs_path(__FILE__.'/..'));

use Whatsup;

use strict;

my $test = grep(/test/, @ARGV);

my $bin = Whatsup->new->{'dht22_bin'} || die 'need dht22_bin';
my $pins = Whatsup->new->{'dht22_pin'} || die 'need dht22_pin';
my $names = Whatsup->new->{'dht22_name'} || die 'need dht22_name';
my $lock = Whatsup->new->{'dht22_lock'} == 0 ? 0 : 1;

my @names = split(/,/, $names);
my @pins = split(/,/, $pins);
my %whatsup;
SENSOR: for(;;)
{
  my $err = 0;
  my $out;
  my $pin = shift(@pins);
  my $name = shift(@names) || last;

  for(;;)
  {
    if($bin =~ /lol/) 
    { 
      $out = `$bin $pin 5 $lock 2>&1`; 
    }
  
    elsif($bin =~ /dht22/) 
    { 
      $out = `$bin -p $pin 2>&1`; 
    }

    else 
    { 
      die 'dht22_bin not supported'; 
    }

    if($out =~ /Humidity = (?<h>[\d\.]+).*Temperature = (?<t>[\d\.]+)/s ||
       $out =~ /Humidity: (?<h>[\d\.]+).*Temperature: (?<t>[\d\.]+)/s)
    {
      my $t = $+{t}*1;
      my $h = $+{h}*1;
      if($h < 0 || $h > 100 || $t < -40 || $t > 80)
      {
        $out = sprintf("value out of range: $name.humidity: %.1f%%, $name.temperature: %.1fC\n", $t, $h);
      }
      else
      {
        if($test)
        {
          printf("$name.humidity: %.1f%%, $name.temperature: %.1fC\n", $h, $t);
        }

        %whatsup = (%whatsup, app => 'dht22', "$name.temperature" => int($t*10), "$name.humidity" => int($h*10));
        last;
      }
    }

    sleep(1);
    $err++;
    print(STDERR "error: $out\n");
    last if($err > 5);
    next;
  }
}

if(%whatsup)
{
  if($test)
  {
    print("sending:\n");
    foreach my $key (keys(%whatsup))
    {
      printf("  %s\t%s\n", $key, $whatsup{$key});
    }
  }
  else
  {
    Whatsup->record(%whatsup);
  }
}

exit 0;
