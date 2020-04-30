#!/bin/sh

# Usage: script.sh <BAM/CRAM file> <regions.bed> | tee out.txt

file=$1
bed=$2

io_trace=$HOME/io_trace/io_trace
samtools=$HOME/samtools/samtools

time="real %e\tuser %U\tsys %S\tmem %M\texit %x"

purge_cache() {
    sudo bash -c 'sync;echo 3 > /proc/sys/vm/drop_caches'
}

# Time it
purge_cache
/usr/bin/time -f "$time" $samtools view -c -M -L $bed $file 

# Repeat, measuring I/O this time
$io_trace -x -S -r $file -r hts-ref -- $samtools view -c -M -L $bed $file
