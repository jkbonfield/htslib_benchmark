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

public class TestBamReadWrite {

public static void main(String[] args) throws IOException {
    SamReader reader = SamReaderFactory
	.makeDefault()
	.validationStringency(ValidationStringency.SILENT)
	.open(new File(args[0]));        // input

    final SAMFileWriter writer = new SAMFileWriterFactory()
	.makeWriter(reader.getFileHeader(),
		    true,
		    new File(args[1]),   // output
		    new File(args[2]));  // reference

    for (SAMRecord record : reader) {
	writer.addAlignment(record);
    }

    reader.close();
    writer.close();
}

}
