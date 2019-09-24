#!/usr/bin/env perl

use Cwd;
use lib (Cwd::abs_path(__FILE__.'/..'));

use Whatsup;

use strict;

my $wup = Whatsup->new();

my %c = map { $wup->{$_} => $_ } sort grep(/^miflora/, keys(%$wup));

my $cmd = join(' ', Cwd::abs_path(__FILE__.'/../miflora-reader.py'), keys(%c));
#print("$cmd\n");
my $d = `$cmd`;
my %d;
foreach my $line (split(/\n/, $d))
{
  #print("$line\n");
  my ($mac, $key, $value) = split(/\t/, $line);
  if($key eq 'error')
  {
    print("$c{$mac}: error\n");
    next;
  }
  next if($key =~ /^(error|name|firmware)$/);
  $value *= 1;
  if($key =~ /^(temperature|moisture)$/) { $value *= 10; }
  $d{ $c{$mac} }{ $key } = int($value);
}

foreach my $sensor (sort(keys(%d)))
{
  print("$sensor:\n");
  foreach my $key (sort(keys(%{$d{$sensor}})))
  {
    printf("  %-20s %d\n", $key, $d{$sensor}{$key});
  }
  print("\n");

  if($ARGV[0] ne 'test')
  {
    $wup->record(host => $sensor, app => 'miflora', %{$d{$sensor}});
  }
}

exit 0;
