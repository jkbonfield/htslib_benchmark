#!/bin/sh

# Usage: script.sh <BAM/CRAM file> <ref.fa> <intervals.list> | tee out.txt

file=$1
ref=$2
intervals=$3

io_trace=$HOME/io_trace/io_trace
java_opts=-Xmx8g

time="real %e\tuser %U\tsys %S\tmem %M\texit %x"

purge_cache() {
    sudo bash -c 'sync;echo 3 > /proc/sys/vm/drop_caches'
}

# Time it
purge_cache
/usr/bin/time -f "$time" java $java_opts -cp picard.jar:. TestBamReadIntervals $file $ref $intervals

# Repeat, measuring I/O this time
$io_trace -x -S -r $file -r hts-ref -- java $java_opts -cp picard.jar:. TestBamReadIntervals $file $ref $intervals
