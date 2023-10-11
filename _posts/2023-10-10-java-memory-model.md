---
layout: post
tags: java memory-model
created_at: "2023-10-05 10:55"
title: "Understanding Java Memory Model"
---

These are notes taken to better understand the [Java Memory
Model](https://docs.oracle.com/javase/specs/jls/se21/html/jls-17.html#jls-17.4),
which I now publish as a blog post.

Programming language memory models, such as the Java Memory Model, attempt to
define the behavior of multi-threaded programs. These specifications help to
reason about code execution in a concurrent environment, even when the code runs
on different hardware architectures or undergoes numerous compiler
optimizations.

For example, given the following multi-threaded program:

<table>
<tr>
<th>Thread I</th>
<th>Thread II</th>
</tr>
<tr>
<td>
{% highlight java %}
x = 1;
done = 1;
{% endhighlight %}
</td>
<td>
{% highlight java %}
while (done == 0) { /** **/ }
System.out.println(x);
{% endhighlight %}
</td>
</tr>
</table>

Initially, all variables are set to zero, and each thread runs in its own
processor. Can we reason about the output of the program?

It appears that the output depends on the hardware and compiler optimizations.
On x86 architecture, the assembly version of this code will always print `1`.
However, on ARM architecture, it may print `0`. Additionally, compiler
optimizations can cause this program to either print zero or enter an infinite
loop.

As a programmer, it would be frustrating if programs don't work on new hardware
or with new compilers. Thus, high-level programming language memory models are
defined to provide a set of guarantees that programmers, while writing code in
that language, can rely upon.

But first, let's understand what guarantees are provided by the hardware.

## Hardware Guarantees

Let us imagine we are writing an assembly code for our multiprocessor computer.
What kind of guarantees could we expect from the hardware?

### Sequential Consistency

From [Leslie Lamport's 1979 paper](https://www.microsoft.com/en-us/research/uploads/prod/2016/12/How-to-Make-a-Multiprocessor-Computer-That-Correctly-Executes-Multiprocess-Programs.pdf):

> The customary approach to designing and proving the correctness of
> multiprocess algorithms for such a computer assumes that the following
> condition is satisfied: the result of any execution is the same as if the
> operations of all the processors were executed in some sequential order, and
> the operations of each individual processor appear in this sequence in the
> order specified by its program. A multiprocessor satisfying this condition
> will be called sequentially consistent.

This definition is natural to a programmer. It states that operations will be
executed in the order they appear in a written program, and threads will be
interleaved in some order.

For example, given the following program with two threads:

<table>
<tr>
<th>Thread I</th>
<th>Thread II</th>
</tr>
<tr>
<td>
{% highlight java %}
x = 1;
y = 1;
{% endhighlight %}
</td>
<td>
{% highlight java %}
r1 = y;
r2 = x;
{% endhighlight %}
</td>
</tr>
</table>

We could expect the following six outcomes from the above program in a
sequentially consistent hardware, with interleaving of each thread operations.

<table style="table-layout: fixed;">
<tr>
<td>
{% highlight java %}
x = 1;
y = 1;
            r1 = y; // 1
            r2 = x; // 1
{% endhighlight %}
</td>
<td>
{% highlight java %}
r1 = y; // 0
r2 = x; // 0
            x = 1;
            y = 1;
{% endhighlight %}
</td>
<td>
{% highlight java %}
x = 1;
    r1 = y; // 0
y = 1;
    r2 = x; // 1
{% endhighlight %}
</td>
</tr>
<tr>
<td>
{% highlight java %}
x = 1;
            r1 = y; // 0
            r2 = x; // 1
y = 1;
{% endhighlight %}
</td>
<td>
{% highlight java %}
r1 = y; // 0
            x = 1;
            y = 1;
r2 = x; // 1
{% endhighlight %}
</td>
<td>
{% highlight java %}
    r1 = y; // 0
x = 1;
    r2 = x; // 1
y = 1;
{% endhighlight %}
</td>
</tr>
</table>

As you can see, in the sequential consistent model the execution result where
`r1 = 1, r2 = 0` is not possible.

We can envision this model where all processors are directly linked to a single
shared memory. In this case, there are no caches involved each write or read
operation goes straight to the memory.

<div class="img-group">
<div class="">
  <img alt="Sequential Consistent Hardware" src="https://research.swtch.com/mem-sc.png">
</div>
<div class="caption" style="text-align:left">
  Sequential Consistent Hardware Model. Image © <a href="https://research.swtch.com/hwmm">Russ Cox - Hardware Memory Models</a>.
</div>
</div>

As we'll see, modern hardware designs often give up on strict sequential
consistency for performance reasons.

### x86 Total Store Order (TSO)

The modern x86 architecture memory model is based on the following hardware structure.

<div class="img-group">
<div class="">
  <img alt="x86 Architecture." src="https://research.swtch.com/mem-tso.png">
</div>
<div class="caption" style="text-align:left">
  x85 Architecture. Image © <a href="https://research.swtch.com/hwmm">Russ Cox - Hardware Memory Models</a>.
</div>
</div>

In this model, each write is queued in first-in, first-out (FIFO) order before
being written to the shared memory. Similarly, each read first checks the local
queue and then queries the shared memory. The local queue is flushed to the
shared memory in FIFO order, ensuring that each write is applied in the same
execution order in the processor.

This results in **total store order** (TSO). Once write reaches the shared
memory, each next read sees it until it's overwritten or buffered in the local
write queue.

### ARM Relaxed Memory Order

ARM processors have weaker memory models.

<div class="img-group">
<div class="">
  <img alt="ARM Architecture." src="https://research.swtch.com/mem-weak.png">
</div>
<div class="caption" style="text-align:left">
  ARM Architecture. Image © <a href="https://research.swtch.com/hwmm">Russ Cox - Hardware Memory Models</a>.
</div>
</div>

As depicted in the picture, each processor has its own copy of memory. Each
write propagates independently to other processors and there is a possibility of
write reordering. Additionally, a read can be delayed until it's needed or
until after a write.

In ARM hardware model, there is no total store order. It only provides total
order for writes on a single memory location (**coherence**) that we will see
later.

### Data Race Free Sequential Consistency (DRF-SC)

In their 1990 paper called [Weak Ordering &mdash; A New
Definition](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.42.5567),
Sarita Adve and Mark Hill introduced a synchronization model known as the
data-race-free (DRF) model.

This model assumes that there are distinct hardware memory synchronization
operations, and memory read or write operations can be rearranged between these
synchronization operations. However, reads and writes must not be moved across
the synchronization operations.

A program is considered data-race-free if any two accesses to the same memory
location from two different threads are either both read operations or are
separated by a synchronization operation that forces one to happen before the
other.

Well, this provides an agreement between hardware and software, given a
data-race-free program, the hardware will execute it in a sequentially
consistent manner. The above paper provides a proof, even for weaker ARM
hardware, that the hardware will appear sequentially consistent to a
data-race-free programs. This guarantee is abbreviated as Data Race Free
Sequential Consistency (**DRF-SC**).

So far, we have been assuming that we are programming in an assembly language
that is close to the hardware. Let's now examine the guarantees offered by
high-level programming language, Java's memory model.

## Java Memory Model

In the preceding section, we learned that if a programming language offers
synchronization mechanisms to coordinate different threads, we can use these to
create *data-race-free* (DRF) programs. These programs will be executed in a
sequentially consistent manner. Multi-threaded operations will be arbitrarily
interleaved and the outcome will be as if the operations are run on a single
processor.

Java offers various options for *atomic variables* and *atomic operations* to
develop DRF programs. It's crucial to understand that these are "synchronizing
instructions" which establish a **happens-before** relationship between code
executed on one thread and code executed on another. These **happens-before**
instructions also synchronize the rest of the program, eliminating data races on
non-atomic variables.

As a result, Java programs that are data-race-free are guaranteed to execute in
a sequentially consistent (DRF-SC) manner.

The main Java synchronization operations are:

- The creation of a thread happens before the first action in the thread.
- Unlock of mutex **m** happens before any following lock of **m**.
- Write to volatile variable **v** happens before any following read of **v**.

In Java, you can arrange all lock, unlock, volatile write and volatile read
operations in some interleaving order. This order defines the total order of
these operations. Then, the happens-before edges are created from write to read
that observes that write.

A Java program with two conflicting accesses that are not ordered according to
the happens-before relationship is considered to have a data race. It's
important to note that the happens-before edges are not established by locking
or unlocking different mutexes, or accessing different volatile variables.

## Litmus Tests

In this section, we are going to run several **litmus tests** to evaluate how
different models behave. These tests provide an answer to the question if
certain outcome is possible or not under specific model.

In these examples, we assume that each shared variable starts with zero and each
thread runs in its own dedicated processor. The `rN` is a thread-local variable,
and we check if a thread-local result is possible at the end of execution.

### Message Passing

Can this program see the following result `r1 = 1, r2 = 0`?

<table>
<tr>
<th>Thread I</th>
<th>Thread II</th>
</tr>
<tr>
<td>
{% highlight java %}
x = 1;
y = 1;
{% endhighlight %}
</td>
<td>
{% highlight java %}
r1 = y;
r2 = x;
{% endhighlight %}
</td>
</tr>
<tr>
<td colspan="2">
- On sequentially consistent hardware: no<br>
- On x86-TSO: no<br>
- On ARM: yes<br>
- Java language (plain): yes<br>
- Java language (volatile y): no<br>
</td>
</tr>
</table>

This outcome isn't possible in a sequentially consistent model. We can imagine
that each processor is directly connected to the shared memory, there are no
caches, registers, or write buffers. Thus, if we see an update on `x`, then we
should also see the update on `y`.

Similar reasoning applies to the x86-TSO model. The write buffer from a single
processor is flushed in FIFO order, ensuring that the update on `x` should
become visible if the update on `y` happens.

Please be aware that we are writing these programs in assembly like language,
where each instruction is executed by the processor. For the ARM model, these
instructions can be reordered. Writes can be run in a different order, resulting
in the possibility of an outcome.

For the Java language, using plain variables, the outcome mentioned above is
possible. The optimizing compilers like Just in Time (JIT) or Ahead of Time
(AOT) compilers can reorder updates on the `x` and `y` variables.

However, if we declare `y` as `volatile`, then write and read on a volatile
variable (for example, a synchronization operation) produces a happens-before
edge. The optimizing Java compiler strictly follows the rules to ensure that
this program conforms to DRF-SC.

By making variable `y` volatile, the above outcome is not possible. Similar to
x86-TSO, update on a volatile propagates all updates before it into the memory.
Then, read on `y` results in `1`, then read on `x` must also result in `1`.

### Store Buffering

Can this program see the following result `r1 = 0, r2 = 0`?

<table>
<tr>
<th>Thread I</th>
<th>Thread II</th>
</tr>
<tr>
<td>
{% highlight java %}
x = 1;
r1 = y;
{% endhighlight %}
</td>
<td>
{% highlight java %}
y = 1;
r2 = x;
{% endhighlight %}
</td>
</tr>
<tr>
<td colspan="2">
- On sequentially consistent hardware: no<br>
- On x86-TSO: yes<br>
- On ARM: yes<br>
- Java language (plain): yes<br>
- Java language (volatile x <b>and</b> y): no<br>
</td>
</tr>
</table>

On sequentially consistent hardware, this outcome isn't possible because
instructions are executed in total store order. However, on x86-TSO, the outcome
is possible because the write buffer from a processor may not have been flushed
to shared memory.

Due to the reordering of instructions, it's also possible to achieve the outcome
in both ARM and Java programming languages (using plain variables).

By making both variables `x` and `y` volatile, the above outcome is not
possible. There exists a happens-before edge between the write and read
operations on both volatile variables, so one of the writes should be the first
to be executed. Remember that reordering of instructions is not allowed across
synchronization operations.

### Load Buffering

Can this program see the following result `r1 = 1, r2 = 1`?

<table>
<tr>
<th>Thread I</th>
<th>Thread II</th>
</tr>
<tr>
<td>
{% highlight java %}
r1 = x;
y = 1;
{% endhighlight %}
</td>
<td>
{% highlight java %}
r2 = y;
x = 1;
{% endhighlight %}
</td>
</tr>
<tr>
<td colspan="2">
- On sequentially consistent hardware: no<br>
- On x86-TSO: no<br>
- On ARM: yes<br>
- Java language (plain): yes<br>
- Java language (volatile x or y): no<br>
</td>
</tr>
</table>

This outcome isn't possible in sequentially consistent and x86-TSO modes because
the instructions cannot be reordered.

On an ARM model and with Java using plain variables, the outcome is possible
because reads can be delayed until after writes.

In Java, declaring one of the variables as volatile, the above outcome is not
possible. Any write operation on a volatile variable creates a happens-before
edge, which prevents the compiler from reordering the instructions.

### Coherence

Can this program see the following result `r1 = 1, r2 = 2, r3 = 2, r4 = 1`?

<table>
<tr>
<th>Thread I</th>
<th>Thread II</th>
</tr>
<tr>
<td>
{% highlight java %}
x = 1;
{% endhighlight %}
</td>
<td>
{% highlight java %}
x = 2;
{% endhighlight %}
</td>
</tr>
<tr>
<th>Thread III</th>
<th>Thread IV</th>
</tr>
<tr>
<td>
{% highlight java %}
r1 = x;
r2 = x;
{% endhighlight %}
</td>
<td>
{% highlight java %}
r3 = x;
r4 = x;
{% endhighlight %}
</td>
</tr>
<tr>
<td colspan="4">
- On sequentially consistent hardware: no<br>
- On x86-TSO: no<br>
- On ARM: no<br>
- Java language (plain): yes<br>
- Java language (volatile x): no<br>
</td>
</tr>
</table>

Here is something that is not possible in the ARM model. This test checks if
updates to a single memory location are observed in a different order.

The threads agree on the total order of writes to a single memory location. One
of the writes overwrites the other, and all the hardware models agree on the
order.

However, due to optimizing compilers, the read instructions on thread IV could
potentially be reordered. While this is possible in Java with regular variables,
it is not feasible with volatile variables.

### Independent Reads of Independent Writes (IRIW)

Can this program see the following result `r1 = 1, r2 = 0, r3 = 1, r4 = 0`?

<table>
<tr>
<th>Thread I</th>
<th>Thread II</th>
</tr>
<tr>
<td>
{% highlight java %}
x = 1;
{% endhighlight %}
</td>
<td>
{% highlight java %}
y = 1;
{% endhighlight %}
</td>
</tr>
<tr>
<th>Thread III</th>
<th>Thread IV</th>
</tr>
<tr>
<td>
{% highlight java %}
r1 = x;
r2 = y;
{% endhighlight %}
</td>
<td>
{% highlight java %}
r3 = y;
r4 = x;
{% endhighlight %}
</td>
</tr>
<tr>
<td colspan="4">
- On sequentially consistent hardware: no<br>
- On x86-TSO: no<br>
- On ARM: yes<br>
- Java language (plain): yes<br>
- Java language (volatile x <b>and</b> y): no<br>
</td>
</tr>
</table>

This is similar to the coherence test, but with two distinct memory locations.
Primarily, we're verifying whether threads III and IV observe the updates on `x`
and `y` in different orders.

On ARM, there is no total store order guarantee on different writes. Similarly,
the optimizing compiler could reorder the `r3` and `r4` reads, making thread
interleaving to produce the above outcome.

Adding `volatile` to both variables, the outcome isn't possible since it
creates a happens-before edge that prevents the compiler from reordering the
reads.

### JCStress Tests

All of the litmus tests are validated using the [JCStress](https://github.com/openjdk/jcstress) framework. You can find the GitHub repository here at [github.com/morazow/jmm-litmus-tests](https://github.com/morazow/jmm-litmus-tests).

## Remarks

### Java Locks

### Java VarHandles

### Java Finals

## Conclusion

## References
