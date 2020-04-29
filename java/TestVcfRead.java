// See https://www.programcreek.com/java-api-examples/?code=broadinstitute/picard/picard-master/src/main/java/picard/vcf/SortVcf.java

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;

import htsjdk.variant.variantcontext.VariantContext;
import htsjdk.variant.vcf.VCFFileReader;
import htsjdk.variant.vcf.VCFHeader;
import htsjdk.variant.vcf.VCFRecordCodec;
import htsjdk.variant.vcf.VCFUtils;

public class TestVcfRead {

public static void main(String[] args) throws IOException {
    VCFFileReader reader = new VCFFileReader(new File(args[0]));
    final VCFHeader header = reader.getFileHeader();

    int i = 0;
    for (VariantContext variantContext : reader) {
	i++;
    }

    System.out.println(i);

    reader.close();
}

}
