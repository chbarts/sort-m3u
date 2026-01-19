#!/usr/bin/perl -w

use strict;
use v5.16;

my $lns = "";
my $flag = 0;
my $uniq = 0;
my $trim = 0;
my $case = 0;
my $key = undef;
my @arr;

PARSE: while ((scalar @ARGV) >= 1) {
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
        last PARSE;
    } else {
        last PARSE;
    }
}

sub proc { my $s = shift; my $res = ""; $s =~ /^#EXTINF:[^,]+,(.+)/; $res = $1; my @arr = split /\n/, $s; return ($res . " " . $arr[-1]) }
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

             my @arr = split /\n/, $s;
             my $url = $arr[-1];

             if (exists $res{$k}) {
                 return ($res{$k} . " " . $url);
             } else {
                 return proc($s);
             }
         }

sub condition { my $s = shift;
                my $key = shift;

                if (($trim == 1) and ($case == 1) and $key) {
                    return fc(trim(getkey($s, $key)));
                } elsif (($trim == 1) and ($case == 1)) {
                    return fc(trim(proc($s)));
                } elsif (($trim == 1) and $key) {
                    return trim(getkey($s, $key));
                } elsif (($case == 1) and $key) {
                    return fc(getkey($s, $key));
                } elsif ($trim == 1) {
                    return trim(proc($s));
                } elsif ($case == 1) {
                    return fc(proc($s));
                } elsif ($key) {
                    return getkey($s, $key);
                } else {
                    return proc($s);
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
        push @arr, (condition($_, $key) . "\x00" . $_);
    } else {
        $lns = $lns . "\n" . $_;
        push @arr, (condition($lns, $key) . "\x00" . $lns);
        $lns = "";
    }
}

if ($uniq == 1) {
    my $lst = "";
    for my $i (@arr) {
        my @arr = split /\x00/, $i;
        $c = $arr[0];
        if ($c ne $lst) {
            print ($arr[1] . "\n");
            $lst = $c;
        }
    }

} else {
    for my $i (@arr) {
        my @arr = split /\x00/, $i;
        print ($arr[1] . "\n");
    }
}
