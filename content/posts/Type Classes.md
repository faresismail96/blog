+++
author = "Fares Ismail"
date = "2019-10-14T12:00:00+00:00"
title = "Type Classes In Cats"
draft = "true"
tags = ["Type Classes"]
+++

_Note_: _This article is long from being complete. But I will be adding content to it the more I learn about cats_

I will join to each type class a phrase "In layman's term" or in other words the phrase that I use to better understand the type class.

1. Semigroup: Defines a guaranteed associative binary operation.
    My way: A Semigroup for a type A defines a combine operation that takes two values of type A and return one value of the same type A.

2. Monoid: Semigroup + empty (allows the collapsing of a list for example by providing an initial value to a fold)
    My way: Empty is like the identity operator in a sense that when it is combined with any other instance of that type, it returns the other instance.

3. Functor: type class that abstract over a type constructor, takes a function and maps this function over every element in the `fa`.
            Ex. Functor of List, Option, Future...

    ```scala
    trait Functor[F[_]] {
    def map[A, B](fa: F[A])(f: A => B): F[B]
    }
    ```

    Must obey 2 laws:

    1. Mapping with `f` and then mapping with `g` is the same as mapping with the composition of f and g `fog`
    2. Mapping with the identity is a no-op (returns the same `fa`)

    In the case of `Option` the map is only applied on the `Some` otherwise it returns a `None`
    In the case of an `Either` and depending on the version of `scala`/`cats` the map is `Right Biased` as of scala 2.12.x, map on an either is right biased (same as cats)

    In other words, the idea is to apply a `pure` function `f: A -> B` to an `effectful` value: `F[A]` // WUUUUT???????????

4. Applicative:

    Applicative extend Functor with a `pure` and an `ap` methods.

    ```scala
    trait Applicative[F[_]] extends Functor[F] {
    def ap[A, B](ff: F[A => B])(fa: F[A]): F[B]

    def pure[A](a: A): F[A]

    def map[A, B](fa: F[A])(f: A => B): F[B] = ap(pure(f))(fa)
    }
    ```

    The method pure wraps the value around a type constructor. For example, for Options, this would be `Some(_)`
    The method ap (also denoted as <*>):

    From a first look at the signature of `ap`, we can see that it takes a function wrapped inside a Type Constructor `F[A=>B]` and takes an F[A] and returns an F[B]

    So `ap` applies the function inside the type `F` to the value inside the same type `F`

5. Traverse:

    Used to traverse a structure with an effect.
    So whats the difference between traverse and a map? Traverse is an abstraction over things that can be traversed over.

6. Monads:

7. Comonad:

8. Alternative:

9. Bifunctor:
