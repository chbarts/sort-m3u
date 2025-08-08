#!/usr/bin/perl -w

use strict;

my $lns = "";
my $flag = 0;
my $uniq = 0;
my @arr;

if ((scalar @ARGV) >= 1) {
    if ($ARGV[0] eq "-u") {
        $uniq = 1;
        shift @ARGV;
    } elsif (($ARGV[0] eq "-h") or ($ARGV[0] eq "--help")) {
        print "usage: sort-m3u [-u] [FILES...]\n";
        print "-u means only print one of duplicate lines (uniquify output)\n";
        exit(0);
    }
}

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
            $lns = $lns . "\n" . $_;
        }

        next LINE;
    }

    if (length($lns) == 0) {
        push @arr, $_;
    } else {
        $lns = $lns . "\n" . $_;
        push @arr, $lns;
        $lns = "";
    }
}

@arr = sort @arr;

if ($uniq == 1) {
    my $lst = "";
    for my $i (@arr) {
        if ($i ne $lst) {
            print "$i\n";
            $lst = $i;
        }
    }

} else {
    for my $i (@arr) {
        print "$i\n";
    }
}
