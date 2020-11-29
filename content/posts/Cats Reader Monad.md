+++
author = "Fares Ismail"
date = "2020-11-29T20:37:00+01:00"
tags = [
    "scala",
    "cats",
    "reader",
    "monad"
]
title = "Reader Monads and Dependency Injection"
+++

After writing an article about the Writer Monad, it only seems fair that I write another one about the Reader Monad.

As with the Writer article, my main support will be the Scala with Cats Underscore Book freely available online.

I've also decided to put more effort into my examples and have them answer a real life problem. So in this articles' examples, I'll attempt to answer a common life question: "Can I become friends with x person".

For this, we'll simplify our "Person" and consider that a `Person` is only a name, age and recommendedBooks.

```scala
case class Person(name: String, age: Int, recommendedBooks: List[String])
```

But I'm jumping the gun. Let's go back to reader Monads:

## What is it

The reader monad allows us to sequence some operation that depend on the same external input (also called configuration).

### Creating Readers

To create a reader, we can use the apply method and pass to it a function that takes our external configuration/input and returns something:

```scala
  import cats.data.Reader
  import cats.implicits._

  val canBeFriend: Person => Boolean = _.recommendedBooks contains "Le Petit Prince"
  val reader: Reader[Person, Boolean] = Reader(canBeFriend)
```

`canBeFriend` is a function that takes a Person and returns a Boolean. It checks if the person would normally recommend the book "The Little Prince" to others. Coz can we really be friends with someone who doesn't???

`reader` is simply an apply. The type is a ``Reader[Person, Boolean]``. So it's a ``Reader`` that takes in a Person and returns a Boolean.

You might also notice that reader is implemented as a `Kleisli` but well talk about that later. (You can also check out my article on Kleisli)

## Why are they better than a raw function

A valid question could be: Why are they useful? What is the difference between doing this and a simple raw function:

```scala
def canBeFriends(person: Person): Boolean = person.recommendedBooks contains "Le Petit Prince"
```

Put like that, there isn't and a raw function is simpler to use/read.

But is "Le Petit Prince" the only criteria for being friends with someone? After all it is the second most translated book in the world after the bible... So maybe filter some more people out?

In an attempt to simplify the modeling of whether or not two people click together, we will assume that I can click with any person who is above 21 years old, below 30 years old aaaand who would recommend the book: Le Petit Prince. (I'm not that picky when it comes to friends).

We will also test this theory with 3 different people: myself, some random idiot who loves twilight and Eric an ok but slightly old person.

Our code might look like this:

```scala
  val fares = Person(
    "Fares",
    24,
    List(
      "All The Light We Cannot See",
      "The Catcher in the Rye",
      "L'étranger",
      "Le Petit Prince",
      "La Vie Devant Soi"
    )
  )
  val someIdiot = Person("Random Human", 16, List("Twilight"))
  val okButOld = Person("Eric", 38, List("Le Petit Prince"))

  def isOldEnough(person: Person): Boolean =
    person.age >= 21

  def isYoungEnough(person: Person): Boolean =
    person.age <= 30

  def okTasteInBooks(person: Person): Boolean =
    person.recommendedBooks contains "Le Petit Prince"

  def canWeBeFriends(person: Person): Boolean =
    isOldEnough(person) && isYoungEnough(person) && okTasteInBooks(person)
```

aaand the fun part:

```scala
  println(fares.name, fares.age, canWeBeFriends(fares))
  // (Fares,24,true)
  println(someIdiot.name, someIdiot.age, canWeBeFriends(someIdiot))
  // (Random Human,16,false) ==> Shocker!
  println(okButOld.name, okButOld.age, canWeBeFriends(okButOld))
  // (Eric,38,false)
```

It's not so bad but here are my couple concerns with the above implementation:

- It is not the easiest code to read. In our case, its a simple function but more complex ones might be even harder to understand.
- We also need to pass the input parameter person through all the intermediary functions just so that they can be passed to our different functions. In addition, our `person` input to every single one of our functions.

### How can we do better with reader

If we were to write the same code but this time using `Readers` it'll look something like this:

```scala
  val fares = Person(
    "Fares",
    24,
    List(
      "All The Light We Cannot See",
      "The Catcher in the Rye",
      "L'étranger",
      "Le Petit Prince",
      "La Vie Devant Soi"
    )
  )
  val someIdiot = Person("Random Human", 16, List("Twilight"))
  val okButOld = Person("Eric", 38, List("Le Petit Prince"))

  val isOldEnoughReader: Reader[Person, Boolean] = Reader(_.age >= 21)
  val isYoungEnoughReader: Reader[Person, Boolean] = Reader(_.age <= 30)

  val okTasteInBooks: Person => Boolean = _.recommendedBooks contains "Le Petit Prince"
  val okTasteInBooksReader: Reader[Person, Boolean] = Reader(okTasteInBooks)
```

In the above code, we've defined our `Person`s instances and our `Reader[Person, Boolean]`. One for each validation we would like to have.

Then we can sequence the operations in a for comprehension:

```scala
  val canWeBeFriends: Kleisli[Id, Person, Boolean] = for {
    okTaste     <- okTasteInBooksReader
    youngEnough <- isYoungEnoughReader
    oldEnough   <- isOldEnoughReader
  } yield okTaste && youngEnough && oldEnough
```

aaand again the fun part:

```scala
  println(fares.name, fares.age, canWeBeFriends.run(fares))
  // (Fares,24,true)
  println(someIdiot.name, someIdiot.age, canWeBeFriends.run(someIdiot))
  // (Random Human,16,false) ==> Shocker!
  println(okButOld.name, okButOld.age, canWeBeFriends(okButOld))
  // (Eric,32,false)
```

Note: the apply `canWeBeFriends(someIdiot)` consists of calling the `run` function. So they're interchangeable.

With the reader implementation, we simply need to defined our readers and create the for-comprehension that will hold our business logic. We then simply have to call the result of the for comprehension with the specific input. This is also the reason why `Readers` are also used as dependency injection.

You might have also noticed that the result of the for-comprehension is a `Kleisli[Id, Person, Boolean]`. If you recall from my previous article, Kleisli allows for the composition of functions where the return type is monadic.

And how is the return type Monadic? Isn't it Boolean? if you look at any of the above applies of the reader, the return type will be an Id[Boolean], Where Id is a Monad.

I'll probably write an article on that but for now know that Id[A] and A can be used interchangeably.
