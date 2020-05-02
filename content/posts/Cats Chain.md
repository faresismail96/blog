+++
author = "Fares Ismail"
date = "2020-04-03T10:00:00+00:00"
tags = [
    "scala",
    "cats",
    "chain",
]
title = "Cats Chain"
+++

In previous articles, I've talked about accumulating errors with Validated, and for that we said that we needed a `Semigroup` on the left side that will be used to accumulate the errors (We used a `NonEmptyList[A]` as an example). Today well talk about `Chain` and `NonEmptyChain[A]` and how it's different from a List.

Appending to a `List` requires iterating over the entire collection (linear time). So using `ValidatedNel[A,B]` will make us incur a heavy performance penalty specially if we `traverse` it.

In comes `Chain`. Chain is very similar to List, but supports O(1) time append and prepend. This makes it a much better fit to use with `Validated`, `Ior` or `Writer` (article on this pretty soon).

Cats also offers type aliases like `ValidatedNec` or `IorNec` as well as helper functions like `groupByNec` or `Validated.invalidNec`.

Here are some benchmarks from the typelevel cats documentation <https://typelevel.org/cats/datatypes/chain.html>:

```text
[info] Benchmark                                  Mode  Cnt   Score   Error  Units
[info] CollectionMonoidBench.accumulateChain     thrpt   20  51.911 ± 7.453  ops/s
[info] CollectionMonoidBench.accumulateList      thrpt   20   6.973 ± 0.781  ops/s
[info] CollectionMonoidBench.accumulateVector    thrpt   20   6.304 ± 0.129  ops/s
```

and some function calls:

```text
[info] Benchmark                           Mode  Cnt          Score         Error  Units
[info] ChainBench.foldLeftLargeChain      thrpt   20        117.267 ±       1.815  ops/s
[info] ChainBench.foldLeftLargeList       thrpt   20        135.954 ±       3.340  ops/s
[info] ChainBench.foldLeftLargeVector     thrpt   20         61.613 ±       1.326  ops/s
[info]
[info] ChainBench.mapLargeChain           thrpt   20         59.379 ±       0.866  ops/s
[info] ChainBench.mapLargeList            thrpt   20         66.729 ±       7.165  ops/s
[info] ChainBench.mapLargeVector          thrpt   20         61.374 ±       2.004  ops/s
```

## NonEmptyChain

Similarly to ``NonEmptyList`` NonEmptyChain has a semigroup but not a monoid (obviously :stuck_out_tongue:).

Cats doc shows a couple examples on how to create them or transform NonEmptyList into a NonEmptyChain:

```scala

import cats.data._
// import cats.data._

NonEmptyChain(1, 2, 3, 4)
// res0: cats.data.NonEmptyChain[Int] = Chain(1, 2, 3, 4)

NonEmptyChain.fromNonEmptyList(NonEmptyList(1, List(2, 3)))
// res1: cats.data.NonEmptyChain[Int] = Chain(1, 2, 3)

NonEmptyChain.fromNonEmptyVector(NonEmptyVector(1, Vector(2, 3)))
// res2: cats.data.NonEmptyChain[Int] = Chain(1, 2, 3)

NonEmptyChain.one(1)
// res3: cats.data.NonEmptyChain[Int] = Chain(1)

```
