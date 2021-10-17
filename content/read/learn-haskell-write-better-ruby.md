---
title: Learn Haskell, Write Better Ruby
kind: article
created_at: 2018-06-24
---

_Originally published on [Medium](https://medium.com/@mctaylorpants/learn-haskell-write-better-ruby-8e22d5ce92dd)_

Over the past several months, I’ve been working my way through [Haskell Programming from first principles](http://haskellbook.com/) with a local meetup. Learning Haskell with some experienced mentors and other beginners like myself has been a great way of getting comfortable with functional programming paradigms, and it’s been a lot of fun so far.

I write Ruby every day, so I can’t go and apply Haskell at work any time soon, but learning another programming language is kind of like traveling the world: it broadens your horizons and gives you new perspectives on your everyday life.

Despite the differences between the two languages, I would argue that knowing a bit of Haskell (or another functional programming language) can give you a new perspective on Ruby, and help you write more robust code.

I’m still very much a junior Haskell developer, but I wanted to share some my thoughts so far on how we can apply some of Haskell’s principles and approaches to our everyday Ruby.

## Haskell TL;DR

Haskell is a purely functional programming language, which means functions are a first-class citizen. Side effects are also tightly controlled: Haskell encourages you to write the majority of your code in the form of pure functions — which always return a predictable output given a set of inputs — and ensures that you explicitly declare when you’re expecting a side effect like reading from a database or writing to a file.

Haskell is also a typed language: functions must declare what kind of data they’re expecting, and what they’re going to return.

## Welcome to the World of Types

A couple weeks ago I was debugging an issue in our Rails app. The error manifested itself in a way all Rubyists are probably all too familiar with:

~~~
undefined method 'something' for nil:NilClass
~~~

The root cause turned out to be a method which was written to check an attribute and return true or false based on its value. The problem was — you guessed it! — it could _also_ return `nil`. As a result, a value intended to be a boolean was passed around in the code, supposedly driving other logic based on its boolean-ness, until eventually it caused a distant method to also return `nil` instead of some expected object.

Types make this kind of error impossible. When you work with types, you place constraints around what kinds of values a function should accept, and what kind of value it returns. In Haskell, we might write a function’s type signature like this:

~~~haskell
isAdmin :: User -> Bool
~~~

We can’t get types in Ruby (although there are [efforts underway](https://medium.com/byteconf/stripe-is-building-a-ruby-typechecker-d6cd7cee6abf) to change this), but thinking in types is still tremendously beneficial. Types provide a contract for each and every function in your application: you give me these things, and I’ll return you this other thing. The more we can be aware of the types of data flowing around our application, the easier it will be to spot the subtle bugs that creep in when an argument to a method isn’t what the method expects.

## Sharing Behaviour

In Ruby, we have two ways of sharing behaviour between different classes of objects: composition and inheritance. Composition is especially useful for providing a common interface between different objects. `Comparable` is a great example; this mixin offers basic comparison functions like greater-than >, less-than <, etc:

~~~ruby
1 < 2
=> true

4 == 3
=> false
~~~

With `Comparable`, we get 6 methods _for free_, as long as we adhere to the [contract laid out in the docs](https://ruby-doc.org/core-2.5.1/Comparable.html):

> “The class must define the `<=>` operator, which compares the receiver against another object, returning -1, 0, or +1 depending on whether the receiver is less than, equal to, or greater than the other object.”

In other words, all we have to do to add `Comparable` behaviour to our own objects is to `include Comparable` and implement a method called `<=>`.

Haskell offers similar functionality via Typeclasses. You can think of Typeclasses as a way of adding behaviour to types. It’s an interesting way of bridging the divide of data and behaviour.

Haskell’s suite of comparison functions is called `Ord`. Lots of types already have “instances” of the `Ord` class, the various numerical types (Integer, Float, etc) being obvious examples. But you can add Ord to any type, so long as you [follow the rules](http://hackage.haskell.org/package/base-4.11.1.0/docs/Prelude.html#t:Ord):

> “Minimal complete definition: either `compare` or `<=`”

As long as we define one of those two functions ourselves, we’ll get all the other comparison functions for free. What’s more, we can take advantage of polymorphism: we can write functions that receive some kind of value which implements `Ord`, without specifying a concrete type.

We can do this easily in Ruby, since there are no types. You can pass anything you want! But if we want to check that a given object adheres to a given contract before calling something, we might use `respond_to`:

~~~ruby
def greater_than?(x, y)
  return unless x.respond_to?(:>) && y.respond_to?(:>)

  x > y
end
~~~

You don’t need to do this in Haskell, because the compiler will complain if you try to pass a value which doesn’t implement `Ord`, which means you don’t have to write all that defensive code!

~~~haskell
isGreaterThan :: (Ord a) => a -> a -> Bool
isGreaterThan x y = x > y
~~~

This function will compare two values that are passed in, and check if the first is greater than the other, so long as both values are of the same type, and that type implements `Ord`. We can use this with two integers, two floats, two boolean values, etc.

I’ve found that working with types gives me more perspective and awareness when working in a dynamically-typed language like Ruby. When you’re always thinking about types, you’re likely to be more careful about how you pass values around your program.

We don’t have a compiler in Ruby to tell us when we’ve made a mistake, but the next best thing might be to fail fast at runtime:

~~~ruby
 def greater_than?(x, y)
  raise TypeError unless x.respond_to?(:>) && y.respond_to?(:>)

  x > y
end
~~~

## Chaining Behaviour with Function Composition

Lots of methods in Ruby allow you to chain together behaviour:

~~~ruby
["world", "functional", "hello"]
  .reverse
  .join(" ")

=> "hello functional world"
~~~

Here we start with our input data, an array of strings, and apply a series of transformations to it from left to right. This works because each method returns an object, and each object responds to the next message: an Array knows how to `#reverse` itself, and how to `#join` its components into a String.

Transformations in Haskell work by passing data into functions, instead of calling methods on objects. And Haskell provides a handy operator that makes it easy to chain functions together. Here’s the same operation in Haskell:

~~~haskell
let x = (concat . intersperse " " . reverse) ["world", "functional", "hello"]
-- "hello functional world"
~~~

The first thing you might notice is that it’s backwards from Ruby: our input data is on the right. This feels weird at first, but it actually makes a lot of sense: in the example above, we’re assigning this operation to a variable named `x`. So, our data is flowing from right to left and into `x`.

This illustrates how method chaining differs from function composition: with function composition, we’re using the output of one function as the input to another, and so on and so on until we get the result we want. With method chaining, we’re limited by the methods available on each object. So, if we want to transform an array using our own custom methods, it’s not so easy.

But as of Ruby 2.5, there’s a fancy new way to achieve the power of function composition without too much hassle: `#yield_self`. This powerful new method lets us use the output of one block as the input to the next, which means we have complete control over how we transform our data. Let’s rewrite the above example using `#yield_self`:

~~~ruby
["world", "functional", "hello"]
  .yield_self { |a| a.reverse }  # `a` is the original array
  .yield_self { |a| a.join " " } # now `a` is the reversed array

=> "hello functional world"
~~~

(Here we still rely on methods available on the object, like `#reverse` and `#join`, but you can imagine the possibilities now that a block is available to us.)

Using function composition can make data transformation more explicit, and often reduces the number of intermediate steps you need to take to accomplish such a series. Give it a shot in your own code!

## Explicit Side Effects

Pure functions are the holy grail of programming: if you can guarantee that your function will return _exactly the same output_ for a given input, you’ve got code which is easy to test, robust, and extremely unlikely to break. Of course, in the real world, we need to cause side effects to make any kind of meaningful program: we need to respond to a network request, get the current time, read and write to a database, etc.

But as it turns out, a great majority of the work our programs need to do can be expressed as pure functions; it’s often only at the boundaries that we need side effects.

In Ruby, we can reach out and touch the outside world any time we want:

~~~ruby
def say_hello(name)
  puts "hello " + name
end
~~~

This method has a side effect: it prints data to the screen. However, nothing aside from knowing what `puts` does will tell you that this is happening. As a result, it’s quite easy to trigger side effects at any time, which can lead to surprising errors and make testing difficult. Hands up if your Rails app reads from the database while rendering a view? 🙌

Haskell requires us to explicitly declare in our type signature that we’re no longer in pure-function territory. The most common way of doing this is with the IO monad:

~~~haskell
sayHello :: String -> IO String
sayHello name = do
  putStrLn ("hello " ++ name)
  return name
~~~

The `sayHello` function takes one string argument. It then prints “hello &lt;name&gt;” to the screen, and returns the string. Essentially, it’s a function which takes a string and returns a string — except, it performs a side effect: `putStrLn` causes text to be written to the user’s console. We declare this by wrapping the return string in an IO monad. Effectively, we’ve given this function a contract saying that it will return a string on the condition that the side effect is acknowledged.

The result of this declaration is that anywhere in our code where we invoke `sayHello`, we need to accept the contract that IO requires of us. Now we’ve got traceability: we can know with absolute certainty where in our application we’re performing side effects.

Controlling side effects is the key to a more predictable, testable application. Minimizing their use and emphasizing their location can go a long way, especially in a dynamic context like Ruby. We don’t have the same kind of tools in Ruby for managing side effects, but we can always keep our eyes open and apply a little discipline.

## Wrapping up

We’ve just scratched the surface of Haskell’s features, but I hope this gives you a taste for what it’s like. There’s an [online REPL](https://repl.it/languages/haskell) if you want to play around a bit more.

I’ve really enjoyed learning Haskell so far. If you’re like me and are more comfortable with object-oriented or imperative paradigms, it can be a bit mind-bending at times, but any momentary confusion is a good sign: it means you’re rewiring your brain to think in a different way, opening yourself up to more ways of solving problems.
