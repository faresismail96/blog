+++
author = "Fares Ismail"
date = "2020-09-25T06:20:00+02:00"
tags = [
    "scala",
    "cats",
    "Monad Error"
]
title = "Cats MonadError"
+++

I've been mostly focusing on Python for the past couple weeks so I'll attempt to balance things out by prioritizing a couple Scala articles...

I've also come to realize that I have not been following the methodology that has inspired this blog in the first place. In this article, I'll attempt to constantly answer the question "why" and in doing so hopefully strengthen my grasp of the subject . And so for all my readers, the both of you might notice a change in format 😝.

## MonadErrors What are they

`MonadErrors` are an abstraction over `Either`-like data types.

### Why are they useful

This abstraction is useful if you're working with both `Either` and `Try` and would like your function to return a value independently of the context it's in.

More concretely, assume you have a function `sayHello` that can return an exception. Depending on where you're calling this function, you would like it to either return an `Either[Throwable, String]` or a `Try[String]` (or something else...).

```scala
import scala.language.higherKinds
import cats.MonadError
import scala.util.Try

def sayHello[F[_]](value: String)(implicit me: MonadError[F, Throwable]): F[String] = {
    me.catchNonFatal("Hello "+ value)
}

val x: Try[String] = {
  import cats.instances.try_._
  sayHello("Fares")  // Success(Hello Fares)
}
println(x)

val y: Either[Throwable, String] = {
  import cats.instances.either._
  sayHello("Emily")
}
println(y)  // Right(Hello Emily)
```

In each case, the function `sayHello` is returning the result in a different `F` context. This is because whe specified that the return type is an `F[_]` and not a specific Monad.

#### Why does it work

MonadError has the following definition:

```scala
trait MonadError[F[_], E] extends ApplicativeError[F, E] with Monad[F] {

  def ensure[A](fa: F[A])(error: => E)(predicate: A => Boolean): F[A] =
    flatMap(fa)(a => if (predicate(a)) pure(a) else raiseError(error))

}
```

This also depends of the version of cats you're using. More recent versions also include: `ensureOr`, `adaptError`, `rethrow` as well as everything coming from `ApplicativeError[F[_], E]` and `Applicative[F]`.
MonadError takes two type parameters:

- ``F``: The type of the Monad
- ``E``: The error that will be within the `F` i.e: `Throwable`

So when we say: `Either[Throwable, String]`, the `F` is the `Either` context and the `E` is the `Throwable`.

##### What are the helper functions useful for

I won't go through all of them, but here are some examples of the functions defined in the `MonadError` trait:

- ``Ensure``: Ensure allows us to turn a successful value into an error if it does not satisfy the predicate.

```scala
  import cats.syntax.either._

  val fares: Either[Throwable, String] = Right("Fares")
  val emily: Either[Throwable, String] = Right("Emily")

  def isFares: String => Boolean = _ == "Fares"

  val res1 = fares.ensure(new Exception("Not Fares"))(isFares)
  val res2: Either[Throwable, String] = emily.ensure(new Exception("Not Fares"))(isFares)

  println(res1) // Right(Fares)
  println(res2) // Left(java.lang.Exception: Not Fares)
```

- `ensureOr`: Definition:

```scala
 def ensureOr[A](fa: F[A])(error: A => E)(predicate: A => Boolean): F[A] =
    flatMap(fa)(a => if (predicate(a)) pure(a) else raiseError(error(a)))
```

Pretty similar to `ensure` but instead of error being `error: => E` it's: `error: A => B`

```scala
  def toError: String => Throwable = str => new Exception(s"$str is not Fares")
  val res1 = fares.ensureOr(toError)(isFares)
  val res2 = emily.ensureOr(toError)(isFares)

  println(res1) // Right(Fares)
  println(res2) // Left(java.lang.Exception: Emily is not Fares)
```

- `adaptError`: Transforms the error into something else and then rethrow it.

Definition:

```scala
  def adaptError[A](fa: F[A])(pf: PartialFunction[E, E]): F[A] =
    recoverWith(fa)(pf.andThen(raiseError[A] _))
```

```scala
  def partialFunction: PartialFunction[Exception, Exception] = {
    case a: Exception => new RuntimeException("Encountered An Error")
  }

  val x: Either[Exception, String] = "Fares".asRight[Exception].adaptError(partialFunction)
  val y: Either[Exception, String] = new Exception("Not Fares").asLeft[String].adaptError(partialFunction)
  val z: Either[Exception, String] = new Exception("Some error").asLeft[String].adaptError(partialFunction)

  println(x)    // Right(Fares)
  println(y)    // Left(java.lang.RuntimeException: Encountered An Error)
  println(z)    // Left(java.lang.RuntimeException: Encountered An Error)
```

Not the most ingenious example, but does the trick.

One limiting thing: the definition of adaptError states `[E,E]` which means that we can not freely adapt the errors to a different type!

- `rethrow`: Handles values by potentially turning them into Errors. Takes a ``F[Either[EE, A]]`` if the outer value is an Error like, the result is an error. If its a Success like value then we check in Either, if it's a left, the result is an error otherwise its a success.

Definition:

```scala
def rethrow[A, EE <: E](fa: F[Either[EE, A]]): F[A] =
    flatMap(fa)(_.fold(raiseError, pure))
```

Examples:

```scala
  val a: Try[Either[Throwable, String]] = Success(Left(new java.lang.Exception))
  a.rethrow // Failure(java.lang.Exception)
  val b: Try[Either[Throwable, String]] = Success(Right("Fares"))
  b.rethrow // Success(Fares)
  val c: Try[Either[Throwable, String]] = Failure(new java.lang.Exception)
  c.rethrow // Failure(java.lang.Exception)
```

### What are some Instances of MonadError

Cats provides instances for `MonadError` for multiple data types like: `Either`, `Future`, `Try`

Either can be used with any error on the left, but Future and Try have to have a Throwable on the Left.
