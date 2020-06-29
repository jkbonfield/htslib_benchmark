#!/bin/sh

time="real %e  user %U  sys %S  mem %M  exit %x"
bcftools=${BCFTOOLS:-bcftools}

file=$1

echo "Input:   $file"
echo "Program: $bcftools"

# Index
echo -n "I $file\t"
case $file in
    *vcf.gz) echo "Not supported";;
    *bcf)    /usr/bin/time -f "$time" $bcftools index $iopt $file;;
esac

# Read
echo -n "< $file\t"
# NB: view -B is a hacked option, added for this paper.
case $file in
    *vcf.gz) /usr/bin/time -f "$time" $bcftools view -S -B $file;;
    *bcf)    /usr/bin/time -f "$time" $bcftools view -B $file;;
esac

# Read/Write
case $file in
    *vcf.gz) uopt="-S" ;;
    *bcf)    zopt="-b"; uopt="-bu" ;;
esac

echo -n "> $file $uopt\t"
/usr/bin/time -f "$time" $bcftools view $uopt $file > _
ls -l _
if [ "$zopt" != "" ]
then
    echo -n "> $file $zopt\t"
    /usr/bin/time -f "$time" $bcftools view $zopt $file > _
    ls -l _
fi


