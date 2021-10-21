---
title: "Global variables are awesome (for debugging)"
created_at: 2021-10-18
kind: article
---

Most people will tell you that global variables are a terrible idea. I agree with them, except in one situation: debugging!

A mutable global variable - anything prefixed with `$` in Ruby - is a great way of dynamically controlling a program's execution path at runtime. I do this a lot:

~~~ruby
if $debug
  binding.pry
end
~~~

Now I can conditionally control my breakpoint, which is handy if the code path is frequently executed (like in a loop) but I don't want to stop every time. After I stop
and do what I want, I can unset it:

~~~ruby
[1] pry(main)> $debug = false
[2] pry(main)> continue
~~~

... and then continue on my merry way!

Here's another situation: Today I was trying to build reproduction steps for a particularly tricky edge case. It relied on a code path encountering an exception the first time it ran, but not subsequent times, and it didn't really matter what the exception was. I dropped this into the code path:

~~~ruby
if $raise_exception
  raise "Boom!"
end
~~~

Then, my console session looked something like this:

~~~ruby
[1] pry(main)> $raise_exception = true
=> true

[2] pry(main)> SomeClass.do_a_thing

# RuntimeError: Boom!
# from (pry):2:in `<main>'

[3] pry(main)> $raise_exception = false
=> false

[4] pry(main)> SomeClass.do_a_thing
=> nil
~~~

With global variables, the debugging possibilities are endless!


