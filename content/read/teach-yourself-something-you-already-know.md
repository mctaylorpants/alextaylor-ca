---
title: Teach yourself something you already know
created_at: 2022-04-26
kind: article
---

They say the best way to learn something is to teach it to someone. What might not be obvious is: that "someone" can be yourself!

I recently read [_The 5 Elements of Effective Thinking_](https://press.princeton.edu/books/hardcover/9780691156668/the-5-elements-of-effective-thinking). The theme of the first element is "understand deeply": it's about the importance of building a strong foundation, of having a deep grasp of the fundamentals of a subject.

Here's one of the exercises from the chapter on this element:

---

> Consider a subject you think you know or a subject you are trying to master. Open up a blank document on your computer. Without referring to any outside sources, write a detailed outline of the fundamentals of the subject...

> Now compare your effort to external sources. When you discover weaknesses in your own understanding of the basics, take action. Every return to the basics will deepen your understanding of the entire subject.

---

I love the idea of this exercise. It can be a highly effective way to expose the gaps in your own knowledge. After all, that's what happens when you teach something: having to explain something to somebody else tends to highlight places where your understanding isn't as deep as you thought it was.

I thought I'd try this exercise with an area of Ruby I find myself Googling every time I come across it: destructuring, and the splat operators (`*` and `**`).

## Poking holes
With this topic in mind, I opened a new document and wrote what I knew so far. Here's what I came up with:


---

> In Ruby, destructuring is the process of extracting individual pieces of data from a data structure and assigning them to local variables. This can be done with arrays and hashes. It can be done in two situations:

> 1. With local variables: you can extract data into local variables by assigning multiple variables at the same time
> 2. With method arguments: you can collapse arrays and hashes from a method call into single arguments  (or maybe this isn't destructuring, but the splat operator is still involved)

> If you don't know how many items are in the array you're destructuring, you can use * ahead of the variable name to collect the rest of the arguments.
> You can use ** when you're dealing with hashes (Q: can you do this with local variables?)

---

Right away, this exercise led me to a few insights:

* I realized that the splat operator `*` is used in two different situations - with local variables, and in method signatures - but they feel related somehow
* I realized that the double-splat operator `**` can only be used in method signatures, _not_ for destructuring a hash (I tried this right after the exercise)

This was exciting! In just a few minutes, I had poked two holes in my tenuous understanding of the splat operators.


## Looking for answers

Armed with these questions, I went looking for answers.

After playing around with the splat `*` operator, I realized why the two different uses felt so similar: they're two sides of the same coin. When you use it in variable assignment, you're _destructuring_ an array with an arbitrary number of elements:

~~~ruby
one, *rest = [1, 2, 3]
# one == 1
# rest == [2, 3]
~~~

... but in a method signature, it's more like _restructuring_: you're collecting an arbitrary number of arguments into a single array:

~~~ruby
def array_of_args(*some_args)
  some_args
end
~~~

~~~ruby
$> array_of_args(1, 2, 3)
=> [1, 2, 3]
~~~

Next, I looked into the double-splat operator `**`. I knew this was for hashes, but now it made a bit more sense: we want our method to accept arbitrary keyword arguments and then _restructure_ those arguments as a single hash:

~~~ruby
def hash_of_args(**some_args)
  some_args
end
~~~

~~~ruby
$> hash_of_args(one: 1, two: 2, three: 3)
=> {:one=>1, :two=>2, :three=>3}
~~~

The only thing I was still curious about was why you can't destructure hashes in the same way you can destructure arrays.

It turns out that Ruby 3.0 adds just that, via [rightward assignment](https://www.fullstackruby.dev/ruby-3-fundamentals/2021/01/06/everything-you-need-to-know-about-destructuring-in-ruby-3/):

~~~ruby
a_hash = { one: 1, two: 2, three: 3 }
a_hash => {one:,two:,three:}
# one == 1
# two == 2
# three == 3
~~~

With rightward assignment, you assign local variables on the right-hand side. Wild! And our double-splat `**` operator makes a triumphant return if you have a hash with arbitrary keys:

~~~ruby
a_hash => {one:, **rest}
# one == 1
# rest == { two: 2, three: 3}
~~~

## A deeper understanding
Not only did this exercise lead me to deepen my knowledge of Ruby, but the answers I got _stuck_. The next day, I was writing some code and reached for the double-splat `**` operator, but this time I felt more confident using it. Coming up with questions before I sought answers helped make those answers resonate more than they would have otherwise.

## Now it's your turn
I highly recommend teaching yourself something you already know!

1. Think of something you already know.
2. Spend 5 minutes writing a summary of that topic, without referring to any outside sources
3. Go find answers to the questions that will inevitably arise from step 2.
