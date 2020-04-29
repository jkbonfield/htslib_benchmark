#!/bin/sh

# NB: do not use on CRAM.
# Samtools view -c takes shortcuts as it doesn't need to decode much.

time="real %e\tuser %U\tsys %S\tmem %M\texit %x"
samtools=${SAMTOOLS:-/home/ubuntu/samtools-0.1.19/samtools}

file=$1
cache=$2
threads=${THREADS:-0}
echo "Threads: $threads"
echo "Input:   $file"
echo "Seqs:    `$samtools view -@8 -c $file`"
echo

purge_cache() {
    sudo bash -c 'sync;echo 3 > /proc/sys/vm/drop_caches'
}

load_cache() {
    echo -n "< INPUT\t"
    /usr/bin/time -f "$time" $samtools view -@$threads -c ${@+"$@"} >/dev/null
}

#fmts=${FORMATS:-sam sam.gz bam bam.u cram30 cram31 cram30.u cram31.u cram40 cram40.u}

fmts=${FORMATS:-sam bam}
for fmt in $fmts
do
    load_cache $file
    load_cache $file
    f=`echo $fmt | sed 's/cram30/cram,version=3.0/;\
                        s/cram31/cram,version=3.1/;\
                        s/cram40/cram,version=4.0/;\
                        s/\.u$/,level=0/'`

    tv_fmt=""
    case $fmt in
	sam)    tv_out_fmt=""; tv_in_fmt="-S";;
	bam)    tv_out_fmt="-b"; tv_in_fmt="";;
    esac
    

    # For write test we always cache input data, as we want to subtract
    # input decode time from transcode time.

    # First encode is to /dev/null, to benchmark algorithm.
    echo -n "> $fmt\t"
    /usr/bin/time -f "$time" $samtools view -@$threads -h $tv_out_fmt $file > /dev/null

    # Second time to file so we can do the decode speed tests
    echo -n "] $fmt\t"
    /usr/bin/time -f "$time" $samtools view -@$threads -h $tv_out_fmt -o $file.$fmt $file

    for rep in `seq 1 3`
    do
	# Time READ.  Should be in cache atm
	[ "$cache" = "pc" ] && purge_cache
	echo -n "< $fmt\t"
	# No threaded decode in 0.1.19
	/usr/bin/time -f "$time" $samtools view $tv_in_fmt -c $file.$fmt >/dev/null
    done
    
    if [ $fmt = "bam" ]
    then
        for rep in `seq 1 3`
        do
            # Time INDEX.  Should be in cache atm
            [ "$cache" = "pc" ] && purge_cache
            echo -n "I $fmt\t"
	    # No threaded decode in 0.1.19
            /usr/bin/time -f "$time" $samtools index $file.$fmt
        done
    fi

    ls -l $file.$fmt
#    rm $file.$fmt
#    rm $file.$fmt.bai $file.$fmt.csi $file.$fmt.crai 2>/dev/null
    echo
done
