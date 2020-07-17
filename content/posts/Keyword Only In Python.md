+++
author = "Fares Ismail"
date = "2020-07-17T06:20:00+02:00"
tags = [
    "python",
    "keyword only",
    "positional only",
    "PEP 3102"
]
draft = "false"
title = "Keyword and Positional Only Arguments in Python"
+++

My flights are now synonymous with new articles... It is a welcomed distraction from the subtle armrest war, the crammed chairs with barely any leg room and the crying babies...

Here's a small feature I recently learned about that might significantly impact your code readability: Forcing functions to take Keyword-Only Arguments or Positional Only Arguments!.

The Keyword-Only argument feature was not so recently introduced in [PEP 3102](https://www.python.org/dev/peps/pep-3102/). But as with most things, I'm discovering this a little bit too late 🤦‍♂

What this allows us to do is force a bunch of arguments to be passed by keyword only as opposed to positional arguments.

## Quick Recap

In python, there are two ways to pass arguments to a function. Either by explicitly naming them, or by arranging arguments in a specific position.

We will be using the following function for our example:

```python

def show_person(name: str, age: int, hobbies: List[str]):
    return f"""The Person is {name}, he is {age} years old and has the following hobbies: {hobbies}"""

```

### Keyword Argument

```python
show_person(name="Fares", age=24, hobbies=["Skiing","Drinking"])
```

### Positional Argument

```python
show_person("Fares", 24, ["Skiing","Drinking"])
```

### Mix of Both

We can also start with positional arguments and end with keyword arguments:

```python
show_person("Fares", 24, hobbies=["Skiing","Drinking"])

```

By default, the flavor of function calling is left to the discretion of the person calling the function.

## Forcing Behaviors

There is however a way to force callers to pass some/all arguments as keyword only (or as of python 3.8, as positional arguments only).

### Forcing Keyword Only

To force users to use keyword only arguments for either all or some of the arguments, simply add a `*` before the arguments. Anything after the `*` will be keyword only.

```python
def show_person(*, name: str, age: int, hobbies: List[str]):
    return f"""The Person is {name}, he is {age} years old and has the following hobbies: {hobbies}"""

show_person(name="Fares", age=24, hobbies=["Skiing"])
## "The Person is Fares, he is 24 years old and has the following hobbies: ['Skiing']"
```

And what happens if we pass positional arguments?

```python
show_person("Fares", 24, ["Skiing"])

## Traceback (most recent call last):
##   File "<stdin>", line 1, in <module>
## TypeError: show_person() takes 0 positional arguments but 3 were given
```

Another example of keyword only function is:

```python
def show_person(name: str, age: int, *, hobbies: List[str]):
    return f"""The Person is {name}, he is {age} years old and has the following hobbies: {hobbies}"""
```

In the above example, both name and age are allowed to be passed by either keyword or positional arguments, but hobbies is required to be a keyword argument.

### Forcing Positional Only (as of Python 3.8)

This functionality is relatively new and was introduced in Python 3.8.

The same way we can force users to call a function by only passing keyword arguments, we can also force users to call a function by only passing positional arguments.

This is done through the `/` sign in the function. Anything before that sign is required to be passed as a positional only argument. Here's an example:

```python
def show_person(name: str, age: int, /, hobbies: List[str]):
    return f"""The Person is {name}, he is {age} years old and has the following hobbies: {hobbies}"""
```

In that case, when calling the function, `name` and `age` have to be passed in positional argument only otherwise an error is returned:

```python
show_person("Fares", 24, hobbies=["Skiing"])
```

### Forcing Both

We could also require that users call a function with specific arguments in positional and the rest in keyword.

```python
def show_person(name: str, /, *, age: int, /, hobbies: List[str]):
    return f"""The Person is {name}, he is {age} years old and has the following hobbies: {hobbies}"""
```

In this case, `name` can only be passed as positional while `age` and `hobbies` can only be passed in keyword arguments.

## My Two Cents

While I see an immense benefit to using keyword only argument to improve readability, I cannot say the same thing about positional only arguments.

The only usage I see is when a function takes an obvious value and a clear name for the parameter is not so easy to come up with. But then again, some might say this is an indication that you've done something wrong in the design of your function 😛.

## If You Must Remember Two Things

+ To require users to call a function with `keyword-only` arguments, add a `*` before those arguments.
+ To require users to call a function with `positional-only` arguments, add a `/` after those arguments.
