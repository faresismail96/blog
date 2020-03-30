+++
author = "Fares Ismail"
date = "2020-03-30T01:00:00+00:00"
tags = [
    "cats",
    "validated",
    "validatedNel",
    "validation",
]
title = "Validated(Nel) for Validation"
+++

Week two of being stuck at home due to the Corona-virus confinement. I'm writing this article because I desperately need to feel like I've accomplished ONE productive thing this weekend.
On a side note, I've recently taken up cooking and managed to completely botch a recipe that was considered kids friendly... So yea those are my life updates...

I will begin my explanation of Validated by explaining something else entirely...

## Either Monad

``Either[A,B]`` is pretty simple to understand. As its name and signature suggest: its Either a value of type A or its a value of type B.
Either also allows us to chain computations.

Assume we wanted to validate that the values for a type ``Person`` are indeed valid, our model would be something like this:

```scala

import cats.Show
import com.validatedPost.PersonError._

final case class Person(private val firstName: String,
                        private val lastName: String,
                        private val age: Int) {
  def validateFirstName: Either[PersonError, String] =
    if (firstName.nonEmpty) Right(firstName) else Left(FirstNameError)
  def validateLastName: Either[PersonError, String] =
    if (lastName.nonEmpty) Right(lastName) else Left(LastNameError)
  def validateAge: Either[PersonError, Int] =
    if (age >= 18) Right(age) else Left(AgeError)
}
object Person {
  implicit val showPersonError: Show[Person] = Show.show( person =>
    s"""
      |First Name: ${person.firstName}
      |Last Name: ${person.lastName}
      |Age: ${person.age}
      |""".stripMargin)
}

sealed abstract class PersonError extends Product with Serializable

object PersonError {

  final case object FirstNameError extends PersonError
  final case object LastNameError extends PersonError
  final case object AgeError extends PersonError

  implicit val showPersonError: Show[PersonError] = Show.show {
    case FirstNameError => "There was an issue with the given first name"
    case LastNameError  => "There was an issue with the given last name"
    case AgeError       => "Age is not 18 or above"
  }
}

```

And we'd be able to chain all three validations with the helpful `For Comprehensions` or simple ``maps + flatMaps``:

```scala

  import cats.syntax.either._
  import com.validatedPost.PersonError._

  val person1 = Person("Fares", "Ismail", 23)

  def validatePerson(person: Person) = {
    for {
      vFirstName <- person.validateFirstName
      vLastName <- person.validateLastName
      vAge <- person.validateAge
    } yield Person(vFirstName, vLastName, vAge)
  }
  val res: Either[PersonError, Person] = validatePerson(person1)

  println(res.show)

```

This will output:

```text

Right(
First Name: Fares
Last Name: Ismail
Age: 23
)

```

But what if the person instance had a few errors?

```scala
  val person2 = Person("Fares", "", 23)
  println(validatePerson(person2).show) // Left(There was an issue with the given last name)

```

Ok... so far so good. But what if there were multiple errors?

```scala

  val person3 = Person("", "", 10)
  println(validatePerson(person3).show) //Left(There was an issue with the given first name)

```

It outputs the first error only. ideally we would have liked the errors to be accumulated.

The reason it does this is because ``Either`` is fail fast. It will exit the for comprehension at the first ``Left`` it encounters.

## Validated For Error Accumulation

If I talked about Either in an article about validated, its clearly not by coincidence.

While either is fail fast, ``Validated`` will allow us to accumulate the errors on the left side. We've touched on this briefly in previous articles (including ``Cats Ior`` which accumulated warnings), but lets go over it again with ``Validated``

For that, well need to change our validation functions to return a ``Validated``

Validate has the following signature:

```scala

sealed abstract class Validated[+E, +A] extends Product with Serializable {
  // Implementation elided
}

final case class Valid[+A](a: A) extends Validated[Nothing, A]
final case class Invalid[+E](e: E) extends Validated[E, Nothing]

```

In our case, its going to be a ``Validated[NonEmptyList[PersonError], Person]``

The ``NonEmptyList`` is used to accumulate the possible errors since we can have more than one.

Conveniently, we have a type alias called ``ValidatedNel[A,B]`` that is short for ``Validated[NoneEmptyList[A], B]``

Person will look like this:

```scala

import cats.Show
import cats.data.{Validated, ValidatedNel}
import cats.syntax.validated._
import com.validatedPost.PersonError._

final case class Person(private val firstName: String,
                        private val lastName: String,
                        private val age: Int) {
  def validateFirstName: ValidatedNel[PersonError, String] =
    if (firstName.nonEmpty) firstName.validNel else FirstNameError.invalidNel
  def validateLastName: ValidatedNel[PersonError, String] =
    if (lastName.nonEmpty) lastName.validNel else LastNameError.invalidNel
  def validateAge: ValidatedNel[PersonError, Int] =
    if (age >= 18) age.validNel else AgeError.invalidNel
}
object Person {
  implicit val showPersonError: Show[Person] = Show.show(person => s"""
      |First Name: ${person.firstName}
      |Last Name: ${person.lastName}
      |Age: ${person.age}
      |""".stripMargin)
}

```

and our function calls:

```scala

  val person3 = Person("", "", 10)

  import cats.data.NonEmptyList._
  import cats.syntax.apply._
  import cats.data.ValidatedNel

  val res: ValidatedNel[PersonError, Person] =
    (person3.validateFirstName, person3.validateLastName, person3.validateAge)
      .mapN((first, last, age) => Person(first, last, age))

  println(res.show) //Invalid(NonEmptyList(There was an issue with the given first name, There was an issue with the given last name, Age is not 18 or above))

```

Note that depending on your version of cats, this can either be a ``.mapN`` or ``.map3`` and so on (replace N by the appropriate number)

We notice that the return of the validation function is all the errors accumulated in the NonEmptyList.

Also note that for this to work we need an implicit Semigroup in the scope for the left side. This is because ``Validated`` will use it to combine the error on the left.

Finally, if we wanted to use ``Validated`` in a fail fast manner, we still can by calling ``.andThen``
