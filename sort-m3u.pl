#!/usr/bin/perl -w

use strict;
use v5.16;

my $lns = "";
my $flag = 0;
my $uniq = 0;
my $trim = 0;
my $case = 0;
my @arr;

if ((scalar @ARGV) >= 1) {
    if (($ARGV[0] eq "-h") or ($ARGV[0] eq "--help")) {
        print "usage: sort-m3u [-u] [-t] [-c] [FILES...]\n";
        print "-u means only print one of duplicate lines (uniquify output)\n";
        print "-t means trim the identification portion of the M3U record\n";
        print "-c means sort case-insensitively\n";
        exit(0);
    }

    if ($ARGV[0] eq "-u") {
        $uniq = 1;
        shift @ARGV;
    }

    if ($ARGV[0] eq "-t") {
        $trim = 1;
        shift @ARGV;
    }

    if ($ARGV[0] eq "-c") {
        $case = 1;
        shift @ARGV;
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

sub proc { my $s = shift; $s =~ /^#EXTINF:[^,]+,(.+)/; return $1; };
# https://perlmaven.com/trim
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

if (($trim == 1) and ($case == 1)) {
    @arr = sort { fc(trim(proc($a))) cmp fc(trim(proc($b))) } @arr;
} elsif ($trim == 1) {
    @arr = sort { trim(proc($a)) cmp trim(proc($b)) } @arr;
} elsif ($case == 1) {
    @arr = sort { fc(proc($a)) cmp fc(proc($b)) } @arr;
} else {
    @arr = sort { proc($a) cmp proc($b) } @arr;
}

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
