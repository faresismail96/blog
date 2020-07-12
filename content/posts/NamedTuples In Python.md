+++
author = "Fares Ismail"
date = "2020-07-12T09:15:00+02:00"
tags = [
    "python",
    "named tuples"
]
title = "Named Tuples In Python"
+++

This cool little feature has been out since Python 2.6 but I'm only discovering this now 🤦‍♂

Before we begin, let us take a quick look at tuples in python and how they work:

```python

def _get_person_from_db(user_id):

    person_name = ... ## Something
    person_age = ...  ## Something

    return (person_name, person_age)

res = _get_person_from_db(0)

print(f"""Person {res[0]} is {res[1]} years old!""")

```

Above, the function returns a tuple consisting of a name and the persons age. This result is stored in `res` and we access it like a list.

Another syntax would be to unapply the returned value into two other values:

```python
(name, age) = _get_person_from_db(0)

print(f"""Person {name} is {age} years old!""")
```

But this can lead to some errors where while tuples consisting of multiple values, we might forget one or two making the returned values sometimes incoherent and potentially causing bugs.

In such cases, `NamedTuples` can improve readability of the code by explicitly defining names to each tuple value.

NamedTuples is part of the Collections module and was introduced in Python 2.6

Here is a quick example on how it works:

```python
def _get_person_from_db():
    Person = namedtuple("Person", ["name", "age"])
    p = Person(name="Fares", age=24)
    return p

person = _get_person_from_db()
print(person.name) # Fares
print(person.age) # 24
```

Essentially namedtuples add the possibility to access fields by name instead of by index and therefore create a more readable and self documenting code.

Additionally, namedtuple defines a default ``repr`` function for us where the fields are shown next to field name. For the previous example, the result would look like this:

```python
# Tuples:
('Fares', 24)

# NamedTuples:
Person(name='Fares', age=24)
```

Clearly using namedtuples is a lot more readable. But it gets better, where you can use a tuple, you can also use a namedtuple. NamedTuples are also accessible by index so this might spare you the need to refactor your existing code:

```python
def _get_person_from_db():

    Person = namedtuple("Person", ["name", "age"])
    p = Person(name="Fares", age=24)
    return p

person = _get_person_from_db()

print(f"""Person {person[0]} is {person[1]} years old!""")
# Person Fares is 24 years old!
```

What if while instantiating the namedtuple, we passed it the wrong keyword argument?

```python
def _get_person_from_db():

    Person = namedtuple("Person", ["name", "age"])
    p = Person(name="Fares", age=24, unknown_keyword=2)
    return p
## TypeError: __new__() got an unexpected keyword argument 'unknown_keyword'
```

So we are restricted to the field_names we define when creating the namedtuple.

Another interesting thing to know: Instead of passing field names as a list of strings, we could pass a space separated string of field names and it'll break it up into separate field names:

```python
def _get_person_from_db():

    Person = namedtuple("Person", "name age")
    p = Person("Fares", 24)
    return p

person = _get_person_from_db()

print(person)
# Person(name='Fares', age=24)
```

We can also pass a dictionary as field_names:

```python
def _get_person_from_db():

    Person = namedtuple("Person", {"name": "Emily", "age": 24})
    p = Person("Fares", 24)
    return p

person = _get_person_from_db()

print(person)
```

It only takes the dict keys and ignores the values.

In addition, NamedTuples can easily be converted to dictionaries through the `._asdict()` function:

```python
print(person._asdict())
# OrderedDict([('name', 'Fares'), ('age', 24)])
```

We can access all the fields with `._fields`

```python
print(person._fields)
# ('name', 'age') : Tuple with fields in it
```

We can replace a field value with `._replace(...)`

```python
print(person._replace(age = 23))
# Person(name='Fares', age=23)
```

**Note**: The replace is not capable of changing the actual tuple object. Instead it returns a new instance with the updated value. to benefit from this, we need to assign the result to another value:

```python
person._replace(age=23)
# Person(name='Fares', age=24)

person = person._replace(age=23)
# Person(name='Fares', age=23)
```

## If You Must Remember 2 Things

+ NameTuples improve readability of your code
+ NameTuples can be used wherever Tuples can be used
