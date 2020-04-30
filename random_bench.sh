#!/bin/sh

# # Test
# ../random_htslib.sh ../NA06985.final.chr1.bam 100.bed 2>&1 | tee ../random_htslib_genes.txt
# ../random_sambamba.sh ../NA06985.final.chr1.bam 100.bed 2>&1 | tee ../random_sambamba_genes.txt
# ../random_htsjdk.sh ../NA06985.final.chr1.bam chr1.fa 100.list 2>&1 | tee ../random_htsjdk_genes.txt
# exit

for file in ../NA06985.final.chr1.bam ../NA06985.final.chr1.1k.cram ../NA06985.final.chr1.cram
do
    fmt=`echo $file | sed 's/.*final.chr1.//'`

    # Ran from java_test dir
    echo; echo === $file htslib genes
    ../random_htslib.sh $file genes.bed 2>&1 | tee ../random_htslib_genes.$fmt.txt
    echo; echo === $file htslib exons
    ../random_htslib.sh $file exons.bed 2>&1 | tee ../random_htslib_exons.$fmt.txt

    echo; echo === $file sambamba genes
    ../random_sambamba.sh $file genes.bed 2>&1 | tee ../random_sambamba_genes.$fmt.txt
    echo; echo === $file sambamba exons
    ../random_sambamba.sh $file exons.bed 2>&1 | tee ../random_sambamba_exons.$fmt.txt

    echo; echo === $file htsjdk genes
    ../random_htsjdk.sh $file chr1.fa genes.list 2>&1 | tee ../random_htsjdk_genes.$fmt.txt
    echo; echo === $file htsjdk exons
    ../random_htsjdk.sh $file chr1.fa exons.list 2>&1 | tee ../random_htsjdk_exons.$fmt.txt

done

