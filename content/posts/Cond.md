+++
author = "Fares Ismail"
date = "2020-03-31T01:00:00+00:00"
tags = [
    "scala",
    "cats",
    "cond",
]
title = "Cond in Scala"
+++

This is probably one of the simplest articles I've written... except for the About section of this site...

The reason I'm writing it is because I recently discovered a simple yet very useful function that facilitates the construction of an ``Either`` monad or a ``Validated`` monad.

This function is called ``cond`` probably short for condition. Ans here is how it works:

```scala

  import cats.data.Validated

  def someFunction: Boolean = ???

  val either: Either[String, String] = Either.cond(someFunction, "OK", "ERROR")

  val validated: Validated[String, String] =
    Validated.cond(someFunction, "OK", "ERROR")
```

So if a certain condition evaluates to true, a right side will be created with the given value. otherwise a left side will be created with the given left value.

It might not be useful all the time since in most cases, the right and left value are calculated from the function doing the validation, but they have their moments 😛 (hint: I could have used them in my previous article about validated!)
