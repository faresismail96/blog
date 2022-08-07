+++
author = "Fares Ismail"
date = "2022-08-07T21:00:00+01:00"
tags = [
    "scala",
    "cats",
    "cats-effect"
]
title = "Cats Effect Part One: Effects"
+++

For some time now, I've been meaning to learn about cats effect. My plan is to follow the `Essential Effects` by Adam Rosien
You can find a copy of the book here: https://essentialeffects.dev/ Though at the time of writing, the book is still in draft version. 

I will be summarizing my understanding of each chapter in blog posts (chapter by chapter).
I will also be solving and posting some of their exercises. You can find them on github. 

And so begins part one (of nine?) blog posts.

## What are Effects

To better understand effect, we need to differentiate between computing a value and interacting with the environment. 

There you go, I sort of gave it away.

## Pure vs Impure Code

Before we get into effects, a short digression on pure vs non pure code in functional programming.

Pure code is a code that does not have any side effects.

Pure functions are deterministic and side effect free.
Impure functions contains side effects, are non deterministic and are generally harder to test.

Side effects can happen when computing a value or when interacting with the environment.

Computing a value:

1. Printing to the console
2. Reading user input
3. Interacting with a mutable variable like a `var`

Interacting with the environment:
Environments can change and are non deterministic. So functions interacting with the environment might not return the same value for the same input every single time. Think of reading something from a db for example.

## Effect Pattern

The idea behind this pattern is to encapsulate the side effect in something (`Effect`)

There are two parts to an effect:

1. Descriptive
    What kind of effect? 
    What value does the side effect produce?
2. When external side effect are required, do we separate the description from its execution
    Is the effect description separated from its execution? 

## Capturing arbitrary side effects as effects

In this section we will create our own Effect type from scratch. Later on we will use `cats.effect.IO` but for the time being, lets look at a very basic effect impl:

```scala

// The side effect is captured in the function unsafeRun
// And its execution can be delayed
case class MyIO[A](unsafeRun: ()=>A)

object MyIO{
    def putStr(s: => String): MyIO[Unit] =
        MyIO(() => println(s))
}

// Calling this

// Description but no execution
val hello = MyIO.putStr("Hello Fares!") 

// explicitly run the effect
hello.unsafeRun() 
```

In the case of `MyIO` it is descriptive. It informs us that `MyIO` contains a possibly side effecting computation, and tells us that if the computation is successful, it returns a type `A`.

Since `MyIO` can do anything (including a side effect), external side effects are possible. When that is the case, we separate the effect description from its execution. The execution only happens when `unsafeRun` is called.

## Composing effects

`IO` is a monad. 
Defines map and flatMap.
Short circuited in a for comprehension.

Composing effect must not execute them. Composition maintains substitution.

We can update our previous `MyIO` effect to allow for composition:

```scala

case class MyIO[A](unsafeRun: () => A){
  def map[B](f: A => B): MyIO[B] = MyIO(() => f(unsafeRun()))
  
  def flatMap[B](f: A => MyIO[B]): MyIO[B] = 
    MyIO(() => f(unsafeRun()).unsafeRun())
}
```

Here's an example that uses our effect to compute the duration of a task:

```scala
import scala.concurrent.duration.FiniteDuration
import java.util.concurrent.TimeUnit

object Timing extends App {
  val clock: MyIO[Long] = MyIO( () => System.currentTimeMillis())

  def time[A](action: MyIO[A]): MyIO[(FiniteDuration, A)] =
    for {
      start <- clock
      act <- action
      finish <- clock
    } yield(FiniteDuration(finish - start, TimeUnit.MILLISECONDS), act)

  val timedHello = Timing.time(MyIO.putStr("hello"))

  timedHello.unsafeRun() match {
    case (duration, _) => println(s"'hello' took $duration")
  }
}
```
