+++
author = "Fares Ismail"
date = "2020-07-11T19:15:00+02:00"
tags = [
    "python",
    "dataclasses"
]
title = "DataClasses in Python"
+++

This is one of those cool features you'd probably wished you'd have known about a while back. Unless I'm the only person to not have known this from the start 🙊

DataClasses is a module that was introduced in python 3.7 and described in [PEP 557](https://www.python.org/dev/peps/pep-0557/). This module simplifies the creation of new classes by defining boilerplate code for you.

Dataclasses are classes designed to store data objects (think case classes in Scala).

Python 3.7 also provides a decorator that transforms a class into a dataclass. Simply wrap it with `@dataclass`.

To understand the usefulness of dataclasses lets look at what we normally have to do when constructing a class in python:

## The Init

Classes in python define an ``__init__`` method. This method is the constructor of the class. It is called when an instance of that class is to be created.

Here's an example:

```python
class Person:
  def __init__(self, name, age, hobbies, currently_reading = 'The Divine Comedy'):
    self.name = name
    self.age = age
    self.hobbies = hobbies
    self.currently_reading = currently_reading
```

Here we are defining a Person with a name, age, hobbies a currently_reading that is set to The Divine Comedy by default. In the init method, we take those values and we set them in the self which is supposed to represent the instance of the class.

But all this is a bit verbose and it gets quite repetitive...

### Init Using DataClass

DataClass handles all this for us. Here is the same example using DataClass:

```python
from dataclasses import dataclass

@dataclass
class Person:
  name: str
  age: int
  hobbies: List[str]
  currently_reading: str = "The Divine Comedy"
```

With this simple decorator, the init (as well as a bunch of other methods) are defined for us!

Lets take a look at some of those other methods

## The repr

Lets forget about dataclass for a moment and go back to our initial Person class. What happens if we create an instance of Person and print it?

example:

```python
p  = Person("Fares", 24, ["Skiing", "Reading"])
print(p)
```

The output would be:

``<__main__.Person object at 0x109c7a2b0>`` Clearly neither useful nor readable...

To output something useful, we'd need to define a `__repr__` method for that class:

```python

class Person:
  def __init__(self, name, age, hobbies, currently_reading = 'The Divine Comedy'):
    self.name = name
    self.age = age
    self.hobbies = hobbies
    self.currently_reading = currently_reading

  def __repr__(self):
    return (f"Person(name = {self.name}, age = {self.age},"+
      f"hobbies = {self.hobbies}, currently_reading = {self.currently_reading})")

p  = Person("Fares", 24, ["Skiing", "Reading"])
print(p)

## Person(name = Fares, age = 24, hobbies = ['Skiing', 'Reading'],
#    currently_reading = The Divine Comedy)
```

### Repr Using DataClass

This is even more tedious and boring... Buuut with dataclasses it comes out of the box by simply adding the decorator:

```python

@dataclass
class Person:
  name: str
  age: int
  hobbies: List[str]
  currently_reading: str = "The Divine Comedy"

p  = Person("Fares", 24, ["Skiing", "Reading"])
print(p)
## Person(name='Fares', age=24, hobbies=['Skiing', 'Reading'],
#    currently_reading='The Divine Comedy')
```

## eq, lt And Other Ordering Stuff

But it's not all... What if we wanted to compare two instances of the class Person? Normally we'd have to define a function: `__eq__` like this:

```python

  def __eq__(self, value):
    return (
        (self.name, self.age, self.hobbies, self.currently_reading) ==
        ((value.name, value.age, value.hobbies, value.currently_reading))
        )

old  = Person("Fares", 23, ["Skiing", "Reading"])
current  = Person("Fares", 24, ["Skiing", "Reading"])

print(old == current)
## False
```

### Eq Using DataClass

But again with DataClass this is already done for us so no need to create the eq function.

How does eq work? Same as the eq definition we declared for out Person Class: a tuple of every attribute should be equal to a tuple of other attributes. (order is the same as the one defined in the class definition)

### What about lt, gt and Other Ordering Stuff

Those are not defined by default for us but they can be!

Simply pass `order = True` to the decorator like this:

```python
@dataclass(order = True)
class Person:
    ...
```

## DataClass Decorator as a Callable

We've seen that by default we have an `init` and a `repr` and well as an `eq` but no `le` or `lt` etc... What are out options? Here is the dataclass decorator with the full list of default arguments:

```python
@dataclass(init=True, repr=True, eq=True, order=False, unsafe_hash=False, frozen=False)
```

+ `init`: defines the `__init__()` method
+ `repr`: defines the `__repr__()` method
+ `eq`: defines the `__eq__()` method
+ `order`: defines `__lt__()`, `__le__()`, `__gt__()`, `__ge__()` methods. If this is set to true, eq has to be defined.
+ `unsafe_hash`: if False, a `__hash__()` method may be generated if it is safe to do so (It can also set hash = None if frozen = False). Setting this to True will force dataclass to create the method. It is not recommended to set it to True if you do not know what you're doing 🙄
+ `frozen`: Passing frozen=True, we can emulate immutability in Python. Assigning values to the fields will raise an exception. In other words this emulates a read-only frozen instance of the class.

  There is a performance penalty when using frozen since the init will have to use ``object.__setattr__()``.

Note that if any of the mentioned methods above (`init`, `repr`, `eq`) are already present in the class, the dataclass parameter will be ignored.
If the class defines one of the order function while order is set to True, a `TypeError` is raised.

## Post Init

Sometimes in the init function, we'd like to make some extra computation. For example, assume that in our Person class, the moment where we instantiate it, we'd like to retrieve the extra details we have on that person from our database...

Normally we'd have to do something like this:

```python
def __init__(self):
    ...,
    self.extra_details = _get_extra_details(self.person_id)
```

But with dataclasses this possibility disappears. It's been replaced by a `__post_init__()` function. Post Init is a special function that allows extra processing after the init function has been called.

```python

from dataclasses import dataclass

@dataclass
class Person:
  name: str
  age: int
  hobbies: List[str]
  currently_reading: str = "The Divine Comedy"

  def __post_init__(self):
      self.extra_details = _get_extra_details(self.person_id)
```

## Customizing Specific DataClass Fields

Dataclass allows us to customize each field. For example we could chose not to include it in the init or to not include it in the repr etc...

We can do this using the specifier `field()`. Field supports multiple parameters:

+ default: Default value of the field
+ default_factory: Function that returns the initial value of the field
+ init: Whether or not to include this field in the ``__init__`` function. Set to True by default.
+ repr: Whether or not to include this field in the `repr` function. Set to True by default.
+ compare: Whether or not to include this field in comparisons. Set to True by default.
+ hash: Whether or not to include this field in the hash computation. (Default is to use the same as for compare.)
+ metadata: A mapping with information about the field. Can also be None.

Example:

```python
from dataclasses import dataclass

@dataclass
class Person:
  name: str
  age: int = field(repr= False) ## For people sensitive about their age 🤷‍♂
  hobbies: List[str]
  currently_reading: str = "The Divine Comedy"
```

## Using Slot Instead Of Dict Access

By default, the dataclass attributes are stored in dictionaries. But if you wish to optimize data access and use less memory for certain fields, you could use `slots`.

Although slots is an entire topic on its own, ill try to recap it here as quickly/simply as I can.

The attributes of a dataclass are stored in a dictionary and can be accessed through `__dict__`. This dict does not have any fixed number of attributes and we can add attributes dynamically.

Slots on the other hand has a static structure and prohibits the adding of attributes after the creation of the instance.

```python
@dataclass
class Person:
    __slots__ = ("name", "age", "hobbies", "currently_reading")
    name: str
    age: int
    hobbies: list
    currently_reading: str

p = Person("Fares", 24, ["Skiing", "Reading"], "The Divine Comedy")

p.profession = "Data Engineer"
print(p.profession)
## AttributeError: 'Person' object has no attribute 'profession'
```

And if we were not using slots:

```python
class Person:
    def __init__(self, name, age, hobbies, currently_reading = 'The Divine Comedy'):
        self.name = name
        self.age = age
        self.hobbies = hobbies
        self.currently_reading = currently_reading

p = Person("Fares", 24, ["Skiing", "Reading"], "The Divine Comedy")

p.profession = "Data Engineer"
print(p.profession) ## Data Engineer
```

So we can see that with ``__slots__`` we can no longer create attributes dynamically but the access becomes faster and uses less memory.

## Inheritance

Dataclasses can be inherited like normal classes in Python.

Example:

```python
@dataclass
class Developer(Person):
    salary: float
```

Developer will have all the attributes of the class `Person` in addition to a salary attribute.

## If you Must Remember 3 Things

1. DataClasses are special classes meant to hold data objects. They define a bunch of methods for us.
2. We have the possibility to tweak each field of the data class.
3. They are available as of Python 3.7 and immensely simplify the creation of new classes.
