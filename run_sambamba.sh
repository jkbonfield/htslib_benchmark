#!/bin/sh

file=${@+"$@"}

export FORMATS="sam bam cram"
export REF=Homo_sapiens.GRCh38_full_analysis_set_plus_decoy_hla.fa
export CACHE=lc; export THREADS=8; ./sambamba_bench.sh $file $CACHE 2>&1 | tee $file.sambamba.${CACHE}${THREADS}
export CACHE=pc; export THREADS=8; ./sambamba_bench.sh $file $CACHE 2>&1 | tee $file.sambamba.${CACHE}${THREADS}
export CACHE=lc; export THREADS=0; ./sambamba_bench.sh $file $CACHE 2>&1 | tee $file.sambamba.${CACHE}${THREADS}
export CACHE=pc; export THREADS=0; ./sambamba_bench.sh $file $CACHE 2>&1 | tee $file.sambamba.${CACHE}${THREADS}

