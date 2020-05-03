+++
author = "Fares Ismail"
date = "2020-05-03T10:00:00+02:00"
tags = [
    "scala",
    "constructor",
    "smart constructor",
    "validation"
]
title = "Smart Constructors in Scala"
+++

Assume we have the following ADT:

```scala

sealed trait Person {
  def name: String
  def age: Int
}

object Person {

  final case class Adult(name: String, age: Int, fieldOfWork: String)
      extends Person
  final case class Child(name: String,age: Int, favAnimal: String)
      extends Person
}

```

Probably a very naive way to see humanity but for our example, it'll do.

So a Person can either be an `Adult` with a field of work or a `Child` with a favorite animal.

And logically, the line of demarcation between and adult and a child is 18 years old.

The problem with our implementation is that nothing stops us from doing the following:

```scala
val kid = Adult("Daniel", 12, "President")
//kid: Adult = Adult(Daniel,12,President)
```

Not exactly what we want...

And yes, we could add a validation later on in our code to enforce certain laws but it'll just be extra boiler plate.

Another very valid solution is the use of ``Refined Types``. But in case you do not/ cannot add that dependency to your project, you can still get away with using ``Smart Constructors``

## Smart Constructor

For our class `Adult` a smart constructor will look like this:

```scala
final case class Adult private (name: String, age: Int, fieldOfWork: String)
    extends Person
object Adult {
  def apply(name: String, age: Int, fieldOfWork: String): Option[Adult] =
    if (age >= 18) Some(new Adult(name, age, fieldOfWork)) else None
}
```

**__Note__ that I've tested the above code in scala 2.11.11 and it does not work. Only starting version 2.12.11**

What happened there? One we made the constructor of Adult private so that we could no longer do:

`new Adult("Daniel", 12, "prez")` from somewhere outside the companion object.
Second thing, we defined our own apply method that returns an `Option[Adult]` that is either Some if the input is valid or None otherwise.

Example:

```scala
val kid = Adult("Daniel", 12, "prez")
// None
val adult = Adult("Fares", 23, "Data Engineer")
//Some(Adult(Fares,23,Data Engineer))
```

The same should also be done for the Child case class.
