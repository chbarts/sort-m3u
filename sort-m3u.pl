#!/usr/bin/perl -w

use strict;

my $lns = "";
my $flag = 0;
my @arr;

LINE: while (<>) {
    chomp;
    if ($_ =~ /^#EXTM3U/) {
        if ($flag == 0) {
            print "$_\n";
            $flag = 1;
        }

        next LINE;
    }

    if ($_ =~ /^#.+/) {
        if (length($lns) == 0) {
            $lns = $_;
        } else {
            $lns = $lns . "\t" . $_;
        }

        next LINE;
    }

    if (length($lns) == 0) {
        push @arr, $_;
    } else {
        $lns = $lns . "\t" . $_;
        push @arr, $lns;
        $lns = "";
    }
}

@arr = sort @arr;

for my $i (@arr) {
    $i =~ s{\t}{\n}g;
    print "$i\n";
}
