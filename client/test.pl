#!perl

use strict;

use Whatsup;

my ($r, $c) = Whatsup->record(app => 'test', ping => 1);
print("result:\t$r\n");
print("content:\t$c\n");
