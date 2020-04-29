#!/bin/sh

time="real %e\tuser %U\tsys %S\tmem %M\texit %x"
scramble=${SCRAMBLE:-/home/ubuntu/io_lib/progs/scramble}
flagstat=${SCRAM_FLAGSTAT:-/home/ubuntu/io_lib/progs/scram_flagstat}
index=${CRAM_INDEX:-/home/ubuntu/io_lib/progs/cram_index}
samtools=${SAMTOOLS:-/home/ubuntu/samtools/samtools}
ref=${REF:-Homo_sapiens.GRCh38_full_analysis_set_plus_decoy_hla.fa}

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
    /usr/bin/time -f "$time" $flagstat -t$threads -b ${@+"$@"} >/dev/null
}

#fmts=${FORMATS:-sam sam.gz bam bam.u cram30 cram31 cram30.u cram31.u cram40 cram40.u}

fmts=${FORMATS:-sam bam cram30 cram31 cram40}
for fmt in $fmts
do
    load_cache $file
    load_cache $file

    tv_fmt=""
    tv_opt=""
    case $fmt in
	sam)    tv_fmt="-O sam";;
	bam)    tv_fmt="-O bam";;
	cram)   tv_fmt="-O cram";;
	cram30) tv_fmt="-O cram"; tv_opt="-V 3.0"$;;
	cram31) tv_fmt="-O cram"; tv_opt="-V 3.1"$;;
	cram40) tv_fmt="-O cram"; tv_opt="-V 4.0"$;;
    esac
    
    # For write test we always cache input data, as we want to subtract
    # input decode time from transcode time.

    # First encode is to /dev/null, to benchmark algorithm.
    echo -n "> $fmt\t"
    /usr/bin/time -f "$time" bash -c "$scramble -r $ref -t$threads $tv_fmt $tv_opt $file > /dev/null 2>/dev/null"

    # Second time to file so we can do the decode speed tests
    echo -n "] $fmt\t"
    /usr/bin/time -f "$time" bash -c "$scramble -r $ref -t$threads $tv_fmt $tv_opt $file $file.$fmt 2>/dev/null"

    for rep in `seq 1 3`
    do
	# Time READ.  Should be in cache atm
	[ "$cache" = "pc" ] && purge_cache
	echo -n "< $fmt\t"
	/usr/bin/time -f "$time" $flagstat -t$threads -b $file.$fmt >/dev/null
    done

    if expr "$fmt" : "cram.*" > /dev/null
    then
	for rep in `seq 1 3`
	do
	    # Time INDEX.  Should be in cache atm
	    [ "$cache" = "pc" ] && purge_cache
	    echo -n "I $fmt\t"
	    #/usr/bin/time -f "$time" $index -t$threads $file.$fmt
	    /usr/bin/time -f "$time" $index $file.$fmt
	done
    fi

    ls -l $file.$fmt
    rm $file.$fmt
    rm $file.$fmt.bai $file.$fmt.csi $file.$fmt.crai 2>/dev/null

    echo
done
