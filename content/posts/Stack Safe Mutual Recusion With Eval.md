+++
author = "Fares Ismail"
date = "2020-01-15T10:00:00+00:00"
tags = [
    "stack safe",
    "eval",
    "cats",
    "mutual recursion",
]
title = "Stack Safe Mutual Recursion with Eval"
+++

The first time I heard someone say: "Stack Safe Mutual Recursion using cats Eval DataType and Trampolining" I figured I'd found the ONE thing I wouldn't be able to write about, on the count of how complex it sounded.

To start with, mutual recursion is not a topic I'm comfortable with, let alone Stack Safety...

But with some time and a small exercise, the idea is getting clearer in my head. So Imma take advantage of the 5 hour flight I'm currently on to concretize the information in my head through this article :stuck_out_tongue:

From the cats documentation: ``Eval is a data type for controlling synchronous evaluation. Its implementation is designed to provide stack-safety at all times using a technique called trampolining.``

Alright so we just added more words to explain :man_facepalming:

``Mutual Recursion``: Function A calling function B who in turn will call function A that will once again call function B till the end of times... Or until a certain condition is met or value is reached.

``Trampolining``: trampolining is replacing recursive function calls with objects representing these calls. This way the recursive computation is built up in the heap instead of the stack, and it is possible to represent much deeper recursive calls just because of the bigger size of the heap.

There are 3 functions in Eval we will look into but first a quick recap on 2 notions:

1. `Lazy Evaluation`: Lazy evaluations refers to an expression being evaluated the first time it is used instead of the first time it is defined. The opposite is called eager evaluation. in Scala: ``lazy val`` is lazy (obviously...) and ``val`` is eager.

2. `Memoization`: Refers to the “memorization“ of the evaluated value. If a value is used twice, will it be evaluated twice or will it be evaluated once and its value memorized? In scala, ``def`` is not memoized, every time we call the function, it will be evaluated. In contrast, ``val`` is memoized. We only define a value once and then use it as many times as we'd like without having to recompute the value every single time.

## Evaluation Strategies

### Eval Now

Eval.now is an eager computation of the value. and its value is memoized.

From the cats documentation:

```scala

val eager = Eval.now {
  println("Running expensive calculation...")
  1 + 2 * 3
}
// Running expensive calculation...
// eager: cats.Eval[Int] = Now(7)

eager.value
// res0: Int = 7
```

### Eval Later

Eval.later is a lazy evaluation. The value is only evaluated once we call ``.value`` on the Later type.
Keep in mind that the result of the Later is memoized, so it is lazily evaluated but only evaluated once. (Think of lazy val)

From the cats documentation:

```scala

val lazyEval = Eval.later {
  println("Running expensive calculation...")
  1 + 2 * 3
}
// lazyEval: cats.Eval[Int] = cats.Later@6c2b03e9

lazyEval.value
// Running expensive calculation...
// res1: Int = 7

lazyEval.value
// res2: Int = 7

```

### Eval Always

Eval.always is the equivalent of a def in scala. In other words, it is lazy and its value is not memoized.

From the cats documentation:

```scala

val always = Eval.always {
  println("Running expensive calculation...")
  1 + 2 * 3
}
// always: cats.Eval[Int] = cats.Always@6a9ffee8

always.value
// Running expensive calculation...
// res3: Int = 7

always.value
// Running expensive calculation...
// res4: Int = 7

```

## So When Do We Use Each Strategy

- Eval.now should be used when the value to be used in the Now is already in hand or if its computation is pure and fast.

Example, assume we are delving into a spark Json object to find the Simple Values.

Keep in mind that a json object can be a Struct containing field names and other Json Objects, an Array of Json Objects or simply a Json Value (denoted JValue).

During a Lazy recursion over that object, if we reach a JValue (an object where the value is already in hand) we can call the Now.
In other cases, we'd have to go one level deeper and repeat.

As a rule of thumb, when there is no computation required, use the ``Now``

- Eval.later will evaluate the computation and cache the value.

- Eval.always will evaluate the computation every time value is required. It should only be used when we need laziness without caching. Otherwise use Later.

## Important note about stack safety

When we chain multiple computations using ``flatMap``, we are still stack safe as long as we don't nest calls to ``.value`` inside the Eval otherwise we will no longer be stack safe.

## Practical Example

So how does any of this help us? whats cool is that we can chain computations each returning an Eval and leave the actual evaluation till the end.

I mentioned Json Objects above... so why not use that as an example:

A Json Object can be:

- JValue (JString, JInt, JDouble...)

- JArray (An Array of JObjects)

- JStruct (Containing a List [(FieldName, JObject)] so a list of tuple: FieldNames and the associated JObject)

### Requirement

Assume that for some unknown and obscene reason, we were asked to traverse a Json Object and increment all the Integers by 1 and transform all the strings to: "String: " + the actual String content.

I know its weird but humor me :clown_face:

Our Domain would look like this:

```scala

sealed trait JObject
sealed trait JValue extends JObject
final case class JString(value: String) extends JValue
final case class JInt(value: Int) extends JValue

final case class JArray(elems: Seq[JObject]) extends JObject

final case class JStruct(fields: Seq[(String, JObject)]) extends JObject

```

