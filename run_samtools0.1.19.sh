#!/bin/sh

file=${@+"$@"}

export CACHE=lc; export THREADS=8; FORMATS="sam bam" ./samtools0.1.19_bench.sh $file $CACHE 2>&1 | tee $file.${CACHE}${THREADS}
export CACHE=pc; export THREADS=8; FORMATS="sam bam" ./samtools0.1.19_bench.sh $file $CACHE 2>&1 | tee $file.${CACHE}${THREADS}
export CACHE=lc; export THREADS=0; FORMATS="sam bam" ./samtools0.1.19_bench.sh $file $CACHE 2>&1 | tee $file.${CACHE}${THREADS}
export CACHE=pc; export THREADS=0; FORMATS="sam bam" ./samtools0.1.19_bench.sh $file $CACHE 2>&1 | tee $file.${CACHE}${THREADS}

