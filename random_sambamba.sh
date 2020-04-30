#!/bin/sh

# Usage: script.sh <BAM/CRAM file> <regions.bed> | tee out.txt

file=$1
bed=$2

io_trace=$HOME/io_trace/io_trace
sambamba=$HOME/sambamba-0.7.1-linux-static
THREADS=${THREADS:-0}

time="real %e\tuser %U\tsys %S\tmem %M\texit %x"

purge_cache() {
    sudo bash -c 'sync;echo 3 > /proc/sys/vm/drop_caches'
}

fmt=""
case $file in
    *cram) fmt="-C"
esac

# Time it
purge_cache
/usr/bin/time -f "$time" $sambamba view -q $fmt -t$THREADS -c -L $bed $file 

# Repeat, measuring I/O this time
$io_trace -x -S -r $file -r hts-ref -- $sambamba view -q $fmt -t$THREADS -c -L $bed $file
