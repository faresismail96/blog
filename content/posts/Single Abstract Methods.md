+++
author = "Fares Ismail"
date = "2022-04-04T20:20:00+02:00"
tags = [
    "Scala"
]
draft = "false"
title = "Single Abstract Method"
+++

Short and quick article to explain a syntactic sugar in Scala.

Often we'll have traits that declare a single abstract method to be overridden in the subclasses of that trait.

This might look like this:

```scala

sealed trait Animal{
    def sayHi(name: String): String
}

object Animal{

    final case object Dog {
        override def siHi(name: String): String = s"Woof $name"
    }
}

```

But we can also instantiate anonymous classes that implement the trait Animal:

```scala

val cat1: Animal = new Animal {
    override def siHi(name: String): String = s"Meow $name"
}

```

This works... But it is a little bit wordy. Scala offers a much neater way to instantiate anonymous classes for traits that declare a single abstract method:

```scala

val bird1: Animal = (name: String) => s"chirp $name"

```

I know... Chirp is not the real sound birds make but its the closest onomatopoeic representation I could find... And if that bothers you, please keep in mind that animals can't utter names either ``¯\_(ツ)_/¯``

But I'm digressing.

This syntactic sugar only works for traits that have a single abstract method.

They work when the trait has multiple implemented methods and one abstract:

```scala

trait Animal {
  def sayHi(name: String): String
  def isHungry: Boolean = true // Animals are always hungry
}

val cat1: Animal = (name: String) => s"Meow $name"


```

But not when that trait has two or more abstract methods. If in the previous case isHungry is abstract then we will no longer be able to define cat1 the way we did and instead will have to resort to the previous instantiation with the `new Animal` keyword.

error example:

```text
type mismatch;
found   : String => String
required: Animal
val cat1: Animal = (name: String) => s"Meow $name"
```

```scala
val cat1: Animal = new Animal {
  override def sayHi(name: String) = s"Meow $name"

  override def isHungry = true
}
```
