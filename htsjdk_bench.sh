#!/bin/sh

time="real %e\tuser %U\tsys %S\tmem %M\texit %x"
test_view=${TEST_VIEW:-/home/ubuntu/htslib/test/test_view}
samtools=${SAMTOOLS:-/home/ubuntu/samtools/samtools}
ref=${REF:-../Homo_sapiens.GRCh38_full_analysis_set_plus_decoy_hla.fa}
htsjdk=${HTSJDK:-$HOME/htsjdk/build/libs/htsjdk-2.22.0-SNAPSHOT.jar}
picard=${PICARD:-picard.jar}

java_opts=-Xmx8g

file=$1
cache=$2
threads=${THREADS:-0}
echo "Threads: $threads"
echo "Input:   $file"
echo "Seqs:    `$samtools view -@8 -c $file`"
echo

if [ "$threads" != "0" ]
then
    java_opts="$java_opts -Dsamjdk.use_async_io_read_samtools=true -Dsamjdk.use_async_io_write_samtools=true"
fi


purge_cache() {
    sudo bash -c 'sync;echo 3 > /proc/sys/vm/drop_caches'
}

load_cache() {
    echo -n "< INPUT\t"
    /usr/bin/time -f "$time" bash -c "java $java_opts -cp $htsjdk:. TestBamRead $file $ref >/dev/null"
}



# Unknown how to do sam.gz.  It appears to end up as BAM, so skip.

fmts=${FORMATS:-sam bam cram}
for fmt in $fmts
do
    load_cache $file; # first may not be in case
    load_cache $file; # cached time for loading input

    # For write test we always cache input data, as we want to subtract
    # input decode time from transcode time.

#    # First encode is to /dev/null, to benchmark algorithm.
#    # Use of bash -c to muzzle chatty programs.
#    echo -n "> $fmt\t"
#    /usr/bin/time -f "$time" bash -c "java $java_opts -cp $htsjdk:. TestBamReadWrite $file /dev/null $ref 2>/dev/null"

    # Second time to file so we can do the decode speed tests
    echo -n "] $fmt\t"
    /usr/bin/time -f "$time" bash -c "java $java_opts -cp $htsjdk:. TestBamReadWrite $file $file.$fmt $ref 2>/dev/null"

    for rep in `seq 1 3`
    do
	# Time READ.  Should be in cache atm
	[ "$cache" = "pc" ] && purge_cache
	echo -n "< $fmt\t"
	/usr/bin/time -f "$time" bash -c "java $java_opts -cp $htsjdk:. TestBamRead $file.$fmt $ref >/dev/null"
    done

    if [ $fmt != "sam" ]
    then
	for rep in `seq 1 3`
	do
	    # Time INDEX.  Should be in cache atm
	    [ "$cache" = "pc" ] && purge_cache
	    echo -n "I $fmt\t"
	    /usr/bin/time -f "$time" bash -c "java $java_opts -jar $picard BuildBamIndex I=$file.$fmt VERBOSITY=ERROR QUIET=true VALIDATION_STRINGENCY=SILENT 2>/dev/null"
	done
    fi

    ls -l $file.$fmt
    rm $file.$fmt
    rm $file.$fmt.bai $file.$fmt.csi $file.$fmt.crai 2>/dev/null

    echo

done
