+++
author = "Fares Ismail"
date = "2019-08-03T10:00:00+00:00"
title = "Collect / FilterMap"
+++

Collect or FilterMap does exactly what is says. it filters a collection and then maps the values.

collect takes a partial function as a parameter and returns a Traversable of the same type.

```scala 
def collect[B](pf: PartialFunction[A, B]): CC[B]
```
Also from the scaladoc: 

```scala
/**
  * @tparam CC type constructor of the collection (e.g. `List`, `Set`). Operations returning a 
  * collection with a different type of element `B` (e.g. `map`) return a `CC[B]`.
  */
```

This tells us that the function collect applies a function on a collection and returns a collection of a different type.

---

let us look at a simple example:

```scala
  val randomNumbers: List[Int] = List(1, 2, 5, 20, 25, 29)

  val result: List[Double] = randomNumbers.collect {
    case x: Int if x < 10  => x * 10
    case x: Int if x >= 10 => x / 10.0
    case _                 => 0
  }
```

The above code returns:
> List(10.0, 20.0, 50.0, 2.0, 2.5, 2.9)

"But... The example above is the same thing as applying a map..." True it is... the below code yields the exact same result:

```scala
  val result = randomNumbers.map { x =>
    if (x < 10) x * 10
    else if (x > 10) x / 10.0
    else 0
  }
```
so where is the benefit of using collect instead of map? the answer is the in filtering part.

when applying collect we have the option to specify the range/type... of values we would like to apply the map on. the rest of the elements in our collection will not be mapped and therefore will no be collected in the result.

going back to our previous example, say we only wanted to collect values below 10 and multiply them by 10:

```scala
  val result = randomNumbers.collect {
    case x: Int if (x < 10) => x * 10
  }
``` 
the result would be:
> List(10.0, 20.0, 50.0)

Now I'm assuming you've figured it out by now but collect is a more concise way of using:

```scala
val result = randomNumbers.filter(_ < 10).map(_ * 10.0)
```

Specially when we start dealing with complex types and multiple scenarios.