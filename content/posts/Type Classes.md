+++
author = "Fares Ismail"
date = "2019-10-14T12:00:00+00:00"
title = "Type Classes In Cats"
draft = "true"
tags = ["Type Classes"]
+++

_Note_: _This article is long from being complete. But I will be adding content to it the more I learn about cats_

1. Semigroup: Defines an associative binary operation (combine)

2. Monoid: Semigroup + empty (allows the collapsing of a list for example by providing an initial value to a fold)

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
    In the case of an `Either` and depending on the version of `scala`/`cats` the map is `Right Biased`

    In other words, the idea is to apply a `pure` function `f: A -> B` to an `effectful` value: `F[A]`

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
