---
layout: post
title: Using MultiGroupBy with Scalding
category: en
tags: scalding cascading hadoop bigdata
location: Nuremberg
comments: true
---

# {{ page.title }}

<p class="meta">18 November 2014 - Nuremberg</p>

## TL;DR

Scalding `.groupBy` and `.join` operations can be combined into single operation
using [MultiGroupBy](https://github.com/LiveRamp/cascading_ext#multigroupby)
from [Cascading extension](https://github.com/LiveRamp/cascading_ext), which
improves the job performance. Scalding job example using MultiGroupBy can be
found [here][scaldingexamples].

## Introduction

Let's imagine we have two data sources. The first data contains the purchase
record of the users per time and per geographical State. This data is formatted
as following, <span id="backcolor">`<user_id, timestamp, state,
purchases>`</span>. The second data contains the user demographic information.
For this particular example, it only contains user age, <span
id="backcolor">`<user_id, age>`</span>

The main goal of this map reduce job is to count the number of purchases per
state and per age group.

In Scalding we can implement this job as,

{% highlight scala %}
class MultiGroupByExample1(args: Args) extends Job(args) {
  // ...

  val Purchases =
    Tsv(purchasesPath, ('USERID, 'TIMESTAMP, 'STATE, 'PURCHASE))
    .read

  val UserAges =
    Tsv(userAgesPath, ('USERID, 'AGE))
    .read

  val MyJob = Purchases
    .groupBy('USERID, 'STATE) { _.size('COUNT) }
    .joinWithSmaller('USERID -> 'USERID, UserAges)
    .groupBy('STATE, 'AGE) { _.sum[Int]('COUNT) }
    .write(Tsv(outputPath))
}
{% endhighlight %}

This is elegant and concise solution however it is not very efficient.

## The Problem

In Scalding each `.groupBy` and `.join` operation introduces another map reduce
phase.  That is with the code above, data will be shuffled, sorted and reduced
three times before finishing the computation. Therefore, when there are very
<span id="backcolor">big data</span> to be processed, the overall job performance
will be very inefficient.

Luckily we can do better!

## MultiGroupBy Operation

The desired solution is to perform aggregation operations while joining two data
sources. Fortunately, it can be achieved using **MultiGroupBy** operation. In
the rest of this blog I will show how to use MultiGroupBy in Scalding by
reducing the three steps from above job into single map reduce phase.

> Recently I was reading [tips for optimizing Cascading
flows](http://nathanmarz.com/blog/tips-for-optimizing-cascading-flows.html) and
recalled [Cascading extensions](https://github.com/LiveRamp/cascading_ext)
project which I saw several months ago.  It offers additional operations on top
of Cascading. Here I will only show MultiGroupBy (maybe BloomJoin in some other
blog post). It is great!

The API of MultiGroupBy is defined [here][cascadingext] It accepts two pipes,
two fields definitions as joining fields, renamed join field(s) and aggregation
operation. We will have to write Cascading multi buffer operation in Java, but
it is worth the effort.

The updated Scalding job will be as below,

{% highlight scala linenos %}
import com.liveramp.cascading_ext.assembly.MultiGroupBy

class MultiGroupByExample2(args: Args) extends Job(args) {
  // ...

  val MyJob =
    new MultiGroupBy(
      Array(UserAges, Purchases),
      Array(new Fields("USERID"), new Fields("USERID")),
      new Fields("USERID"),
      new MyMultiBufferOp(new Fields("STATE", "AGE", "COUNT"))
    )
    .discard('USERID)
    .write(Tsv(outputPath))
}
{% endhighlight %}

Because MultiGroupBy performs join operation, it keeps the join fields.
Therefore, on line 13 we just discard *'USERID* column.

> Please notice the smooth Scala/Scalding and Java/Cascading interop. *new
> Fields("USERID")* and *'USERID* are the same.

Next we write our multi buffer operation, **MyMultiBufferOp**.

{% highlight java linenos %}
import com.liveramp.cascading_ext.multi_group_by.MultiBuffer;
import org.apache.commons.collections.keyvalue.MultiKey;

public class MyMultiBufferOp extends MultiBuffer {
  // ...

  @Override
  public void operate() {

    // First pipe: UserAges <USERID, AGE>
    Iterator<Tuple> userAges = getArgumentsIterator(0);
    if (!userAges.hasNext())
      return ;

    Tuple userAgesTuple = userAges.next();
    int user_age = userAgesTuple.getInteger(1); // second field is age

    // Data structure to store the count
    MultiKey key = null;
    Map<MultiKey, Integer> countMap = new HashMap<MultiKey, Integer>();

    // Second pipe: Purchases <USERID, TIMESTAMP, STATE, PURCHASES>
    Iterator<Tuple> purchases = getArgumentsIterator(1);

    while (purchases.hasNext()) {
      Tuple purchasesTuple = purchases.next();

      int state = purchasesTuple.getInteger(2); // third column is state

      key = new MultiKey(state, user_age);
      if (countMap.containsKey(key)) {
        countMap.put(key, countMap.get(key) + 1);
      }
      else {
        countMap.put(key, 1);
      }
    }

    // We just calculated <STATE, AGE, COUNT> results stored in 'countMap'
    // Now we just have to emit COUNT, because we gave <STATE, AGE>
    // as grouping names when calling this buffer operation
    for (Map.Entry<MultiKey, Integer> entry : countMap.entrySet()) {
      key = entry.getKey();

      int state = (Integer) key.getKey(0);
      int age = (Integer) key.getKey(1);
      int count = entry.getValue();
      emit(new Tuple(state, age, count));
    }
  }
}
{% endhighlight %}

On lines 11 & 23 we obtain tuple iterators for the two data sources. Then we
keep updating the hashmap `HashMap(<state, age>, count)` until exhausting
iterators on lines 30-36. Finally, on lines 42-49 we emit the hashmap contents
as results for this buffer operation.

You can find the full code [here][multiscala] and [here][multijava] multi buffer
operation. In order to test the MultiGroupBy example you will have to assembly
fat jar and run it on Hadoop environment.

## Conclusion

In find this kind of patterns, join after or before groupBy, a lot in our map
reduce job chains. Using MultiGroupBy we achieved considerable performance
increase. Additionally, it resulted in efficient cluster utilization.

I strongly believe this operation should be default in both Cascading and
Scalding.

{% include tweet.html %}

[scaldingexamples]: https://github.com/morazow/ScaldingExamples/tree/master/src/main/scala/com/morazow/multigroupby
[multiscala]: https://github.com/morazow/ScaldingExamples/tree/master/src/main/scala/com/morazow/multigroupby
[multijava]: https://github.com/morazow/ScaldingExamples/tree/master/src/main/java/com/morazow/multigroupby
[cascadingext]: https://github.com/LiveRamp/cascading_ext/blob/master/src/main/java/com/liveramp/cascading_ext/assembly/MultiGroupBy.java#L35-L55
