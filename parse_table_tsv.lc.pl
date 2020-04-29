#!/usr/bin/perl -w
use strict;

# Extract < INPUT lines to get the input read speed.
# Subtract this from the > $fmt lines to get the encode speed.

my $nseqs = 1;
#my $decode_time = 0;
my $decode_time;
my $ndecode = 0;


my $file = "";
my $fmt = "";
my %enc; # per format
my %dec;
my %idx;
my %size;

while (<>) {
    $nseqs = $1 if (/^Seqs:\s+(\d+)/);
    $file  = $1 if (/^Input:\s+(\S+)/);
    if (/^< INPUT\treal ([\d.]+)/) {
	$decode_time = $1 if (!defined $decode_time || $decode_time > $1);
	# $decode_time += $1;
	# $ndecode++;
    }
    if (/^[\]>] (\S+)\treal ([\d.]+)/) {
    #if (/^[\]] (\S+)\treal ([\d.]+)/) {
	$enc{$1} = $2 if (!defined $enc{$1} || $enc{$1} > $2);
	$fmt=$1;
    }
    if (/^< (\S+)\treal ([\d.]+)/) {
	$dec{$1} = $2 if (!defined $dec{$1} || $dec{$1} > $2);
    }
    if (/^I (\S+)\treal ([\d.]+)/) {
	$idx{$1} = $2 if (!defined $idx{$1} || $idx{$1} > $2);
    }
    if (/-rw-rw-/) {
	my @F = split(/\s+/, $_);
	$size{$fmt}=$F[4];
    }
}

# $decode_time /= $ndecode;

print "### $file\t$nseqs\n";
print "### baseline decode time\t$decode_time\n\n";
printf("FORMAT\tENCODE s\tDECODE s\tINDEX s\tSIZE Mb\n");
foreach (sort keys %enc) {
    $idx{$_} = 0 if (!defined($idx{$_}));
    printf("%-s\t%.2f\t%.2f\t%.2f\t%d\n",
	   $_, $enc{$_}, $dec{$_}, $idx{$_}, int($size{$_}/1000000+.5));
}

print "\n";
printf("FORMAT\tTRANSCODE K/s\tENCODE K/s\tDECODE K/s\tINDEX K/s\tSIZE Mb\n");
foreach (sort keys %enc) {
    printf("%-s\t%d\t%d\t%d\t%d\t%d\n", $_,
	   $nseqs/$enc{$_}/1000+.5,
	   $nseqs/($enc{$_}-$decode_time)/1000+.5,
	   $nseqs/$dec{$_}/1000+.5,
	   $nseqs/($idx{$_}?$idx{$_}:1e99)/1000+.5,
	   $size{$_}/1000000+.5);
}
