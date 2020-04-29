// See https://www.programcreek.com/java-api-examples/?code=broadinstitute/picard/picard-master/src/main/java/picard/vcf/SortVcf.java

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;

import htsjdk.variant.variantcontext.VariantContext;
import htsjdk.variant.variantcontext.writer.Options;
import htsjdk.variant.variantcontext.writer.VariantContextWriter;
import htsjdk.variant.variantcontext.writer.VariantContextWriterBuilder;
import htsjdk.variant.vcf.VCFFileReader;
import htsjdk.variant.vcf.VCFHeader;
import htsjdk.variant.vcf.VCFRecordCodec;
import htsjdk.variant.vcf.VCFUtils;
import htsjdk.samtools.SAMSequenceDictionary;

public class TestVcfReadWrite {

public static void main(String[] args) throws IOException {
    final VCFFileReader reader = new VCFFileReader(new File(args[0]));
    final VCFHeader header = reader.getFileHeader();
    
    SAMSequenceDictionary dict = header.getSequenceDictionary();
    final VariantContextWriter writer = new VariantContextWriterBuilder()
	.setReferenceDictionary(dict)
	.setOutputFile(new File(args[1])).build();

    writer.writeHeader(header);

    int i = 0;
    for (VariantContext variantContext : reader) {
	writer.add(variantContext);
	i++;
    }

    System.out.println(i);

    reader.close();
    writer.close();
}

}
