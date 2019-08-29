#!/usr/bin/env perl

use Cwd;
use lib (Cwd::abs_path(__FILE__.'/..'));

use Whatsup;

use strict;

if($ARGV[0] eq 'create') { exit system(qq|schtasks /create /tn "$ARGV[1]\\whatsup\\wemo" /sc minute /mo 1 /tr "$^X |.Cwd::abs_path(__FILE__).qq|"|); }
if($ARGV[0] eq 'delete') { exit system(qq|schtasks /delete /tn "$ARGV[1]\\whatsup\\wemo"|); }


my $wup = Whatsup->new();

foreach my $wemo (sort(grep(/^wemo/, keys(%$wup))))
{
  ### get services: http://192.168.1.151:49153/insightservice.xml
  my $action = 'GetInsightParams';

  my $body = qq|<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:$action xmlns:u="urn:Belkin:service:insight:1"/></s:Body></s:Envelope>|;
  my $res = HTTP::Tiny->new->post(
      sprintf('http://%s:49153/upnp/control/insight1', $wup->{$wemo}),
      {
        headers => {
          'Content-Type' => 'text/xml',
          SOAPACTION => qq|"urn:Belkin:service:insight:1#$action"|
        },
        content => $body
      }
    );

  #warn($res->{status});
  #warn($res->{content});

  my %d;
  if($res->{content} =~ m|<InsightParams>(.*?)</InsightParams>|)
  {
    my @d = split(/\|/, $1);
    # mapping from: https://ouimeaux.readthedocs.io/en/latest/_modules/ouimeaux/device/insight.html
    foreach my $f (qw(state lastchange onfor ontoday ontotal timeperiod unknown currentmw todaymw totalmw powerthreshold))
    {
      $d{$f} = int(shift(@d)*1);
      #printf("%-20s ... %d\n", $f, $d{$f});
    }

    ### stuff i dont care about ###
    foreach my $f (qw(state lastchange timeperiod unknown powerthreshold))
    {
      delete($d{$f});
    }

    foreach my $f (sort(keys(%d)))
    {
      printf("%s:  %-20s ... %d\n", $wemo, $f, $d{$f});
    }

    if($ARGV[0] ne 'test')
    {
      $wup->record(host => $wemo, app => 'wemo', %d);
    }
  }
}


exit 0;
