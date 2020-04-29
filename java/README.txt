SAM/BAM/CRAM
------------

javac -cp picard.jar TestBamRead.java 
java -cp picard.jar:. TestBamRead in.bam


VCF/BCF
-------

Input *must* be tabix indexed.  Why do we need an index just to
iterate through the entire file?  Baffling.

javac -cp ~/work/picard.jar TestVcfRead.java
java -cp ~/work/picard.jar:. TestVcfRead in.vcf.gz
