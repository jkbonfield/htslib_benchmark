import htsjdk.samtools.DefaultSAMRecordFactory;
import htsjdk.samtools.SAMFileWriter;
import htsjdk.samtools.SAMFileWriterFactory;
import htsjdk.samtools.SAMRecord;
import htsjdk.samtools.SamInputResource;
import htsjdk.samtools.SamReader;
import htsjdk.samtools.SamReaderFactory;
import htsjdk.samtools.ValidationStringency;
import htsjdk.samtools.seekablestream.SeekableStream;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;

public class TestBamRead {

public static void main(String[] args) throws IOException {
    SamReader reader = SamReaderFactory
	.makeDefault()
	.validationStringency(ValidationStringency.SILENT)
	.open(new File(args[0]));

    int i = 0;
    for (SAMRecord record : reader) {
	i++;
    }

    System.out.println(i);

    reader.close();
}

}
