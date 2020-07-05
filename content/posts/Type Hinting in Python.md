+++
author = "Fares Ismail"
date = "2020-06-29T00:05:00+02:00"
tags = [
    "python",
    "typing",
    "type hints"
]
title = "Type Hinting in Python"
+++

As I turn 24, my blog is about to turn 1 year old!! :confetti_ball:

This article will mostly be a summary of the official python documentation. I have found it useful to read a documentation and then re-summarize it in my own words. (Examples are mostly theirs though)

Typing is a new module starting python 3.5 and introduced by [PEP 484](https://www.python.org/dev/peps/pep-0484/). Its goal is to introduce static types to Python.

## Table of Content

1. [To Clarify One Thing](#to-clarify-one-thing)
2. [Hello World Example](#hello-world-example)
3. [Custom Types with NewType](#custom-types-with-newtype)
    - [One thing to pay attention for](#one-thing-to-pay-attention-for)
4. [Callable Type](#callable-type)
5. [Generic Types](#generic-types)
    - [TypeVars](#typevars)
6. [Types](#types)
7. [Union Types](#union-types)
8. [Optional](#optional)
9. [If You Must Remember 3 Things](#if-you-must-remember-3-things)

---

## To Clarify One Thing

To clarify something from the start:

``` text
Python will remain a dynamically typed language,
and the authors have no desire to ever make type
hints mandatory, even by convention.
```

This is taken from the PEP's Non Goal section.

So even if type hints are available, they are not checked at runtime (even though there is a support for that through `get_type_hints()`). Instead, type hints are meant to be checked by offline type checkers or linters.

## Hello World Example

Here is how type hinting might work:

```python

def hello_human(name: str) -> str:
    return 'Hello ' + name

```

without type hints, the function would look like this:

```python
def hello_human(name):
    return "Hello " + name
```

You might be saying to yourself that it isn't much difference... But after a year of experience with Scala I can confirm that types can really make a code more readable.

## Custom Types with NewType

If the built-in types are not enough, NewType allows us to create custom types:

``` python
from typing import NewType

Url = NewType("Url", str)

website = Url("fares.codes")
```

### One thing to pay attention for

Operations on newtypes will be treated as operations on the underlying type and the result is the underlying type.

Here's an example:

```python

UserId = NewType("UserId", int)

fares = UserId(1)
emily = UserId(3)

total = fares + emily  ## Will output 4

```

So what is the point? It allows its users to pass any int when a UserId is expected, but at the same time doesn't allow them to create a UserId in an invalid way.

At runtime, the NewType expression is transformed to a regular function call and therefore no additional overhead is introduced.

> Warning: Since NewTypes do not exist at runtime, it is impossible to create subtypes of NewTypes.

example:

```python

UserId = NewType('UserId', int)

# Fails at runtime and does not typecheck
class AdminUserId(UserId): pass

```

However, it is possible to create a NewType based on another NewType:

```python

UserId = NewType('UserId', int)

ProUserId = NewType('ProUserId', UserId)

```

## Callable Type

Return type can also be a `Callable`. It follows this signature:

``Callable[[Arg1Type, Arg2Type], ReturnType]``

Example:

```python
from typing import Callable

def feeder(get_next_item: Callable[[], str]) -> None:
    # Body

def async_query(on_success: Callable[[int], None],
                on_error: Callable[[int, Exception], None]) -> None:
    # Body

```

If we don't want to declare the types of the arguments, we can use the following syntax:

``Callable[..., ReturnType]``

## Generic Types

A normal example of a sequence of UserIds would look like this:

```python

UserId = NewType('UserId', int)

def do_something(sequence: Sequence[UserId]) -> None: ...

```

But what if we wanted the input to the function to be generic?

In comes ``TypeVars``

### TypeVars

```python
from typing import Sequence, TypeVar

T = TypeVar('T')

def do_something(sequence: Sequence[T]) -> None: ...
```

Classes in python can also be generic:

```python

from typing import TypeVar, Generic

T = TypeVar('T')

class MyClass(Generic[T]):
    def __init__(self, value: T, name: str) -> None:
        self.name = name
        self.value = value

```

Type variables can also be constrained to specific types:

```python
S = TypeVar('S', int, str)
```

In that case, the type S can either be a str or an int.

Note: by default type variables are invariant, but they can be marked as covariant or contravariant by passing: ``covariant=True`` or ``contravariant=True``. Additionally, an upper bound can be specified using: `bound=<type>`.

## Types

What is the difference between the following two declarations:

```python
UserId = NewType('UserId', int)
```

and

```python
from typing import Type
UserId = NewType('UserId', Type[int])
```

or even

```python

T_int = int
UserId = NewType('UserId', T_int)
```

``T_int = int`` and ``Type[int]`` are the same thing. They allow the variable to accept a type int but to also accept `class object of int`.

While the first example, only allows the variable to be of type int.

Example from the doc:

```python
class User: ...
class BasicUser(User): ...
class ProUser(User): ...
class TeamUser(User): ...

# Accepts User, BasicUser, ProUser, TeamUser, ...
def make_new_user(user_class: Type[User]) -> User:
    # ...
    return user_class()
```

When using types, we can only pass classes, Any, type variables or a Union of those.

## Union Types

Union types are used to indicate an one of multiple types. It is used as `Union[X, Y]`. Example:

```python
Union[int, str, float]
Union[str, int]
```

## Optional

Optional allows us to define a type that can also be None. Example:

```python

def foo(arg: Optional[int] = None) -> None:
    ...

```

Note that ``Optional[X]`` is also equivalent to: ``Union[X, None]``

## If you must remember 3 things

1. Type hints make your code more readable so you should try to use them as often as you can
2. Type hints are only checked by static type checkers or linters and not during runtime
3. I just turned 24 :smile:
