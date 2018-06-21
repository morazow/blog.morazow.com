---
layout: post
title: Scalding TemplatedTsv And Hadoop Many Files Problem
category: en
tags: scalding cascading hadoop
location: Nuremberg
comments: true
---

# {{ page.title }}

<p class="meta">03 October 2014 - Nuremberg</p>

## TL;DR

If Scalding TemplatedTsv tap creates lots of output files, do a groupBy on
template column(s) just before writing the tap.

{% highlight scala linenos %}
pipe
  // some other etl
  .groupBy('STATE) { g => g.pass }
  .write(TemplatedTsv(baseOutputPath, "%02d", 'STATE))
{% endhighlight %}

You can find full pseudocode at the bottom of this page.

## Background

My daily job involves writing Hadoop map reduce jobs. I use
[Scalding](https://github.com/twitter/scalding) and
[Cascading](http://www.cascading.org/projects/cascading/). They are really
really really awesome. I cannot recommend them enough.

Usually we have several chain of map reduce jobs running. One of the jobs
performs daily aggregation of the incoming data. The result of this job is then
used as input for other jobs which run weekly or monthly.

## The Problem

Let's imagine the input data is formatted as, <span id="backcolor">`<user_id,
timestamp, state, transactions>`</span>  That is we have data about user making
transactions in particular timestamp (epoch) per place, which is geographical
State.

The main goal of this job is to count the number of transactions user made each
day per state. In Scalding that would be `map` and `groupBy` operations.

{% highlight scala %}
pipe
  .map('TIMESTAMP -> 'DAY) { ts: Long => ts % (3600 * 24) }
  .groupBy('USERID, 'DAY, 'STATE) { g => g.size('COUNT) }
  .write(Tsv(baseOutputPath))
{% endhighlight %}

One other requirement for the job is that it needs to store its results into
`/year/month/day/state/` partitions.

Depending on the incoming input data we need to partition the aggregated data.
That is, all the transactions for a particular state should be in single bucket
partition.  Input data may not contain all states, we should not create folders
for not existing states.

## The Solution

To achieve the goal we can use [TemplatedTsv][templatedtsv] tap from Scalding.
Just change the Tsv tap with it,

{% highlight scala %}
  .write(TemplatedTsv(baseOutputPath, "%02d", 'STATE))
{% endhighlight %}

When running the job jar just give the base output path as  <span
id="backcolor">`--output /year/month/day/`</span>  and it will create state
folders inside above path.

However, this approach will create [lots
files](http://blog.cloudera.com/blog/2009/02/the-small-files-problem/). Because
the data is not organized in any way, each reducer will have data containing
several states, reducers will create several files in the state folder.

This is very very bad for the next jobs in the chain if they use as input the
results of above job. For instance, weekly running job will be very slow because
of lots files it has to read.

Can we mitigate this problem somehow?

Yes, sure. When reducers are done processing the data and about to write, we
want the data that reducer processed to be from one (or two) state at most. So
it will create one or two files at most.

To achieve this, sort the data by state using Hadoop power before writing.  In
other words, we just add another `groupBy` operation in Scalding and do not
perform any aggregation operation in that grouping.

{% highlight scala %}
.groupBy('STATE) { g => g.pass }
.write(TemplatedTsv(baseOutputPath, "%02d", 'STATE))
{% endhighlight %}

This solves many files problem by introducing another map reduce phase overhead.

However, there is another problem with this solution. Because the data is not
balanced with respect to state, some reducers will process only records (which
might be a lot) belonging to a single state and delay the whole process.

Now the problem at hand is that some reducers process considerably large
percentage of the data while some others process very small percentage.
Therefore, our next goal is to process the states with lots of data in parallel
with several reducers instead of single reducer handling that state.

After analyzing the incoming data or the results of the previous aggregation
jobs, we can determine the states containing large portion of data. And
distribute their load to number of reducers (of our choice) with the following
trick,

{% highlight scala %}
.map(('USERID, 'STATE) -> 'SORTER) { tuple: (String, Int) =>
  val modulo = tuple._2 match {
    case 6  => 5
    case 48 => 7
    case 37 => 3
    case _  => 1
  }
  tuple._1.hashCode % modulo
}
.groupBy('STATE, 'SORTER) { g => g.pass }
.discard('SORTER)
.write(TemplatedTsv(baseOutputPath, "%02d", 'STATE))
{% endhighlight %}

For instance, we redistribute the California (6) state's data into five
reducers.  Therefore, instead of single reducer, five of them will be writing
into output partition thus creating file smaller files.

## Conclusion

TemplatedTsv is great. However, it creates lots of small output files which
affects negatively the performance of the next job on the chain. Fortunately,
the number of files can be reduced by sorting the data according to template
before writing the tap. Furthermore, if the data is skewed you can apply some
tricks to balance the templated data among reducers. This adds overhead of
another map reduce phase.

{% highlight scala %}
val pipeSource = Tsv(InputSource, ('USERID, 'TIMESTAMP, 'STATE, 'TRANSACTIONS))

val pipeETL = pipeSource
  .read
  .map('TIMESTAMP -> 'DAY) { ts: Long => ts % (3600 * 24) }
  .groupBy('USERID, 'DAY, 'STATE) { g => g.size[Int]('COUNT) }
  .map(('HASHCODE, 'STATE) -> 'SORTER) { tuple: (String, Int) =>
    val modulo = tuple._2 match {
      case 6  => 5
      case 48 => 7
      case 37 => 3
      case _  => 1
    }
    tuple._1.hashCode % modulo
  }
  .groupBy('STATE, 'SORTER) { g => g.pass }
  .discard('SORTER)
  .write(TemplatedTsv(baseOutputPath, "%02d", 'STATE))
{% endhighlight %}

{% include tweet.html %}

[templatedtsv]: https://twitter.github.io/scalding/api/#com.twitter.scalding.TemplatedTsv
