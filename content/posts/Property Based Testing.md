+++
author = "Fares Ismail"
date = "2021-02-28T19:20:00+02:00"
tags = [
    "testing",
    "unit testing",
    "property based testing",
    "scalacheck",
    "scala"
]
draft = "false"
title = "Property Based Testing with ScalaCheck"
+++

Unit testing is an effective way of catching bugs and protecting our code from future bugs related to refactoring.

But with the classical unit tests (example based tests), we are restricted to the test cases we can think ok. We can only write a finite number of tests that cover a finite number of cases.

In this article I'll begin by showing the limitations of example based tests before moving to scalacheck and property based testing.

The following article is inspired by Magda Stożeks' talk in the ScalaLove 2021 conference: "Property-based testing - let your testing library work for you".

## Example Based Tests

Example based tests are a great way to test out code against a specific input and compare it with a precomputed output. Here's how a simple one might look:

```scala
  behavior of "MyFunc"

  it should "correctly compute result" in {

    val input = ???
    val res = MyFunc.compute(input)
    val expected = ???
    
    res mustBe(expected)
  }
```

In addition to allowing us to quickly test our code against a specific example, this type of tests also serves as a documentation. Anyone reading those types of unit tests can easily and quickly get a sense of what our code does and what are the cases that it handles etc...

But as I've mentioned above, they're somewhat restricted to the examples we can think of.

Assume we are computing someones' age based on birthday to authorize access to a site, we might think of testing a "happy path" where the person is above 18 years old and so should be granted access to our site, and test that if a person is below 18, their access will be denied.

But we might forget to test what happens if the person inputs a birth date that is in the future. The age will be negative and if our code does not handle that, it will lead to a bug.

Using a framework that can automatically generate test cases based on a specified properties can immensely improve our code and potentially catch unthought of bugs.

## Property Based Testing

Before we get into property based testing, lets look at what a property is.

### Defining Properties

A property is something that is always true no matter what the input is.

Here are some examples of properties:

- When computing age or distance between two points: the result cannot be negative.
- When concatenating two lists, the size of the result should be the sum of the size of both lists
- Applying reverse twice on the same list will return the original list

### ScalaCheck

ScalaCheck is a framework that allows us to automatically generate test cases using the properties that are provided.

Here is how the concatenation of two list test would look like:

```scala
import org.scalacheck.Properties
import org.scalacheck.Prop.forAll

object MainSpec extends Properties("Main") {
  property("concatLists") = forAll { (list1: List[Int], list2: List[Int]) =>
    list1.size + list2.size == Main.concatLists(list1, list2).size
  }
}
```

This will yield the following result:

```text
+ Main.concatLists: OK, passed 100 tests.
```

Essentially, ScalaCheck generated 100 test cases and ran them all against our property to validate that it holds for all test cases. In each of those test cases, scalacheck created two lists with varying numbers and lengths and ran them through our function to validate that for each case, the property holds true.

### Generators

We've seen how ScalaCheck can generate random data for our simple types like String, Int, List[String] etc... But what if your test takes a case class instance as input? In that case, we will need to supply the forAll function with a custom generator that it'll use to generate that data.

For our examples, we will look at Grade Reports. Here's how we might model one in scala:

```Scala
  final case class GradeReport(
    firstName: String,
    lastName: String,
    studentId: Long,
    coursesResult: List[CourseResult],
    generalAverage: Double,
    studentStatus: OverallStatus
  )
  final case class CourseResult(courseName: String, courseId: String, courseGrade: Double)

  sealed trait OverallStatus

  object OverallStatus {
    case object Passing extends OverallStatus
    case object Failing extends OverallStatus
  }

```

Its a pretty simplistic view, A grade report will contain information about the student, a list of courses the student has taken along with their respective grades and the students' overall status along with his average.

So how can we generate Grade Reports knowing that some fields in our GradeReport depend on others. For example, a students' overall status depends on the general average which in turn depends on the list of courses taken. Naturally, our Generator will have to take all that into account.

