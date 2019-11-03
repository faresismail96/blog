+++
author = "Fares Ismail"
date = "2019-10-14T13:00:00+00:00"
title = "Recursive Schemes with Matryoshka"
draft = true
tags = ["Matryoshka", "Recursive Schemes", "Scala"]
+++

I was always convinced that I would never even attempt to learn Matryoshka. Here are some of the reasons behind my decision:

1. Their Readme on GitHub contains the following doc that supposedly is a cheat sheet: <https://github.com/slamdata/matryoshka/blob/master/resources/recursion-schemes.pdf>

2. They use words like: "`zygohistomorphic prepromorphisms`"

3. The following line of code compiles...

```scala
  def htraverse[G[_]: Applicative, F[_], H[_], A](f: F ~> (G ∘ H)#λ) =
    λ[EnvT[A, F, ?] ~> (G ∘ EnvT[A, H, ?])#λ](_.run.traverse(f(_)).map(EnvT(_)))
```

and in case you were wondering, the symbol `∘` is defined as:

```scala
sealed abstract class ∘[F[_], G[_]] {
  type λ[A] = F[G[A]]
}
```

🤕🤕🤕

I will attempt to explain the notions in matryoshka the way I would have liked them explained to me.

So lets start by completely forgetting about matryoshka 😝

## What are Json Objects

Json is a way to write data using the key value notation.
`Keys` have to be `Strings` and values should be a valid Json data type: `string, number, object, array, boolean or null`.

Here is a simple Json, introducing me:

```json
{
    "name": "fares",
    "age": 23,
    "profession": "data engineer"
}
```

But a lot of people would argue that those field are useless because they don't actually tell us anything about that person...
So I'll re-write that json with data that might be a bit more representative of who I am:

```json
{
    "name": "fares",
    "age": 23,
    "profession": "data engineer",
    "currentlyReading": {
        "title":"la chute",
        "author":"albert camus"
    },
    "hobbies":["biking", "hiking", "skiing"],
    "petPeeve":"people using literally when they mean figuratively",
    "britishAccent":false
}
```

Thats cool, now you know a bit more about me... but whats more important is that you can see how the json object can contain strings, numbers, booleans, arrays of strings and a can contain a value that is in and of itself a json object (in our case book is a json object that contains 2 fields: `title` and `author`)

But we could stumble on much more complex cases, we can fin objects of objects of objects of strings and numbers and arrays. We can also find an array of objects ect...

lets add more details to the book im currently reading:

```json
{
    "name": "fares",
    "age": 23,
    "profession": "data engineer",
    "currentlyReading": {
        "title": "la chute",
        "author": {
            "name": "albert camus",
            "yearBorn": 1913,
            "isDead": true,
            "books": ["l'étranger", "la peste", "la chute", "l'homme révolté", "l'été"],
            "prixNobel":{
                "title": "prix nobel de littérature",
                "year": 1957
            }
        }
    },
    "hobbies":["biking", "hiking", "skiing"],
    "petPeeve":"people using literally when they mean figuratively",
    "britishAccent":false
}
```

As it turns out, a JsonObject is a very simple example of a recursive scheme. a JsonObject can either be a Value, an Array of JsonObjects or a Struct of JsonObject where a JsonObject is once again either a value an array of JsonObjects or a struct of JsonObjects and so on... you get the point and you can clearly see where the recursion is.

we would end up with a domain model that looks like this:

```scala
sealed trait JsonObject

final case class JsonStruct(k: String, v: JsonObject) extends JsonObject
final case class JsonArray(v: List[JsonObject]) extends JsonObject

final case class JsonString(v: String) extends JsonObject
final case class JsonInt(v: Int) extends JsonObject
final case class JsonBoolean(v: Boolean) extends JsonObject
```

Now assume we are not happy with the way this json was written. for example, I would like to capitalize every letter in a string. assume I also want to for some reason, append the word `value_` to every Integer.

I would have to write a code that looks something like this:

```scala

```
