+++
author = "Fares Ismail"
date = "2020-09-13T14:08:00+02:00"
tags = [
    "python",
    "typing",
    "type hints"
]
draft = "false"
title = "Resolving Circular Dependencies Due to Type Hinting"
+++

In a previous article, I've talked about type hinting and its usefulness. However I recently realized that while using typing and defining custom types, one can easily find oneself in a circular dependency loop.

Here's a case scenario:

```text
root
  |
  custom_types.py
  my_function.py

```

custom_types is the module in which we define all custom types used in my_function.py

my_function is the module in which we define all functions.

So it's clear that my_function will depend on our custom_types. But what if, in our custom_types, the value of a field is the result of a function call. A function defined in my_function.

Then we'd run into a circular dependency problem since custom_types imports my_function and my_function imports custom_types.

In general, there are no simple ways to deal with circular dependency problems and in most cases the solution is to re-write the function itself, or even re-organize the code. In our case, we could move that function to the custom_types module as a private function.

But for circular dep problems due to type hints, the typing library offers a simpler solution: a flag.

the flag `TYPE_CHECKING` is by default set to false, and static type checkers set this value to true.

With this we could reorganize our imports in python to avoid a circular dependency since type hints are only on compile type and not in runtime. So in runtime, we do not need to have a dependency on our custom type classes.

example:

```python

from module_a import a
from module_b import b

if(TYPE_CHECKING):
    from my_function import x
    from my_function import y
    from my_function import z

```
