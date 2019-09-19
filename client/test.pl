#!/usr/bin/env perl

use Cwd;
use lib (Cwd::abs_path(__FILE__.'/..'));

use Whatsup;

use strict;


my ($r, $c) = Whatsup->record(app => 'test', ping => 1);
print("result:\t$r\n");
print("content:\t$c\n");
