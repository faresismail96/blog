+++
author = "Fares Ismail"
date = "2021-03-30T19:20:00+02:00"
tags = [
    "python",
    "strings",
    "String Interpolation"
]
draft = "false"
title = "String Interpolation in Python"
+++

Right off the bat, I'll say this: my go to solution for string interpolation in python are f-strings. They're elegant, simple to read and even simpler to understand. But in some cases, depending on your setup, you might be forced to use another way. In this article I'll outline the different possibilities that I have come to learn exist when talking about string interpolation in python.

Note: This article is mostly me recopying what is said here: <https://www.programiz.com/python-programming/string-interpolation> (along with a bit more examples and context).

## F Strings

As I mentioned before, they're my go to interpolation. They were added in Python 3.6 and consist of prefixing the string with an f. Here's an example:

```python

name = "fares"
greeting = f"hello {name}!! Hope you're doing well"
print(greeting)
```

This results in: **hello fares!! Hope you're doing well**

anything in the braces is evaluated and added to the string. So in our example, the variable name is replaced with fares in the string.
We could also add inline operations inside the braces:

```python

print(f"The sum of 1+1 is {1+1}")

```

Which results in: **The sum of 1+1 is 2**

This is a simple example but we could also call a function etc...

### Escaping characters in f strings

What happens if we wanted to print a json string or a real braces in an f string? then we would need to escape it:

```python

message = f"the result in: {{'value':'OK'}}"

print(message)
## the result in: {'value':'OK'}

```

So to escape the braces, we need to add another braces on each end.

### Where's the catch?

While this might seem like a good solution, and in most cases it really is (about 99% of the cases), in some systems it causes more issues. Why? because the double braces on each side can get interpreted as Jinja code. In retrospect, you're very unlikely to end up with this case scenario but I did... so you'll bare with me while I enumerate the other options. (also valid solutions if you're running earlier versions of python)

## Other Options

### % formatting

% formatting is one of the oldest string interpolation. while it gets the job done, having multiple variables in your string can make readability/refactoring an issue. Here's how a simple example might look like:

```python

name = "Fares"
day = "Thursday"
message = "hello %s, today is %s" %(name, day)

print(message) # hello Fares, today is Thursday

```

The %s formats the variable as a string, %d formats the value as a digit, %f for floats, %r for `__repr__` conversion.

```python

day = 1
month = "April"
message = "today is %s %dst" %(month, day)

print(message) # today is April 1st

```

You could also apply some padding with:

```python
message = 'Hello %10s' % ('Fares')
print(message) # Hello      Fares
```

Or apply left padding:

```python

message = 'Hello %-10s how are you?' % ('Fares',)
print(message) # Hello Fares      how are you?

```

While this option is very verbose and not so readable, it still does the job and answers our Python + Jinja issue.

### Str.format()

This option is widely seen as the better alternative to % formatting, but in our specific case it cannot be used as it is not compatible with our weird setup. Nevertheless, it deserves an honorable mention.

Here's how it works:

```python

name = 'Fares'
print('Hello, {}'.format(name)) # Hello, Fares

```

What if we had multiple variables? then we can simply name them:

```python
name = 'Fares'
day = 1
month = "April"

message = "Hello {name}, We're the {date}st of {month}".format(name=name, date=day, month=month)

print(message)
# Hello Fares, We're the 1st of April
```

You can clearly see why this is preferred over the older % formatting for strings. But if you're wondering why this cannot work in our environment, its because the values to be interpolated are in `{}`, which will be in conflict with the Json brackets.

### Template Strings

The last option and in my personal opinion the best for our case is using Template String from the python standard library.

It works by defining a template with variables to be substituted, and then calling the substitute function while passing the values to be replaced. Here's an example:

```python

from string import Template
message_template = Template("Hello $name, I am $emotion")

message = message_template.substitute(name='Fares', emotion="tired")
print(message)
# Hello Fares, I am tired

```

This works well in our case and has the added value of resembling the s strings in `Scala`
