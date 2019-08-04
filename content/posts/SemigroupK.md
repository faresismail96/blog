+++
author = "Fares Ismail"
date = "2019-08-03T15:00:00+00:00"
title = "SemigroupK and CombineK"
+++

Before we get into `SemigroupK`and `combineK` let us first quickly recap what a `semigroup` is.

---

Semigroup
---------

A Semigroup for a given type `A` has a single operation that takes two values of type A and returns a single value of the same type. This operation needs to be associative.
We will call this operation combine for simplicity.

from `algebra.Semigroup` we have:

```scala
/**
 * A semigroup is any set `A` with an associative operation (`combine`).
 */
trait Semigroup[@sp(Int, Long, Float, Double) A] extends Any with Serializable {

  /**
   * Associative operation taking which combines two values.
   */
  def combine(x: A, y: A): A

```

This might be a bit abstract, so lets look at a more concrete example:

```scala
  val classOneGrades: List[Int] = List(75, 80, 78, 90, 100)
  val classTwoGrades: List[Int] = List(50, 68, 90, 98)

  val allGrades = classOneGrades.combine(classTwoGrades)
```
the result is as you'd expect: `List(75, 80, 78, 90, 100, 50, 68, 90, 98)`

```md
Note:  We could have also called `classOneGrades |+| classTwoGrades`
since the sign |+| is a `SemigroupOps` that calls combine.
```
So where is the utility of semigroups?

Assume we had a `List[A]` and we wished to combine all the elements in that list into one, we could easily call:

```scala
  val result: A = list.foldLeft(???)(_ |+| _)
```
this starts out with an initial single value (??? in this case) and traverses the list combining every 2 elements together and appending previous value.

```
Note: the only issue in the above example is that we do not have an "empty" value to put in instead of the ??? (in the case the list is empty for example...)

This however is taken care of by the Monoid which is a semigroup plus an 'empty' value that acts as the identity of the combine.
```

---

SemigroupK
----------

For Lists, the Semigroup's combine and the SemigroupK's combineK operate in the same way i.e: they return a concatenated list consisting of both lists' elements.

so where is the difference?

Here is an excerpt from cats' official documentation: 
```
SemigroupK has a very similar structure to Semigroup, the difference is that SemigroupK operates on type constructors of one argument. So, for example, whereas you can find a Semigroup for types which are fully specified like Int or List[Int] or Option[Int], you will find SemigroupK for type constructors like List and Option. 
```

But what does SemigroupK do differently?

Well assume you have two `Option[A]` combineK would return the the first Some of the two...

assume you have a function that takes a `previousValue` and a `currentValue`.
you would like to return currentValue but if this is none, then you would like to return previousValue else return None.

If we did not use SemigroupK, our solution would have to look like this:
```scala

  val res: Option[Int] = (curr, prev) match {
    case (Some(a), _)    => Some(a)
    case (None, Some(b)) => Some(b)
    case (None, None)    => None
  }

```

Using SemigroupK the same code becomes:

```scala
  val res: Option[Int] = SemigroupK[Option].combineK(curr ,prev)
```

With SemigroupK the code becomes much simpler and easier to read.

Here are a few examples of returns with SemigroupK:


```scala

val res = SemigroupK[Option].combineK(Some(2), None)
// res = Some(2)

val res = SemigroupK[Option].combineK(None, Some(3))
// res = Some(3)

val res = SemigroupK[Option].combineK(Some(2), Some(3))
// res = Some(2)

val res = SemigroupK[Option].combineK(None, None)
// res = None

```
