+++
author = "Fares Ismail"
date = "2021-02-14T12:20:00+02:00"
tags = [
    "adt",
    "sum type",
    "product type",
    "scala"
]
draft = "false"
title = "ADTs: Sum Types and Product Types"
+++

It has been a while since I haven't posted a new article, and in an attempt to break the cycle I'm starting off with something pretty simple.

When listening to people talk of ADTs, you'll often hear the words: `Sum type` and `Product type`. Now I have a bad habit of confusing the two so in this article I'll attempt to make things clearer and I will hopefully never find myself re-re-researching both.

But first, ADT stands for Algebraic Data Type and they're essentially all about combining existing types to create new ones to better model a specific domain.

A simplistic explanation of domain is "an area of knowledge", the problem space we are working with. This includes all related entities, their behavior and the laws they obey.

ADTs allow us to model all that, including the relationships between different entities.

## Product Types

Product types are created by combining two or more types together with the `AND` operator. Here are a couple examples:

Street addresses are comprised of a street number and a street name.

```scala
final case class StreetAddress(streetNumber: Int, streetName: String)
```

A book consists of a title, and author and an ISBN.

```scala
final case class Book(title: String, author: String, isbn: Long)
```

## Sum Types

A sum type is a type that combines other types using the `OR` operator. Here are a couple examples:

- A grade is a pass or fail class is a Sum type, it can either be `Pass` or can be `Fail` but not both.

- A boolean can either be `True` or it can be `False` but not both.

- A dice roll can only be one out of six possibilities at a time but not more.

In our PostalAddress class, we represented a fullName as a String. But what if we wanted to push this further?

A fullName can be comprised of a firstName and a lastName, but a persons' name can also include a middleName

So here's one way of modeling this:

```scala
final case class FullName(
  firstName: String,
  middleName: Option[String], 
  lastName: String
)
```

And I guess thats okay... But we'll have to add ``None`` everywhere a middle name does not exist and when it does, we'll have to wrap it in a ``Some``

```scala
  val stephen = FullName("Stephen", None, "Chbosky")
  val sagan = FullName("Carl", Some("Edward"), "Sagan")
```

But what about people with a singe name such as : `Aristotle`, `Charlemagne`, `Fibonacci` etc...

Should we make the firstName optional? can those really be considered their last names? or should be put some cases aside as special cases to be handled separately? If so wouldn't we end up in a situation where we have so many exceptions of different kind that it becomes unmanageable?

If I'm asking these questions its because they best demonstrate where Sum Types really shine!

A FullName can be modeled as a first and last name OR a first, middle and last name OR a single name etc...

```scala

sealed trait FullName

object FullName {
  
  final case class FirstLastName(
    firstName: String, 
    lastName: String
    ) extends FullName

  final case class WithMiddleName(
    firstName: String, 
    middleName: String, 
    lastName: String) 
    extends FullName

  final case class SingleName(name: String) extends FullName
  
  val stephen: FullName = FirstLastName("Stephen", "Chbosky")
  val sagan: FullName = WithMiddleName("Carl", "Edward", "Sagan")
  val aristotle: FullName = SingleName("Aristotle")
}

```

I'm definitely not the best at coming up with class names, but this point aside... All three instances are of the same type: `FullName` which is a Sum Type that can either be one of the three defined above.

We're not restricted to Either Sum or Product Types. Instead we can use both together to better model our domain. Here's our Book type better represented using the FullName Sum Type:

```scala
final case class Book(title: String, author: FullName, isbn: Long)
```

The last one is known as a Hybrid type or a `Sum of Products` type.

## If you must remember two things

- ADTs are all about combining existing types to create new ones and better model our domain.
- Sum Types combine types with the OR operator while Product Types do it with the AND operator.
