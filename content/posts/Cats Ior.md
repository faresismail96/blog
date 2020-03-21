+++
author = "Fares Ismail"
date = "2020-03-21T10:00:00+00:00"
tags = [
    "cats",
    "ior",
]
title = "Cats Ior"
+++

If you've gotten this far reading my blog, you're probably very familiar with ``Either``. Of course Im also assuming someone is reading this blog in the first place 😛

Anyway, ``Either[A,B]`` allows us to return either an ``A`` or a ``B`` depending on some conditions... In other words, its a XOR (exclusive or) A value can either be A or it can be B but it cannot be both.

You probably see where this is going, ``IOR`` is a cats datatype that stands for Inclusive Or. In other words, ``Ior[A,B]`` can either be `A` or it can be `B` or it can be `Both A and B`.

Another syntax for defining an Ior is: ``A Ior B``

Ior is often used when we want to handle errors and correct values as well as correct values but wth a warning.

## Examples

Here is an example using IOR:

```scala

  import cats.data.Ior

  val right: Ior[String, Int] = Ior.right[String, Int](3)
  val left: Ior[String, Int] = Ior.left[String, Int]("Error")
  val both: Ior[String, Int] = Ior.both[String, Int]("Warning", 0)

```

Of course things can be made to look nicer when using the cats syntax:

```scala

  import cats.syntax.ior._

  val x: Ior[String, Nothing] = "NOPE".leftIor
  // Or
  val z: Ior[String, Int] = "Better Nope".leftIor[Int]

```

## Accumulating Errors

Another benefit of Ior is its ability to accumulate errors on the left side. Similar to Cats Validated (Will be discussed in a later article)

### How does it work

Ior will accumulate warnings on the left side but will short circuit the computations as soon as it encounters a left only value.
Lets look at an example for a clearer image.

```scala

  import cats.data.Ior
  import cats.syntax.ior._
  import cats.data.{NonEmptyList => Nel}
  type Failures = Nel[String]

  final case class UserName(private val name: String) extends AnyVal {
    def validateUserName: Failures Ior UserName = {

      if (name.isEmpty) Nel.one("Error, Username cannot be empty").leftIor
      else if (name == "admin")
        Ior.both(
          Nel.one(
            "In the future, protected words will no longer be considered valid"),
          UserName(name))
      else UserName(name).rightIor
    }
  }

  final case class UserPassword(private val value: String) extends AnyVal {
    def validatePassword: Failures Ior UserPassword = {
      if (value.isEmpty) Nel.one("Passwords cannot be empty").leftIor
      else if (value.length < 10)
        Ior.both(Nel.one("Password is not very secure"), UserPassword(value))
      else UserPassword(value).rightIor
    }
  }

```

which would allow us to create a valid ``User``:

**Note:** If you're confused by mapN and the various imports, it'll be explained in another post along with validated and validatedN.

```scala
  import cats.syntax.apply._

  final case class User(name: UserName, pass: UserPassword)

  val username1 = UserName("Fares")
  val pass1 = UserPassword("qwertyazerty")
  val user1 = (username1.validateUserName, pass1.validatePassword).mapN(User)

  // user1 ==> Right(User(UserName(fares),UserPassword(qwertyazerty)))
```

But what if the username and password contained non blocking errors?

```scala

  val username2 = UserName("admin")
  val pass2 = UserPassword("pass")
  val user2 = (username2.validateUserName, pass2.validatePassword).mapN(User)

  //user2 ==> Both(NonEmptyList(In the future, protected words will no longer be considered valid, Password is not very secure),User(UserName(admin),UserPassword(pass)))

```

This is what we meant by accumulating warnings or nonblocking errors.

But what if we encountered a blocking error?

```scala

  val username3 = UserName("")
  val pass3 = UserPassword("")
  val user3 = (username3.validateUserName, pass3.validatePassword).mapN(User)

  //user3 ==> Left(NonEmptyList(Error, Username cannot be empty))

```

Notice it short circuited the computations without accumulating the errors on the left side (Password was empty but the error was not added to that of Username)

## Conversion

Ior Can be converted to an ``Either`` a ``Validate`` or even an ``Option``.

Keep in mind however that when doing so, the ``Both`` will drop its left side and only keep the right value and transform it to a ``Some`` or a ``Right`` ect...

Here are the transformation codes:

```scala

  final def toEither: Either[A, B] = fold(Left(_), Right(_), (_, b) => Right(b))
  final def toValidated: Validated[A, B] = fold(Invalid(_), Valid(_), (_, b) => Valid(b))
  final def toOption: Option[B] = fold(_ => None, b => Some(b), (_, b) => Some(b))

```
