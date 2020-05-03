+++
author = "Fares Ismail"
date = "2020-05-03T20:00:00+02:00"
tags = [
    "scala",
    "trait",
    "abstract class",
    "ADT",
]
title = "Scala Sealed Trait vs Sealed Abstract Class"
+++

From my previous articles, you've seen me create ADTs in two different ways:

```scala
sealed abstract class Animal

object Animal {

  final case object Dog extends Animal
  final case object Cat extends Animal
}
```

or

```scala
sealed trait Animal

object Animal {

  final case object Dog extends Animal
  final case object Cat extends Animal
}
```

This article will outline the difference between those two implementations.

## Sealed Trait

If a behavior is to be re-used, traits are very handy since they can be mixed in. We can also mix in multiple traits, as opposed to abstract classes where we can only extend one.

A disadvantage for traits (and a huge advantage for abstract classes) is that traits can't take constructor arguments.

example:

```scala
sealed trait Person(name: String)
// Will not compile
```

In other words, if our base behavior takes constructor arguments, use an abstract class.

Its worth also nothing that in traits we can do the following

```scala
sealed trait Person{
    def name: String
}
```

Which ultimately is the same thing... except its a def so can be implemented as a `val` or a `def` ==> more flexible

## Sealed Abstract Class

The primary advantage of abstract classes over traits is that they have a direct mapping to a structure in java, as opposed to trait which do not.

So if you intend on calling your code will be accessed in java, think about defining abstract classes.

Another worthy note, mentioned above for traits:

```scala
sealed abstract class Person(name: String)
```

name is a `val`. So it wouldnt be possible for a case class to implement name as a def (which could have been possible with a trait) ==> Less flexible.

## If you must remember 2 things

A class can only extend one abstract class, as opposed to traits where we can mix in multiple traits

If you want to call your code from java, use abstract classes since Scala traits with implemented methods can’t be called from Java code.

## General advice

If you're not sure, you can start by creating a trait and move to an abstract class later on if you need it. Keep in mind that traits are more flexible.
