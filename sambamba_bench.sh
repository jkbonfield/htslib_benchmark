#!/bin/sh

time="real %e\tuser %U\tsys %S\tmem %M\texit %x"
sambamba=${SAMBAMBA:-/home/ubuntu/sambamba-0.7.1-linux-static}
ref=${REF:-Homo_sapiens.GRCh38_full_analysis_set_plus_decoy_hla.fa}

file=$1
cache=$2
threads=${THREADS:-0}
echo "Threads: $threads"
echo "Input:   $file"
echo "Seqs:    `$sambamba view -t8 -c $file -q`"
echo

purge_cache() {
    sudo bash -c 'sync;echo 3 > /proc/sys/vm/drop_caches'
}

load_cache() {
    echo -n "< INPUT\t"
    /usr/bin/time -f "$time" bash -c "$sambamba view -t$threads -c -F supplementary ${@+"$@"} >/dev/null -q"
}

fmts=${FORMATS:-sam bam cram}
for fmt in $fmts
do
    load_cache $file
    load_cache $file
    f=$fmt

    tv_fmt=""
    case $fmt in
	sam)    tv_out_fmt="-f sam";  tv_in_fmt="-S";;
	bam)    tv_out_fmt="-f bam";  tv_in_fmt="";;
	cram)   tv_out_fmt="-f cram"; tv_in_fmt="-C";;
    esac
    

    # For write test we always cache input data, as we want to subtract
    # input decode time from transcode time.

    # First encode is to /dev/null, to benchmark algorithm.
    echo -n "> $fmt\t"
    /usr/bin/time -f "$time" bash -c "$sambamba view -t$threads -T $ref -h $tv_out_fmt $file -o /dev/null -q"

    # Second time to file so we can do the decode speed tests
    echo -n "] $fmt\t"
    /usr/bin/time -f "$time" bash -c "$sambamba view -t$threads -T $ref -h $tv_out_fmt -o $file.$fmt $file -q"

    # View -c works OK for BAM, but for SAM it's got some custom code which
    # is more akin to wc -l.  Hence it's not a good proxy for the real
    # decode rate.  The filter option causes it to do a proper parse though.
    # BAM CPU with and without -F "supplementary" are 1m15.7 vs 1m16.8s.
    # Close enough.
    #
    # As soon as we actually have to ingest SAM though rather than line-count
    # it's entirely different. (-t16 runs)
    #
    # BAM: view -c          real 0m5s,  user 1m16s, sys 0m1s
    # BAM: view -f bam -l0  real 0m18s, user 2m27s, sys 1m7s
    #
    # SAM: view -c          real 0m10s, user 0m4s,  sys 0m7s
    # SAM: view -f bam -l0  real 1m54s, user 2m24s, sys 0m45s
    #
    # Obviously the BAM output is adding a lot, even at level 0 (CRC needed),
    # but that should be constant for BAM and SAM (~2min cpu).
    # => SAM parser does not multi-thread.  Similarly -F suppmenentary:
    #
    # BAM view -c -F supp   real 0m6s,  user 1m17s, sys 0m3s
    # SAM view -c -F supp   real 1m36,  user 1m29,  sys 0m7s (same as -t0)

    for rep in `seq 1 3`
    do
	# Time READ.  Should be in cache atm
	[ "$cache" = "pc" ] && purge_cache
	echo -n "< $fmt\t"
	/usr/bin/time -f "$time" bash -c "$sambamba view -t$threads $tv_in_fmt -c -F supplementary $file.$fmt >/dev/null -q"
    done
    
    if [ $fmt != "sam" ]
    then
        for rep in `seq 1 3`
        do
            # Time INDEX.  Should be in cache atm
            [ "$cache" = "pc" ] && purge_cache
            echo -n "I $fmt\t"
	    # No threaded decode in 0.1.19
            /usr/bin/time -f "$time" bash -c "$sambamba index -t$threads $file.$fmt -q"
        done
    fi

    ls -l $file.$fmt
#    rm $file.$fmt
#    rm $file.$fmt.bai $file.$fmt.csi $file.$fmt.crai 2>/dev/null
    echo
done
