+++
author = "Fares Ismail"
date = "2019-10-14T12:00:00+00:00"
title = "Type Classes In Cats"
+++

_Note_: _This article is long from being complete. But I will be adding content to it the more I learn about cats_

1. Semigroup: Defines an associative binary operation (combine)

2. Monoid: Semigroup + empty (allows the collapsing of a list for example by providing an initial value to a fold)

3. Functors: type class that abstract over a type constructor, takes a function and maps this function over every element in the `fa`.
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

4. Applicative:

5. Traversable:

6. Monads:

7. Comonad:

8. Alternative:

9. Bifunctor:
