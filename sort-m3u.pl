#!/usr/bin/perl -w

use strict;
use v5.16;

my $lns = "";
my $flag = 0;
my $uniq = 0;
my $trim = 0;
my $case = 0;
my $key = "";
my @arr;

while ((scalar @ARGV) >= 1) {
    if (($ARGV[0] eq "-h") or ($ARGV[0] eq "--help")) {
        print "usage: sort-m3u [-u] [-t] [-c] [-k KEY] [FILES...]\n";
        print "-u means only print one of duplicate lines (uniquify output)\n";
        print "-t means trim the identification portion of the M3U record\n";
        print "-c means sort case-insensitively\n";
        print "-k KEY means sort by value of key in EXTINF information; otherwise, sort by channel name (portion after comma) (also sort by that if key does not exist in some channel)\n";
        print "-- means stop processing options and treat everything else as a filename\n";
        exit(0);
    } elsif ($ARGV[0] eq "-u") {
        $uniq = 1;
        shift @ARGV;
    } elsif ($ARGV[0] eq "-t") {
        $trim = 1;
        shift @ARGV;
    } elsif ($ARGV[0] eq "-c") {
        $case = 1;
        shift @ARGV;
    } elsif ($ARGV[0] eq "-k") {
        shift @ARGV;
        $key = shift @ARGV;
    } elsif ($ARGV[0] eq "--") {
        shift @ARGV;
        break;
    } else {
        break;
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

sub proc { my $s = shift; $s =~ /^#EXTINF:[^,]+,(.+)/; return $1; }
# https://perlmaven.com/trim
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s }

sub getkey { my $s = shift;
             my $k = shift;
             my %res;
             $s =~ /^#EXTINF:[-0-9]+\s+(.+)/;
             my $head = $1;
             while ($head =~ /([-[:alnum:]]+="[^"]+")\s*(.*)/) {
                 my $kv = $1;
                 $head = $2;
                 $kv =~ /([-[:alnum:]]+)="([^"]+)"/;
                 $res{$1} = $2;
             }

             if (exists $res{$k}) {
                 return $res{$k};
             } else {
                 return proc($s);
             }
         }

if (($trim == 1) and ($case == 1) and (length($key) > 0)) {
    @arr = sort { fc(trim(getkey($a, $key))) cmp fc(trim(getkey($b, $key))) } @arr;
} elsif (($trim == 1) and ($case == 1)) {
    @arr = sort { fc(trim(proc($a))) cmp fc(trim(proc($b))) } @arr;
} elsif (($trim == 1) and (length($key) > 0)) {
    @arr = sort { trim(getkey($a, $key)) cmp trim(getkey($b, $key)) } @arr;
} elsif (($case == 1) and (length($key) > 0)) {
    @arr = sort { fc(getkey($a, $key)) cmp fc(getkey($b, $key)) } @arr;
} elsif ($trim == 1) {
    @arr = sort { trim(proc($a)) cmp trim(proc($b)) } @arr;
} elsif ($case == 1) {
    @arr = sort { fc(proc($a)) cmp fc(proc($b)) } @arr;
} elsif (length($key) > 0) {
    @arr = sort { getkey($a, $key) cmp getkey($b, $key) } @arr;
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