One easy way to achieve the requirement is to do a simple recursion over the initial JObject value

```scala

  def transform(value: JObject): JObject = {
    value match {
      case JArray(elems) => JArray(elems.map(v => transform(v)))
      case JStruct(fields) =>
        JStruct(fields.map {
          case (str, jObject) => (str, transform(jObject))
        })
      case value: JValue =>
        value match {
          case JString(value) => JString("String: " + value)
          case JInt(value)    => JInt(value + 1)
        }
    }
  }

```

Took about 5 min to write and simple to read...

But the issue here is that I do not have control over the initial Json Object ill be traversing. Each call to transform will create a new stack frame and for deeply nested JObjects, we will end up with a stack overflow problem.

The more proper way of doing this is using Eval.

From what we've discussed earlier, the Eval.now should be used when we have reached a expected value.

for the rest we will continue going one level deeper searching for the JValues

```scala

  def updateJObject(jo: JObject): JObject = {
    def iterate(elems: Seq[JObject]): Eval[Seq[JObject]] = {
      Eval.always(elems).flatMap {
        case x +: xs => deepMap(x).flatMap(x => iterate(xs).map(l => x +: l))
        case Nil     => Eval.now(Nil)
      }
    }

    def deepMap(value: JObject): Eval[JObject] = {
      Eval.always(value).flatMap {
        case value: JValue =>
          value match {
            case JString(value) => Eval.now(JString("String: " + value))
            case JInt(value)    => Eval.now(JInt(value + 1))
          }
        case JArray(elems) => iterate(elems).map(JArray)
        case jstruct: JStruct =>
          val (fieldNames, jobject) = jstruct.fields.unzip
          iterate(jobject).map(ob => JStruct(fieldNames.zip(ob)))
      }
    }

    deepMap(jo).value
  }

```

### Code Breakdown

From a high level point of view, we notice there are two functions now... instead of one.

and each functions calls the other function and so on and so forth.

I've found it helpful when dealing with recursion to start with the stopping criteria.

In this case, we can look at the places where we call the Eval.now, and thats in the deepMap whenever we find a JValue. This is expected given the task at hand. notice that we could have abstracted the transformations applied on the Int or the String to another function (and it would have been better and more readable)...

Functionally speaking, we are given a JObject and we would like to traverse it and all its sub structures in order to find the JString or the JInt.

This is where the case of JArray and of JStruct come into play.

In case we have an array, we would like to go one level deeper into every element of said array, and apply the function on that element.

Calling ``deepMap`` does not help because of the accepted params. deepMap takes a JObject, but we need to pass that function a List of JObjects.

Additionally, we cannot map over every element of the Array and apply deepMap on each element, because we need to conserve the initial structure: an Array of JObjects in order to return an ``Eval[JArray[JObject]]``. Applying the map on every element would have resulted in a:
``Eval[JArray[Eval[JObject]]]`` which would no longer be compatible with the main return type of ``Eval[JObject]``

This is why we had to create another function ``iterate``.

Iterate takes a sequence of JObects and decomposes it into head and tail. It applies the ``deepMap`` function to the head, and then calls itself one more tail but this time only passing the tail as a param. Eventually, we would have applied deepMap on every element of the Seq... we append all the elements together and return an ``Eval[Seq[JObject]]``

In the case of JArray, the return of ``iterate`` is inserted into the Object JArray making the final return type ``Eval[JArray[JObject]]``

As for the JStruct, the idea is pretty similar to that of the JArray, but we had to add a small manipulation in order to be able to reconstruct the Struct using the FieldNames so we unzipped the data and re-zipped it after applying the transformations. Note that the map on an eval will retrieve the entire JObject inside the Eval, not every element of the JObject.

And this was how ``Eval`` can be used to achieve stack safe mutual recursion.

## To Test This Out

Run the below example to test the functions above:

```scala

  val identity: JObject = JStruct(
    List[(String, JObject)](
      ("Name", JString("Fares")),
      ("Age", JInt(23)),
      ("Profession",
       JArray(List[JObject](JString("Google Cloud Professional Data Engineer"),
                            JString("Apache Spark Developer"))))
    ))

  println(updateJObject(identity))

  // JStruct(List((Name,JString(String: Fares)), (Age,JInt(24)), (Profession,JArray(List(JString(String: Google Cloud Professional Data Engineer), JString(String: Apache Spark Developer))))))

```

## Some Metrics

Erik Osheim (@non) ran a benchmark to compare ``Eval``, ``TailRec library`` and ``Trampoline technic``. Here are the results (Sep. 2015):

|Benchmark                   | Mode | Cnt  |    Score |     Error | Units |
|:--------------------------:|:----:|:----:|:--------:|:---------:|:-----:|
|TrampolineBench.eval        |thrpt |   3  |23049.351 |± 3891.576 | ops/s |
|TrampolineBench.stdlib      |thrpt |   3  |11827.608 |± 1919.654 | ops/s |
|TrampolineBench.trampoline  |thrpt |   3  | 5743.017 |±  197.309 | ops/s |

Source: <https://github.com/non/cats/tree/topic/eval-call-bench> and <https://gitter.im/typelevel/cats?at=55f07c1ce30ef74f74f95d3a>
