+++
author = "Fares Ismail"
date = "2019-07-29T21:37:00+00:00"
title = "For Comprehensions Demystified"
tags  =["For Comprehension", "Scala"]
+++
A For Comprehension is a syntactic sugar for using a composition of map, flatMap and filter.

At first glance it might look complicated and difficult to comprehend. But once you get the hang of it, you'll realise it's a cool card to have up your sleeve, one that will surely make your code much more readable.

***

Lets look at the below couple functions:

```scala

def computeA(a: Int): Either\[Throwable, Int\] = ???
def computeB(b: Int): Either\[Throwable, Int\] = ???
def computeC(c: String): Either\[Throwable, String\] = ???
def computeD(a: Int, b:Int, c: String): String= ???

```

The issue here is that computeA, computeB and computeC all  return an Either of Throwable or Something.

One way to deal with this would be to check the return value of each function, make sure it is a `Right(_)` else throw an error or something (`fold`? `getOrElse`? pattern matching?)...

But this quickly becomes cumbersome and annoying. it also makes the logic somewhat harder to follow.

So here comes For Comprehensions to the rescue.

```scala

for {
    a <- computeA(1)
    b <- computeB(2)
    c <- computeC("Hi")
} yield computeD(a,b, c)

```

so what does this mean exactly? when in doubt, use Intellij's desugar option.

the above code desugarized (is that a word?) is equivalent to the following code:

```scala
computeA(1).flatMap(a =>computeB(2).flatMap(b =>computeC("Hi").map(c =>computeD(a, b, c))))
```

Of the two, I'm sure we'd all prefer reading / writing the first format... It is more concise, readable and hence less prone to errors.

***

Here is a good article on For Comprehensions in Scala official docs: [Translating for-comprehensions](https://docs.scala-lang.org/tutorials/FAQ/yield.html "Translating for-comprehensions")

it basically says that for without the yield translates into a chain of foreach.

for with yield translates into a chain of flatMap followed by a map.

```scala
for(x <- c1; y <- c2; z <- c3) yield {...}
//translates to
c1.flatMap(x => c2.flatMap(y => c3.map(z => {...})))
```

Using for with an if condition translates into a `.wihFilter` and as a fallback of `filter` if the method `wihFilter` is not available.

_One important note_ however, your methods have to have the same return type. in this case `Either[A,B]`

You cannot mix an Either return type with an Option return type.

For Options, it is less of a problem since many methods exists to transform Either to Option and vice versa (example `.toOption`, `.toRight`

_Another important note_, you could also use assignment inside the for comprehension. you also do not need to add the key word val or var ( though I dont see why you should...). All assignments inside the for are vals.

_third note (getting out of hand no?):_ When we first said for comprehensions are a sequence of `flatMap` and `filter` followed by a `map`, it is important to know that it is actually the yield that calls the map.