To generate simple fields like a name of an id:

```scala
val nameGen: Gen[String] = Gen.alphaLowerStr
```

We're using the method alphaLowerStr because we would like to restrict ourselves to the 26 characters of the english alphabet, and we'd also like to have everything in lowercase.

Here's some examples of what might get generated:

- eycp
- e
- hjsbqcyhzecjfcydyxheajplls

-

(yes the last one is an empty string)

So overall the generated values are valid strings with varying lengths.

Note that we also have out of the box generators for numeric string, alphanumeric string, constant values where the generator will always return the same value etc...

For the studentId, we can have the generator pick a value from a given range:

```scala
val studentId = Gen.choose(100L, 100000L)
// Examples:
// 98159
// 9138
// 793

```

On to more interesting generators.

How can we generate a list of ``CourseResult``? start small:

```scala
  val courseResultGen: Gen[CourseResult] = for {
    courseName  <- Gen.alphaLowerStr
    courseId    <- Gen.alphaStr
    courseGrade <- Gen.choose(0, 100)
  } yield CourseResult(courseName, courseId, courseGrade)

```

Over here, we are creating a generator for our case class. The for comprehension syntax is just a prettier representation and allows us to easily create generators for custom product types.

Then we could reuse this generator to create a list of ``CourseResult``

```scala
val listCourseResult: Gen[List[CourseResult]] = 
    Gen.listOf(courseResultGen)

// If we want to fix the list length, use:
//   Gen.listOfN(NUMBER, courseResultGen)
```

Alright... now that we have a generator for listOfCourseResult, we can calculate the generalAverage and based on that, choose a specific OverallStatus:

### Dependant Generators

A students' Overall Status should only be passing if the average of his courses is above some value (say 70%). So when generating a value, our generator needs to take into account the generated value for another field. In our case the list of courses along with their details. Here's how this might look:

```scala

  val gradeReportGen: Gen[GradeReport] = for {
    firstName      <- Gen.alphaLowerStr
    lastName       <- Gen.alphaLowerStr
    studentId      <- Gen.choose(100L, 100000L)
    courseResult   <- listCourseResult
    generalAverage <- Gen.const(courseResult.map(_.courseGrade).sum / courseResult.length)
    studentStatus  <- Gen.const(if (generalAverage >= 70) Passing else Failing)
  } yield GradeReport(
        firstName,
        lastName,
        studentId,
        courseResult,
        generalAverage,
        studentStatus
    )

```

With the above code, we are able to generate logical results that make sense.

**But there is one flaw in our design.**

If the passing threshold is 70% then we cannot really rely on a random generator for our CourseGrade. By definition, half the generated values will be below 50% and as a result (with 70% being the threshold) the majority of our students will end up ``Failing`` their years, the dean would soon demand answers and accreditation will be revoked...

Instead of relying on a random generator, we'll have to created a biased generator that will favor some values over others. Grades will most likely have a normal distribution around a class average with a relatively low standard deviation (or at least from personal experience 😛)

### Not So Random Data

Before moving on to generating biased generators, how can you verify what I've said? Prop offers a classify function that collects data about the test cases and displays them in the final result.

#### Collecting Test Data with Classify

```scala
  property("something") = forAll(gradeReportGen) { name =>
    Prop.classify(name.generalAverage < 50, "below 50", "above 50"){ 
        true 
    }
  }
```

This shows the following results:

```text
> Collected test data: 
52% above 50
48% below 50
```

And in another run:

```text
> Collected test data: 
54% below 50
46% above 50
```

So when we compare with 70?

```text
> Collected test data: 
88% below 70
12% above 70
```

This somewhat verifies it.

#### Biased Generators

One way of creating a biased generator is by using the frequency function:

```scala

val beverageGen = Gen.frequency(
    (1, Gen.const("Hot Chocolate")),
    (5, Gen.const("Coffee"))
)

```

