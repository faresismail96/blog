+++
author = "Fares Ismail"
date = "2019-10-14T13:00:00+00:00"
title = "Refined Types In Scala"
+++

The following is my interpretation of the [Refined Types presentation](http://fthomas.github.io/talks/2016-05-04-refined/)

In previous articles, I wrote about some issues surrounding the use of `String` parameters (passing an accountId instead of a userId and so on...)

Lets quickly recap:

``` scala
final case class UserBankAccount(userId: String, accountId: String, amount: Double)

UserBankAccount("user_10023", "account_28179", 2000) // Ok
UserBankAccount("account_28179", "user_10023", 2000) // Possible bug
```

It would be cool if we had a type safe solution that would prevent the code from compiling...

This is where value classes come in (discussed in an earlier post):

```scala
final case class UserBankAccount(userId: UserId, accountId: AccountId, amount: Double)

final case class UserId(id: String) extends AnyVal
final case class AccountId(id: String) extends AnyVal
```

With this implementation, the following would no longer compile:

```scala
UserBankAccount(AccountId("account_28179"), UserId("user_10023"), 2000)
```

And its great... provides compile time safety and we already know that value classes do not instantiate.
But we still run the risk of messing things up, since value classes are wrappers around simple types.

So we could still end up writing something like this:

```scala
UserBankAccount(UserId("account_28179"), AccountId("user_10023"), 2000)
```

... We could add some extra validation:

```scala

  final case class UserId(id: String) extends AnyVal
  final case class AccountId(id: String) extends AnyVal

  object UserId {
    def fromString(s: String): Option[UserId] = {
      def isUserId(s: String): Boolean = s.startsWith("user_")

      if (isUserId(s)) Some(UserId(s)) else None
    }
  }

  object AccountId {
    def fromString(s: String): Option[AccountId] = {
      def isAccountId(s: String): Boolean = s.startsWith("account_")

      if (isAccountId(s)) Some(AccountId(s)) else None
    }
  }

```

This does indeed provide extra security and insures compile time type safety we would have to end up dealing with Options are return values and so on...

The above code could also benefit from using a for-comprehension but nevertheless, you get my point...

Clearly there must be a better way.

## Refined Types

Refined Types are simply:
a `base type` and a `predicate`

It is a way to simply `Reduce` the `domain of our type`

so the instances of a refined types are the instances of that base type that satisfy the predicate.

Example:

```scala
type PositiveInt = Int Refined Positive
```

Where PositiveInt is a subset of the type Int containing only positive numbers.

for this to work, we would have to add the following library to our `build.sbt`

```scala
libraryDependencies ++= Seq("eu.timepit" %% "refined" % "0.9.10")
```

This would allow us to simply write:

```scala
val x: PositiveInt = 2
```

but what is we wrote:

```scala
val x: PositiveInt = -2 // would not compile
```

we would end up with the following error:

```scala
Error:(46, 25) Predicate failed: (-2 > 0).
  val y: PositiveInt = -2
```

Under the hood the actual code translates into:

```scala
val x: PositiveInt = auto.autoRefineV(2)(refinedRefType, greaterValidate(natWitnessAs(witness0, toInt0, IntIsIntegral), IntIsIntegral))
```

But I think everyone prefers the implicit version :p

The library goes a lot further, you could write your own validation functions as well as use prebuilt ones.

Example of PreBuilt functions:

* Contains[U]: checks if a Traversable contains a value equal to U
* Count[PA, PC]: counts the number of elements in a Traversable which satisfy the predicate PA and passes the result to the predicate PC
* Empty: checks if a Traversable is empty
* Forall[P]: checks if the predicate P holds for all elements of a Traversable
* Exists[P]: checks if the predicate P holds for some elements of a Traversable
* MinSize[N]: checks if the size of a Traversable is greater than or equal to N
* MaxSize[N]: checks if the size of a Traversable is less than or equal to N

* True: constant predicate that is always true
* Not[P]: negation of the predicate P
* And[A, B]: conjunction of the predicates A and B
* Or[A, B]: disjunction of the predicates A and B
* AllOf[PS]: conjunction of all predicates in PS
* AnyOf[PS]: disjunction of all predicates in PS
* OneOf[PS]: exclusive disjunction of all predicates in PS

* Less[N]: checks if a numeric value is less than N
* LessEqual[N]: checks if a numeric value is less than or equal to N
* Greater[N]: checks if a numeric value is greater than N
* GreaterEqual[N]: checks if a numeric value is greater than or equal to N
* Positive: checks if a numeric value is greater than zero
* Interval.Open[L, H]: checks if a numeric value is in the interval (L, H)
* Interval.Closed[L, H]: checks if a numeric value is in the interval [L, H]

* EndsWith[S]: checks if a String ends with the suffix S
* MatchesRegex[S]: checks if a String matches the regular expression S
* Regex: checks if a String is a valid regular expression
* StartsWith[S]: checks if a String starts with the prefix S
* Uri: checks if a String is a valid URI
* Url: checks if a String is a valid URL

So going back to our example, we would simply need to write:

```scala
  type UserId = String Refined StartsWith[W.`"user_"`.T]
  type AccountId = String Refined StartsWith[W.`"account_"`.T]
  final case class UserBankAccount(userId: UserId,
                                   accountId: AccountId,
                                   amount: Double)
```

and the code will cause a compile time error if a `user` or if an `account` do not meet the conditions set by the predicate.

source:

1. [Refined Types presentation](http://fthomas.github.io/talks/2016-05-04-refined/#1)
2. [WTF is Refined](https://medium.com/@Methrat0n/wtf-is-refined-5008eb233194)
