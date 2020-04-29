#!/bin/sh

time="real %e\tuser %U\tsys %S\tmem %M\texit %x"
test_view=${TEST_VIEW:-/home/ubuntu/htslib/test/test_view}
samtools=${SAMTOOLS:-/home/ubuntu/samtools/samtools}

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
    /usr/bin/time -f "$time" $test_view -@$threads -B ${@+"$@"} >/dev/null
}

#fmts=${FORMATS:-sam sam.gz bam bam.u cram30 cram31 cram30.u cram31.u cram40 cram40.u}

fmts=${FORMATS:-sam sam.gz bam cram30 cram31 cram40}
for fmt in $fmts
do
    load_cache $file
    load_cache $file
    f=`echo $fmt | sed 's/cram30/cram,version=3.0/;\
                        s/cram31/cram,version=3.1/;\
                        s/cram40/cram,version=4.0/;\
                        s/\.u$/,level=0/'`

    tv_fmt=""
    tv_opt=""
    case $fmt in
	sam)    ;;
	sam.gz) tv_fmt="-z";;
	bam)    tv_fmt="-b";;
	cram)   tv_fmt="-C";;
	cram30) tv_fmt="-C"; tv_opt="-o version=3.0"$;;
	cram31) tv_fmt="-C"; tv_opt="-o version=3.1"$;;
	cram40) tv_fmt="-C"; tv_opt="-o version=4.0"$;;
    esac
    
    # For write test we always cache input data, as we want to subtract
    # input decode time from transcode time.

    # First encode is to /dev/null, to benchmark algorithm.
    echo -n "> $fmt\t"
    /usr/bin/time -f "$time" $test_view -@$threads $tv_fmt $tv_opt $file > /dev/null

    # Second time to file so we can do the decode speed tests
    echo -n "] $fmt\t"
    /usr/bin/time -f "$time" $test_view -@$threads $tv_fmt $tv_opt -p $file.$fmt $file

    for rep in `seq 1 3`
    do
	# Time READ.  Should be in cache atm
	[ "$cache" = "pc" ] && purge_cache
	echo -n "< $fmt\t"
	/usr/bin/time -f "$time" $test_view -@$threads -B $file.$fmt >/dev/null
    done

    if [ $fmt != "sam" ]
    then
	for rep in `seq 1 3`
	do
	    # Time INDEX.  Should be in cache atm
	    [ "$cache" = "pc" ] && purge_cache
	    echo -n "I $fmt\t"
	    /usr/bin/time -f "$time" $samtools index -@$threads $file.$fmt
	done
    fi

    ls -l $file.$fmt
    rm $file.$fmt
    rm $file.$fmt.bai $file.$fmt.csi $file.$fmt.crai 2>/dev/null

    echo
done
