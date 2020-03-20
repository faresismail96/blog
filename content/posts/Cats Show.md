+++
author = "Fares Ismail"
date = "2020-03-20T10:00:00+00:00"
tags = [
    "cats",
    "show",
    "toString",
]
title = "Cats Show"
+++

You can tell I'm not looking to write something serious by the topic I've chosen 😛

The first time I read about ``Show`` I instantly said to my self "its just a glorified toString". I still struggle to see the difference... Okay not really but they are pretty similar.

Backing up, Here is the signature of show:

```scala

  /** creates an instance of [[Show]] using the provided function */
  def show[A](f: A => String): Show[A] = new Show[A] {
    def show(a: A): String = f(a)
  }

```

So it takes a ``A`` as a type parameter and a function that takes an ``A`` and transforms it to a ``String``. Kind of like a toString... but the difference is that show takes a type parameter while toString is defined on ``Any`` meaning everything has a toString and as bizarre as this might look, it actually works:

```scala

(new {}).toString // Would return  $anon$1@8641b7d ???

```

While this would not work for show.

Show also safeguards against anyone randomly overriding the toString somewhere else and affecting your code.

## Example of using Show

Assume we have our ADT:

```scala

sealed abstract class Animal extends Product with Serializable

object Animal {

  final case object Dog extends Animal
  final case object Cat extends Animal

  implicit val showAnimal: Show[Animal] = Show.show {
    case Dog => "The following is a Dog"
    case Cat => "The following is a Cat"
  }
}

```

We defined an implicit val of type ``Show[Animal]`` in our ADT, allowing us to call the following from anywhere else in the code:

```scala

  val d: Animal = Dog
  d.show // Would return "The following is a Dog"

```
