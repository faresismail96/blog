+++
author = "Fares Ismail"
date = "2019-09-01T10:00:00+00:00"
tags = [
    "scala",
    "pattern matching",
    "fold",
]
title = "Fold vs Pattern Matching and Matching on Options"
+++

The following article is a summary of the Lambda Conf 2015 talk: Idiomatic Scala Your Options Do Not Match by Marconi Lanna <https://www.youtube.com/watch?v=ol2AB5UN1IA&t=1s>

----

Often when dealing with Options, we have a case where we want to check if a value is defined and if it is, apply a specific treatment on the value inside the option. So we end up with a code that looks something like this:

``` scala
value match {
    case Some(a) => foo(a)
    case None => bar
}
```

In this example, we patten match on the Option value. if it is defined, we call the function foo on the value inside the Some, otherwise we call bar.

and this is technically correct, however: the scala doc states that:

``` text
The most idiomatic way to use an Option instance is to treat it as a collection or monad and use map,flatMap, filter, or foreach
```

and that:

``` text
A less-idiomatic way to use Option values is via pattern matching:
```

with this in mind; the above can be re-written as:

```scala
val res = value.map(foo).getOrElse(bar)
```

another, more readable way would be using the `fold`.

```scala
value.fold(bar)(foo)
```

`fold` has the following definition and impl:

``` scala
  /** Returns the result of applying $f to this $option's
   *  value if the $option is nonempty.  Otherwise, evaluates
   *  expression `ifEmpty`.
   *
   *  @note This is equivalent to `$option map f getOrElse ifEmpty`.
   *
   *  @param  ifEmpty the expression to evaluate if empty.
   *  @param  f       the function to apply if nonempty.
   */
  @inline final def fold[B](ifEmpty: => B)(f: A => B): B =
    if (isEmpty) ifEmpty else f(this.get)
```

In other words, the value on the left (`bar` in our case) will be applied if `value` is `None`, otherwise if it is `Some`, the function of the right (`foo` in our case) will be invoked on the value inside the Option.

## Is there an even better way to do things?

I wont go into the details, but `Marconi Lanna` does in his video or his article <https://www.originate.com/thinking/stories/idiomatic-scala-your-options-do-not-match/>, but here are a few examples of code that can be better written. The below examples are taken/inspired by the video of `Marconi Lanna`.

This is a silly example and uncommon, but:

``` scala
if(something==true){
 return true
}
else {
 return false
}
```

which can easily be re-written as:

``` scala
return something
```

### Pattern Matching on boolean

```scala
condition match {
    case true => "Okay"
    case false => "Not Okay"
}
```

can be re-written as:

``` scala
if(condition) "Okay" else "Not Okay"
```

### Checking if an Option is Defined

```scala
value match {
    case Some(_)    => true
    case None       => false
}
```

can simply be re-written as:

```scala
value.isDefined
//or its alias .nonEmpty (as of scala 2.10)
```

To check the inverse, you can use: `.isEmpty`

### Filtering Values

What is we wanted to filter on an option?

```scala
// given predicate p
value match {
    case Some(a)=> if(p(a)) Some(a) else None
    case None   => None
}
```

can be simplified by calling:

```scala
value.filter(p)
// Note, Find also works in the same manner.
```