In this case our custom Beverage Generator is biased towards coffee. 5 out of 6 times, the result will be Coffee and not Hot Chocolate. the numbers represent the results' weight.

But this is a bit harder to apply to our case since we're dealing with continuous variables and not discrete ones. Instead lets look at defining a distribution and using that to generate our data:

```scala
courseGrade <- Gen.const(Random.nextGaussian() * 10 + 70)
```

A lot of things are happening in the above line, so let's break it down:

Random.nextGaussian() will generate a pseudorandom number that has a normal distribution. Those values will have a standard deviation of 1 and a mean of 0.

To shift that to our own average, we multiply by 10 (standard deviation) and add 70.

Here are some examples of the generated values:

```text
85.84898535417973
71.96463467037076
70.75840861524729
54.78215028238531
66.1747348048266
```

and the classify result:

```text
+ Main.something: OK, passed 100 tests.
> Collected test data: 
51% above 70
49% below 70
```

Any person having taken basic math would be able to point out another flaw. With three times the standard deviation we can only garante that 99.7% of the values will fall in our acceptable range (so 99.7% of the values will be below 3*10+70 thats 100). But what of the 0.3%? well, either you say that its an acceptable test case and carry on (NO) or you still have the option to filter it during the execution of the test (more on that in the next section).
Also note that the same applies for numbers below 0 (which in our case would be an **extremely** rare case).

With this, we now have a fully functioning GradeReport Generator that produces logical values.

ScalaCheck also offers some neat features that I couldn't mention in the context of my example, but I'll list them below

## Limiting Test Cases

In some cases, we would like to exclude some test values from running through our unit test. This could either be because they are not possible in our use case or because they are not handled etc... Fortunately, ScalaCheck offers a simple way to exclude some cases:

```scala

  property("something") = forAll(gradeReportGen) { name: GradeReport =>
    name.coursesResult.map(x =>
     (x.courseGrade >= 0) && (x.courseGrade <= 100)
     ).forall(identity) ==> true
  }

```

The implication operator (==>) in this case is used to filter out the values that do not satisfy the given conditions

### Dangers in doing so

When filtering out test cases, it is important to make sure that the condition will not filter most if not all the test cases.

In some cases, the property test will fail with a similar message:

```text
Gave up after only 9 passed tests. 501 tests were discarded.
Found 1 failing properties.
```

We could also be filtering out test cases by accident that could have proved interesting.

## Labeling Test Cases

ScalaCheck has allows us to label our assertions, and it'll use those labels in the report for clearer error messages. Here is a simple example that demonstrate labeling assertions and the results:

```scala

  property("bigger than 0") = forAll { num: Int =>
    (num >= 0) :| "number should be bigger or equal to zero"
  }

```

Generates the following error:

```text
! Main.bigger than 0: Falsified after 2 passed tests.
> Labels of failing property: 
number should be bigger or equal to zero
> ARG_0: -1
```

When the same test is ran without the labels, here is the output:

```text

! Main.bigger than 0: Falsified after 1 passed tests.
> ARG_0: -1
Found 1 failing properties.

```

Note that if you're using scalacheck with ScalaTest, then the matchers will make labeling assertions irrelevant because scalacheck can use informations from the matchers to generate a report.

## Difficulties using ScalaCheck

You might not have noticed it in this article because the example was rather simple, but in my opinion one of the hardest things in property based testing is coming up with the properties to test.

Another issue is code readability. With example based testing, it is easy to understand what the code is supposed to do simply by reading the unit tests. In those cases, the unit tests act as a code documentation. This becomes a bit harder to do in Property Based Testing.

## Best Practice

Because of the above mentioned points, property based tests can easily reside in the same code base as example based tests.

Another best practice is to reproduce any bug caught by the property based test as an example based test. That way, you're sure it'll be checked again every time from this point on.

## If you must remember two things

- ScalaCheck is a framework that generates test cases to validate or invalidate some properties
- ScalaCheck can be used together with ScalaTest for better test coverage and the ability to use unit tests as code documentation
