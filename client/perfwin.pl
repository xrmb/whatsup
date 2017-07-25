#!perl

use Win32::OLE;
use Win32::API;
use Cwd;
use Math::Int64;

use lib (__FILE__.'/..');
use Whatsup;

use strict;


if($ARGV[0] eq 'create') { exit system(qq|schtasks /create /tn "$ARGV[1]\\whatsup\\perf" /sc minute /mo 5 /tr "$^X |.Cwd::abs_path(__FILE__).qq|"|); }
if($ARGV[0] eq 'delete') { exit system(qq|schtasks /delete /tn "$ARGV[1]\\whatsup\\perf"|); }


my %whatsup;


### uptime ###
my $gtc = Win32::API->new('kernel32', 'GetTickCount64', '', 'Q') || die;
#$gtc->UseMI64(1);
$whatsup{uptime} = int(substr($gtc->Call(), 0, -3));


### mem used ###
my $wmi = Win32::OLE->GetObject("winmgmts://./root/cimv2") or die;
my $list = $wmi->InstancesOf("Win32_OperatingSystem") or die;

foreach my $v (in $list)
{
  $whatsup{total_mem} = $v->{TotalVisibleMemorySize};
  $whatsup{used_mem} = $v->{TotalVisibleMemorySize} - $v->{FreePhysicalMemory};
}


### cpu used ###
my $samples = 5;
my @data;
for my $sample (0..$samples)
{
  printf("cpu sample:\t%d\n", $sample);

  if($sample) { sleep(1); }

  my $list = $wmi->InstancesOf('Win32_PerfRawData_PerfOS_Processor') or die;

  my @properties = qw(PercentProcessorTime TimeStamp_Sys100NS);

  my $hash = {};
  foreach my $v (in $list)
  {
    map { $hash->{$v->{Name}}{$_} = $v->{$_} } @properties;
  }

  push(@data, $hash);
}

for my $sample (1..$samples)
{
  my $h1 = $data[$sample-1]{_Total};
  my $h2 = $data[$sample]{_Total};

  $whatsup{used_cpu} += (100/$samples)*(1-(($h2->{PercentProcessorTime} - $h1->{PercentProcessorTime})/($h2->{TimeStamp_Sys100NS}-$h1->{TimeStamp_Sys100NS})));
}

$whatsup{used_cpu} = int($whatsup{used_cpu});

printf("\nuptime:\t\t%d days %d hours %d minutes %d seconds\n", $whatsup{uptime}/(24*60*60), $whatsup{uptime}/(60*60) % 24, $whatsup{uptime}/60 % 60, $whatsup{uptime} % 60);
printf("total_mem:\t%d\nused_mem:\t%d\nused_cpu:\t%d\n", $whatsup{total_mem}, $whatsup{used_mem}, $whatsup{used_cpu});
printf("\nresult:\t%d\n", Whatsup->record(app => 'perf', %whatsup));

exit 0;
