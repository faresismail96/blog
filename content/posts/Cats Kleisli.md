+++
author = "Fares Ismail"
date = "2020-05-17T10:00:00+02:00"
tags = [
    "scala",
    "cats",
    "kleisli"
]
title = "Cats Kleisli"
+++

I wont lie... The main reason I'm looking into `Kleisli` is because I think the name is cool.

Kleisli allows the composition of functions where the return type is a monadic value while the input to the next function is not.

## Function Composition

Function Composition allows us to chain function calls together.

Here is a dummy example:

```scala
  val getValueFromDB: Unit => String = _ => "Fares"
  val transformValue: String => String = _.toUpperCase
  val saveValueToDB: String => Unit = _ => ()
```

The following are 3 dummy functions that load a value from a database, transforms it (to uppercase) and finally saves it back to the database.

Here's how it would look like:

```scala
  saveValueToDB(transformValue(getValueFromDB()))
```

Except it's quite ugly to look at and to read.

But luckily there is another way:

```scala
  val result = saveValueToDB compose transformValue compose getValueFromDB
  result()
```

or

```scala
  val result = getValueFromDB andThen transformValue andThen saveValueToDB
  result()
```

I'll admit I think using `andThen` is the better option since it is the most readable and since we have a tendency to read left to right and not the other way around.

## Issue (When it returns a monadic value)

Alright so thats cool... But the problem becomes if those functions return a monadic value. Example:

```scala
  val getValueFromDB: Unit => Either[Throwable, String] = _ => Right("Fares")
  val transformValue: String => Either[Throwable, String] = x =>  Right(x.toUpperCase)
  val saveValueToDB: String => Either[Throwable, Unit] = x => Right(println(x))
```

Sure in this context, the return type doesn't make much sense, but just imagine a real world scenario 😛

In that case, we would no longer be able to use function composition because the return types no longer match with the input parameter of the next function.

One solution that normally comes to mind:

### For Comprehension

The following works well:

```scala
  for {
    value          <- getValueFromDB()
    transformedVal <- transformValue(value)
    _              <- saveValueToDB(transformedVal)
  } yield ()
```

But there is another way, using `Kleisli`.

## Using Kleisli

Effectively, Kleisli is a  MonadTransformer but for functions. It allows us to abstractly ignore the context when performing composition of functions.

```scala
  val res =
  Kleisli(getValueFromDB) andThen
  Kleisli(transformValue) andThen
  Kleisli(saveValueToDB)

  res.run()
```

We need to call run in the end because the end result of res is `Kleisli[Either, Unit, Unit]`

So thats about it for Kleisli... But if you ask me, for this particular usage, using a for-comprehension to me is a lot more straightforward.
