+++
author = "Fares Ismail"
date = "2020-10-04T23:00:00+02:00"
tags = [
    "scala",
    "cats",
    "writer",
    "monad"
]
title = "Writer Monads"
+++

This is actually one of the very first GitHub tickets I've opened. I tend read medium articles on my daily commute to work and I always see articles on the `Writer Monad` (along other monad instances I plan to write about). I did not use to read them because they're topics I do not understand but I've been meaning to learn about them for a while now... And so here is goes:

Note that my main support for this article is the [scala with cats book](https://books.underscore.io/scala-with-cats/scala-with-cats.html#writer-monad)

The `Writer` monad is used to carry a log along a computation.

It's `Writer[A,B]` Where A represents what we'd like to log and B is the computation. One thing worth noting is that the Writer DataType is actually a Type Alias:

```scala
type Writer[L, V] = WriterT[Id, L, V]
```

Before we go through an example here's a couple functions you should know:

To create a writer Monad:

- Create the Writer using both values with Apply:

```scala
val x: WriterT[Id, String, Int] = Writer("First Step", 1)
```

or a more eye pleasing syntax:

```scala
val b = 42.writer("Result of something")
```

Both return a MonadTransformer WriterT. We can see later on how to extract the actual values.

- Create the Writer from the Left value:

```scala
val res: Writer[String, Unit] = "Step".tell
```

- Create the Writer from the Right value

```scala
type Logged[A] = Writer[String, A]
val t: Logged[Int] = 2.pure[Logged
```

The reason we had to do that is because pure takes a `F[_]` so we had to fix the left value by creating a type alias. (Might one day write an article on type alias and type lambdas).

- Create a writer of Unit:

```scala
val res: Writer[String, Unit] = "Step".tell
```

## Extracting values from Writers

- To extract the Right value:

```scala
val b = 42.writer("Result of something")
val bResult: Id[Int] = a.value
```

- To extract the Left value:

```scala
val b = 42.writer("Result of something")
val bValue: Id[String] = b.written
```

- To extract both into a tuple:

```scala
val b = 42.writer("Result of something")
val bothResult: (String, Int) = b.run
```

## What to use as Log type

In the previous example, we used String but it doesn't make much sense since ideally we'd have multiple computations and would like to keep all the logs from each step. A good practice is to use a vector.

### Why a Vector

Given the need, you might be inclined to ask yourselves: `Why a vector and not a List` _(I know I did)_. The answer, it turns out, is because a vector is more efficient at append and concatenate operations.

## Example

```scala
  type Logged[A] = Writer[Vector[String], A]

  val writer1 = for {
    a <- 10.pure[Logged]
    _ <- Vector("Started off with 10").tell
    b <- 32.writer(Vector("New Writer with initial value: 32"))
    _ <- Vector("Now Adding both Writers").tell
  } yield a + b

  println(writer1) // WriterT((Vector(Started off with 10,
  //New Writer with initial value: 32, Now Adding both Writers),42))

```

Ok... So what just happened here:

We started off with a Writer(Vector(), 10)
Then in the second line of the for comprehension, we added our first log. _(note, we could have done both in the same statement)_.
Third line: We created a new Writer with an initial value of 32
Fourth line, we added to our second writer a log stating that we will add both writers.

The end result: All logs were appended to one another, and both values were added to one another.

### Mapping on the logs

Think of this as the equivalent of a left map, we have the possibility to map on the logs to transform them. The result will be a new Writer:

```scala
  val writer2 = writer1.mapWritten(_.mkString("\n"))
  println(writer2)
```

And the result:

```text
WriterT((Started off with 10
New Writer with initial value: 32
Now Adding both Writers,42))
```

To map on both values: either use the classical `bimap` or `mapBoth`. The differences are simply in the input parameters:

#### bimap

```scala
val writer1a = writer2.bimap(_.toLowerCase, _ + 1)
println(writer1a)
```

```text
WriterT((started off with 10
new writer with initial value: 32
now adding both writers,43))
```

#### mapBoth

```scala
  val writer1b = writer2.mapBoth((str, i) => (str.toLowerCase, i + 1))
  println(writer1b)
```

```text
WriterT((started off with 10
new writer with initial value: 32
now adding both writers,43))
```

Not much difference between both but it depends on how you want to use them or your preference.

## Why can't we just append to a file or a var

Appending the logs to a global variable or even a log file might sound like a good replacement for Writer monads but it has its limitations, specially when dealing with concurrency and failed computations.

If two actions are executed simultaneously, we might lose control over our log file/list. In addition, if a specific computation began its execution and logging and failed at some task, retrying the computation/task might be problematic and might complicate the handling of the logs.

Another issue (albeit not small) with having a global variable or a log file is that the code no longer remains pure, and code purity is something all functional programmers push for.

Having a pure function means the function can only interact with the arguments that are passed to it and cannot mutate some other state and cannot have side effects (like writing to a file).

## Real Life example

As a kid I loved math, specially algebra. But I would always get marks off my exams and homework even if my final answer was correct. My teachers would always nag me to "SHOW YOUR WORK".

In this example, we will attempt to solve for x while logging our work.

```scala
  val initialExpression = "(x-1)(x-2)(x-3)=0"

  val solver = for {
    _ <- 0.writer(Vector(s"initial equation: $initialExpression"))
    _ <- Vector(
      "The answer is x=1, x=2,x=3 but yall want me to " +
      "show my work so here it goes:"
    ).tell
    _ <- Vector(
      "There is a value for x that satisfies this " +
      "equation for (x-1)=0, (x-2)=0 and (x-3)=0"
    ).tell
    res1 <- 1.writer(Vector("(x-1)=0 so x=1"))
    res2 <- 2.writer(Vector("(x-2)=0 so x=2"))
    res3 <- 3.writer(Vector("(x-3)=0 so x=3"))
    _    <- Vector("roots of x: ").tell
  } yield (res1, res2, res3)

  val res = solver.mapWritten(_.mkString("\n")).run
  print(res._1)
  println(res._2)
```

```text
initial equation: (x-1)(x-2)(x-3)=0
The answer is x=1, x=2,x=3 but yall want me to show my work so here it goes:
There is a value for x that satisfies this equation for:
     (x-1)=0, (x-2)=0 and (x-3)=0
(x-1)=0 so x=1
(x-2)=0 so x=2
(x-3)=0 so x=3
roots of x: (1,2,3)
```

Yes I am a vindictive and vengeful person 🙄

## Drawbacks

1. The logs are not directly written, instead they are written at the end of the computation. This doesn't really show in our case because the computations are simple (0, 1, 2 etc...) but in the case where they were complex functions, the log would only be appended at the end of each function execution. For that reason, using timestamps in the logs is not a good idea.

2. If one step fails, the entire computation is lost and the logs along with them.
