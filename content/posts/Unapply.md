+++

author = "Fares Ismail"
date = "2019-08-02T10:00:00+00:00"
title = "Un-Apply in Scala"

+++


Unapply in Scala is the inverse of the apply... (queue no shit comments :p)

So what does it do exactly? given a class Person:

``` scala
case class Person(name: String, age: Int, hobbies: List[String])
```

If we wanted to decompose the class person into a set of attributes:

 - name: String
 - age: Int
 - hobbies: List[String]

We would use the unapply. the return type of the unapply is an Option of a tuple with the values inside the tuple representing the values we seek to retrieve.

``` scala
case class Person(name: String, age: Int, hobbies: List[String])

object Test {
  
  val fares: Person = Person("fares", 23, List("Hiking", "Biking")) 
  val result: Option[(String, Int, List[String])] = Person.unapply(fares)
 
}
```

We notice that the return type is an option of a tuple of string, int and List of String.
That means that after the unapply, we would have to extract the Tuple from the option and call `result._1` and so on to retrieve each individual value.

clearly this is cumbersome and annoying to deal with. And clearly there is a better way :p 

But for fun, let us check what this might look like:

``` scala
  val fares: Person = Person("fares", 23, List("Hiking", "Biking"))

  var result: Option[(String, Int, List[String])] = Person.unapply(fares)

  val name = result.get._1
  val age = result.get._2
  val hobbies = result.get._3
```

Note: calling get like this can throw a `java.util.NoSuchElementException` we should instead do some checking if it its defined or simply call `.getOrElse` and pass a default value... (complicate things even more) or check `.isDefined` before calling the `get`

Not to mention that calling values inside tuples using the `_1` and so on can quickly become confusing.


Unapply and case classes
------------------------

case classes automatically define both methods apply and unapply for us. this also allows us to easily do pattern matching on instances of case classes.

As we saw in previous examples, unapply can automatically be called on any case class and we pass to it the instance of the case class whose values we would like to unapply.

```scala
val result: Option[(String, Int, List[String])] = Person.unapply(fares)
```

Unapply in Pattern Matching
---------------------------

Pattern matching automatically calls the unapply method, in order to check if the values inside match a specific case.

```scala
  fares match {
    case Person(name: String, age: Int, _) =>
      if (age > 22) println(name) else println("Not Fares")
    case _ => println("Ummm") // Should not happen
  }

```


Unapply Simplified
------------------

Going back to out Person case class and fares instance.

```scala
  val Person(faresName, faresAge, faresHobbies) = fares

  println(faresName)
  println(faresAge)
  println(faresHobbies)

  //the following code yields: 
 
    fares
    23
    List(Hiking, Biking)

```

  So we pass the val names we want in the case class Person and we assign it the value of the instance.

