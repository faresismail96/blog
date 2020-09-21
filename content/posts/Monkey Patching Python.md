+++
author = "Fares Ismail"
date = "2020-09-21T06:20:00+02:00"
tags = [
    "python",
    "Monkey Patching"
]
title = "Monkey Patching in Python"
+++

Asides from giving you the ability to say the words "Monkey Patch" out loud in your office, monkey patching can be a useful tool when working with external libraries. It can also be the reason why all the developers who will work on the product after you will come loath you... More on that in a bit.

For some additional clarifications, the concept is something I recently learned from someone I work with and the examples closely resemble his own... The reason I'm recopying them can be summarized in the following french quote: "Le savant reste ignorant de ce qu’il a appris tant qu’il ne l’a pas mis en pratique" - Unknown. (though in no way shape or form do I think of myself as a savant 🙄)

## What is Monkey Patching

Monkey patching is Python's ability to dynamically apply a modification (at runtime) to a class or even a module.

What does that mean and how is it useful?

Let us look at a simple example:

```python
class Cat:
    def say_hi(self):
        print("Meow")


Cat().say_hi()   ## Meow
```

The above code behaves as expected... But what if we wanted to change the behavior of the class `Cat` by modifying the greeting function?

```python

class Cat:
    def say_hi(self):
        print("Meow")

Cat().say_hi()          ## Meow

def say_hello(self):
    print("Woof")

Cat.say_hi = say_hello
Cat().say_hi()          ## Woof

```

From now on, any cat will say `Woof` instead of `Meow`

### When Is It Useful

Monkey Patching can be useful when working with a third party library and where we do not have control over the source code. Possible situation: in my python module, I import the library: `my_lib` who has a `say_hello` function that I wish to modify. Except the library and therefore the function are not directly accessible and I do not have control over the implementation.

## Different scopes of Monkey Patching

FARES: TODO talk about local affecting one instance and global, affecting all Cat (unless previously patched at instance level).

There are different types of Monkey Patching, each affecting a different scope.

- Instance level monkey patch:

In instance level patching, only the instance will behave differently, the rest of the instances will remain the same.

```python
class Cat:
    def say_hi(self):
        print("Meow")

cat1 = Cat()
cat1.say_hi()               # Meow

def say_hello():
    print("Modified Meow")

cat1.say_hi = say_hello

cat1.say_hi()               # Modified Meow
cat2 = Cat()
cat2.say_hi()               # Meow

```

- Global Patching:

Global patching is the same as the first example we've seen. In that case all the instances of `Cat` will be modified, **except those that have been patched at an instance level.**

## To Monkey Patch or Not to Monkey Patch

Beware when monkey patching, if any other piece of code calls the function you're patching, it will (depending on the patching scope) also receive a piece of the modified code.

In my opinion, monkey patching is an evil hack and should be avoided when possible. It makes the code a lot harder to read and for large projects, almost impossible to debug multiple years down the road...

I can imagine a scenario where the documentation of the library says one thing but the reality is completely unrelated... I would also imagine that the debugging process will not be fun.

Some additional issues: If two modules monkey patch the same function, one of them will get canceled out (the one that ran first). It can also lead to upgrade problems.

But to play the devils advocate, this evil might be necessary in some cases to fix existing bugs in the external library without having to fork the entire library and adding another deps to your own project.

Monkey Patching could also be very handy when it comes to testing. Where for example we might bypass a connection to some database etc...

## If You Must Remember Three Things

1. Monkey Patching is modifying a variable or a functions' behavior at runtime.
2. We can either monkey patch an instance or the entire Class and all its instances.
3. It is an evil hack that if used without caution can lead to confusion and additional bugs.
