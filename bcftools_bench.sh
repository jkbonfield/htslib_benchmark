#!/bin/sh

time="real %e\tuser %U\tsys %S\tmem %M\texit %x"
bcftools=${BCFTOOLS:-bcftools}

file=$1

echo "Input:   $file"
echo "Program: $bcftools"

# Index
echo -n "I $file\t"
case $file in
    *vcf.gz) iopt="-t" ;; # Tabix
    *bcf)    iopt="-c" ;; # CSI
esac
/usr/bin/time -f "$time" $bcftools index -f $iopt $file

# Read
echo -n "< $file\t"
# min-alleles as a filter to produce no output.
# Validated as broadly identical times to test_view -B.
# 1m21.9 vs 1m12.5 on a test, so within expected variability
# between test runs.
/usr/bin/time -f "$time" $bcftools view -H -m 999 $file

# Fully read.  Phased only (which none are).
# This forces FORMAT field to be decoded too.
# It has a bit of speed impact compared to pure decode, but not huge
# (~2%).
echo -n "<< $file\t"
/usr/bin/time -f "$time" $bcftools view -H -p $file


# Read/Write
case $file in
    *vcf.gz) zopt="-Oz"; uopt="-Ov" ;;
    *bcf)    zopt="-Ob"; uopt="-Ou" ;;
esac

echo -n "> $file $uopt\t"
/usr/bin/time -f "$time" $bcftools view $uopt $file -o _
ls -l _
echo -n "> $file $zopt\t"
/usr/bin/time -f "$time" $bcftools view $zopt $file -o _
ls -l _

