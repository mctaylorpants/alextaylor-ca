---
title: The hidden features of `caller`
kind: article
created_at: 2021-11-18
---

I use Ruby's [`caller`](https://ruby-doc.org/core-2.7.0/Kernel.html#method-i-caller) feature a lot when I'm debugging and trying to figure out the stack trace of a particular code path. I used to think that it couldn't do much beyond returning the full stack trace as an Array. But it's got some tricks!

Here's the basic usage. Let's say we're debugging this code:

~~~ruby
class Tea
  def initialize(tea_name)
    @tea_name = tea_name
  end

  def prepare
    measure
    steep
    drink
  end

  private

  def measure
    puts "1 teaspoon per cup..."
  end

  def steep
    puts "Pouring water and waiting 3.5 minutes..."
  end

  def drink
    puts "Ssssip! Mmmm, #{@tea_name}."
    puts caller.map { |s| s.insert(0, "  ") } # padding
  end
end

Tea.new("Assam").prepare
~~~

When we run the file, now we can see how we got to `#drink`:

~~~
$> ruby tea.rb
1 teaspoon per cup...
Pouring water and waiting 3.5 minutes...
Ssssip! Mmmm, Assam.
  tea.rb:9:in `prepare'
  tea.rb:28:in `<main>'
~~~


## Stacktrace too long; did not read

Stacktraces can get pretty huge, especially if you're debugging something in Rails. Sometimes you just need to know the last line from the stacktrace. You could address into the array from `caller`, but there's another way:

~~~ruby
caller(1, 1)
~~~

`caller` can take two arguments: the starting index, and how many lines you want. `caller(1, 1)` returns an Array containing the last line of the stack trace. (`caller(0, 1)` would return the _current_ line, which usually isn't terribly useful.)

These two approaches - indexing the whole array vs. passing arguments - are **not** equivalent when it comes to performance. `caller` with arguments is significantly faster. [See the appendix below for proof](#appendix-performance-of-caller)!

Anyway, when we run this, we get a more focused output:

~~~
$> ruby tea.rb
1 teaspoon per cup...
Pouring water and waiting 3.5 minutes...
Ssssip! Mmmm, Assam.
  tea.rb:9:in `prepare'
~~~

## Sometimes, you want more than just a string

If you want to extract the filename, line number etc. from each line, you could do a bunch of surgery on the string itself. Or, you could use `caller_locations`:

~~~ruby
caller_locations(1, 1)
~~~

`caller_locations` has the same interface as `caller`, but it returns a [`Thread::Backtrace::Location`](https://ruby-doc.org/core-2.7.0/Thread/Backtrace/Location.html) instead of a String for each entry. Much easier than messing around with the string itself:

~~~ruby
caller_locations(1, 1)
  puts "  --> called from #{s.path} at line #{s.lineno}"
  puts "      (full path: #{s.absolute_path})"
end
~~~

~~~
$> ruby tea.rb
1 teaspoon per cup...
Pouring water and waiting 3.5 minutes...
Ssssip! Mmmm, Assam.
  --> called from tea.rb at line 9
      (full path: /Users/alextaylor/code/tea.rb)
~~~



## Appendix: performance of `caller`
I had a feeling that passing arguments to `caller` would be more performant than indexing into the whole array, since presumably `caller` wouldn't do the work of generating the whole stack trace if it didn't need to. But I wanted to prove it, so I wrote a benchmarking script:

~~~ruby
require "benchmark/ips"

MAX_METHODS = 5000

(0...MAX_METHODS).each do |num|
  define_method("method_#{num}") do
    send("method_#{num+1}")
  end
end

define_method("method_#{MAX_METHODS}") do
  Benchmark.ips do |x|
    x.report("caller")       { caller }
    x.report("caller(1, 1)") { caller(1, 1) }
    x.report("caller[0]")    { caller[0] }
    x.compare!
  end
end

method_0
~~~

This script defines 5000 methods, each one calling the next, kind of like this:

~~~
method_0 -> method_1 -> method_2 -> etc..
~~~

On the last method, it benchmarks various approaches to fetching the stack trace. Here's what we get:

~~~
Warming up --------------------------------------
        caller(1, 1)     4.614k i/100ms
           caller[0]    24.000  i/100ms
              caller    23.000  i/100ms
Calculating -------------------------------------
        caller(1, 1)     48.644k (± 2.5%) i/s -    244.542k in   5.030285s
           caller[0]    234.556  (± 2.1%) i/s -      1.176k in   5.016163s
              caller    229.167  (± 3.1%) i/s -      1.150k in   5.023069s

Comparison:
        caller(1, 1):    48643.5 i/s
           caller[0]:      234.6 i/s - 207.39x  (± 0.00) slower
              caller:      229.2 i/s - 212.26x  (± 0.00) slower
~~~

As you can see, fetching the whole stack trace in this case is **200x slower** than looking up just what you need.


