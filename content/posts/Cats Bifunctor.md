+++
author = "Fares Ismail"
date = "2020-02-09T10:00:00+00:00"
tags = [
    "scala",
    "cats",
    "bimap",
]
title = "Cats Bifunctor"
+++

The following will be a short and rather simple article about a useful function I recently learned about: `bimap` by cats.

In cats and in some cases scala, types like Either, Validated, Option... are right biased. which means that when we call `.map` on them, the function applied in the map is only applied on the case of a right.

Here are some examples:

```scala

val either: Either[String, Int] = Right(2)
val result: Either[String, Int] = either.map(int => int * 2)

val option1: Option[Int] = Some(2)
val result1: Option[Int] = option1.map(int => int * 2)
// a map on a None returns a None.

```

But what if we only wanted to apply a function on the left side? conveniently, cats offers us a `.leftMap` function. This does not apply in the case of an option.

```scala
val result = either.leftMap(str => "Error: " + str)
```

In some cases, we find ourselves wanting to apply different functions in the case where the return is a right and when its a left. In that case we can use `bimap`.

bimap is defined by a `Bifunctor` and from the cats definition:

``` text
Bifunctor takes two type parameters instead of one, and is a functor in both of these parameters. It defines a function bimap, which allows for mapping over both arguments at the same time. Its signature is as follows:
```

```scala
def bimap[A, B, C, D](fab: F[A, B])(f: A => C, g: B => D): F[C, D]
```

here's an example:

```scala

  import cats.syntax.either._

  val either: Either[String, Int] = ???
  def function1(str: String) = ???
  def function2(int: Int) = ???

  either.bimap(function1, function2)

```

In the case where the value ``either`` is of type Right then ``function2`` will be applied. In the case its a Left, ``function1`` would be applied.

Here is the implementation of ``bimap`` on an either:

```scala

  def bimap[C, D](fa: A => C, fb: B => D): Either[C, D] = eab match {
    case Left(a)  => Left(fa(a))
    case Right(b) => Right(fb(b))
  }

```

In case this behavior is a bit familiar its because scala offers a very similar function: ``fold``

Similarly to `bimap`, fold takes 2 functions and applies them on the left and the right.

Here is the scala doc along with the function definition:

```scala

  /** Applies `fa` if this is a `Left` or `fb` if this is a `Right`.
   *
   *  @example {{{
   *  val result = util.Try("42".toInt).toEither
   *  result.fold(
   *    e => s"Operation failed with $e",
   *    v => s"Operation produced value: $v"
   *  )
   *  }}}
   *
   *  @param fa the function to apply if this is a `Left`
   *  @param fb the function to apply if this is a `Right`
   *  @return the results of applying the function
   */
  def fold[C](fa: A => C, fb: B => C): C = this match {
    case Right(b) => fb(b)
    case Left(a)  => fa(a)
  }

```

The difference between both is in the return and in the return types of the function they take.

In the case of `bimap` on an Either, the return type will compulsorily be an Either. So its as its name suggests, its a map in both directions. The return type is an Either and the 2 type parameters can be different from one another and from the initial type parameters.

But in the case of `fold`, the return type will depend on the functions passed to the fold. In the same time, both functions will have to have the same return type (``C in the scala doc``)

So to summarize the main differences between a bimap and a fold:

1. ``bimap`` returns an Either while ``fold``'s return type depends on the functions passed to it.
2. The functions passed to the bimap can have different return types. while the functions passed to the fold needs to have the same return type.
