# Compressed Tsv for Scalding

Compressing the map-reduce job results is essential. In my daily job I write all
my Hadoop map-reduce jobs using Scalding. It is really really great, I cannot
stress this enough.

Briefly, Scalding is a Scala DSL on top of the Cascading, another great tool for
writing Hadoop jobs.

Back to topic at hand.

## Compress the output of Scalding job

It is relatively easy. We just need to enable Hadoop compression parameters. I
want the compression to be Gzip and its type BLOCK.

```scala
class WordCountJob(args : Args) extends Job(args) {

  // Set job specific configurations here
  override def config: Map[AnyRef,AnyRef] = {
    super.config ++ Map (
      // Hadoop MR1, for backward compatibility
      "mapred.output.compress" -> "true",
      "mapred.output.compress.type" -> "BLOCK",
      "mapred.output.compress.codec" -> "org.apache.hadoop.io.compress.GzipCodec",

      // Hadoop MR2 (Yarn)
      "mapreduce.output.fileoutputformat.compress" -> "true",
      "mapreduce.output.fileoutputformat.compress.codec" -> "org.apache.hadoop.io.compress.GzipCodec",
      "mapreduce.output.fileoutputformat.compress.type" -> "BLOCK"
    )
  }

  TextLine( args("input") )
    .flatMap('line -> 'word) { line : String => line.split("""\s+""") }
    .groupBy('word) { _.size }
    .write(Tsv( args("output") ) )
}
```

However this job will not compress its output result.

Because underlining 'TextDelimited' class, which 'Tsv' extends, set compression
parameter to null.  Therefore, when writing to HDFS it will basically not
compress the output even if we enable compression in our job configuration.

## Compression process

We can implement our class with compressions enabled. And extend this to create
compressed taps, Tsv, Csv, etc.  There is only single line we have to change in
Cascading TextDelimeted class. That is, set the [sinkCompression][compress] to
TextLine.Compress.DEFAULT or TextLine.Compress.ENABLE.

Here is the change in Scalding DelimetedScheme,

```scala
override def hdfsScheme = {
  val tmp = new CHTextDelimited(fields, CHTextLine.Compress.DEFAULT,
                skipHeader, writeHeader, separator, strict, quote, types, safe)

  tmp.asInstanceOf[
    Scheme[JobConf, RecordReader[_, _], OutputCollector[_, _], _, _]]

  // old Scalding code
  // HadoopSchemeInstance(new CHTextDelimited(fields, null, skipHeader, writeHeader,
  //        separator, strict, quote, types, safe))
}
```

This is not a bug for Twitter since they use [elephant-bird]() with LZO
compression.  I had a pull request around this which got lost because of my next
pull request.

You can find example project here, [WordCount-Compressed](). It is easy to make
other Delimited taps use compression by extending [CompressedDelimitedScheme]().

[compress]: http://docs.concurrentinc.com/cascading/2.5/cascading-hadoop/cascading/scheme/hadoop/TextLine.html#setSinkCompression%28cascading.scheme.hadoop.TextLine.Compress%29
