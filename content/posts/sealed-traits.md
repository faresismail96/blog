+++
author = "Fares Ismail"
date = "2019-07-31T21:00:00+00:00"
title = "Sealed Traits in Scala"

+++
A sealed trait in scala forces all the case classes/objects that wish to extend it to be in the same source file.

In other words, if `case class B` wishes to extend `sealed trait A` B has to be defined in the same file where trait A is defined.

Taking a little step back,  _What exactly is a trait?_

## Traits in Scala

Traits in scala are similar to interfaces in java.

They encapsulate methods and field definitions so that they can be reused by different classes/objects

A single class can inherit from multiple traits by `mixing` them.

While a single class can only extend one abstract class.

{{< highlight scala >}}
trait A
trait B
case class C(name: String) extends A with B
{{< /highlight>}}

Traits can include both function definition and function implementation, but there must be at least one abstract function in the trait for it to be considered as such.

Another useful note; wherever a trait is required, a subtype of the trait can be used.

{{< highlight scala >}}
trait Animal {  
  	def getName(): String
}

case class Dog(name: String) extends Animal{  
  	override def getName(): String = name
}

case class Cat(name:String) extends Animal{
  	override def getName(): String = name
}

val l: List[Animal] = List(Cat("Blacky"), Dog("Verra"))
{{< / highlight >}}

Notice how we were able to pass a list of Cat and Dog to a list of Animal?

Why are traits useful?

Traits allow you to model behavior and reuse functions across multiple classes that could potentially be unrelated.

## Sealed Traits In Scala

As mentioned earlier, sealed traits can only be extended by classes in the same source folder as the trait itself.

This makes the code easier to read because we would have the trait as well as all the classes that extend it, in once file. As opposed to having to look for the subtypes across the project files.

to make a trait sealed, we just need to add the keyword `sealed` before it.

{{< highlight scala >}}

sealed trait Database[A] {
  	def insert(value: A)
  	def delete(value: A)
  	def update(old: A, `new`: A)
}

case class Person(name: String, age: Int, hobbies: List[String])
case class Animal(name: String, color: String, owner: Person)

case class LocalDatabase() extends Database[Person] {
  	override def insert(value: Person): Unit = ???
  	override def delete(value: Person): Unit = ???
  	override def update(old: Person, `new`: Person): Unit = ???
}

case class MongoDB() extends Database[Animal] {
	override def insert(value: Animal): Unit = ???
  	override def delete(value: Animal): Unit = ???
  	override def update(old: Animal, `new`: Animal): Unit = ???
}

{{< / highlight >}}

Another important benifit of using sealed traits is `exhausiveness checking`. During pattern matching, the compiler can check and make sure that the cases cover all the basis and that no case is left unhandeled.

Assume we were living in a world where only the following 3 shapes existed:

{{< highlight scala >}}

sealed trait Shape
object Circle extends Shape
object Line extends Shape
object Rectangle extends Shape

{{< / highlight >}}

if we were to do a pattern matching on a function that returns a shape while omitting one case:

{{< highlight scala >}}

sealed trait Shape
object Circle extends Shape
object Line extends Shape
object Rectangle extends Shape

object ShapeArea{
  	def getType(value: String): Shape = ???
  	val name = "Circle"
  	getType(name) match {
    	case Circle => // do something
    	case Line   => // do something
  	}
}
{{< / highlight >}}

we would get the following warning:

    Warning: match may not be exhaustive. It would fail on the following input: Rectangle

    getType(name) match {