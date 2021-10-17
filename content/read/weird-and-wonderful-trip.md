---
title: "A Weird and Wonderful Trip through Ruby’s Standard Library"
created_at: 2018-12-02
kind: article
---

_Originally published on [Ruby Inside](https://medium.com/rubyinside/a-weird-and-wonderful-trip-through-rubys-standard-library-762ddcf7a908)_

![](/images/keep-ruby-weird.png){:class="pure-img"}


You’ve probably heard the news by now — [Bundler is getting merged into Ruby core](http://engineering.appfolio.com/appfolio-engineering/2018/11/26/bundler-is-built-into-ruby-260preview3)! It’s great to see that projects like Bundler, which have become so central to the Ruby experience, are becoming part of Ruby in a deep way.

It also got me thinking: what else is in there? I use Ruby primarily for writing web applications, but Ruby’s rich history as a scripting language means that there’s lots of functionality I don’t use every day, and probably lots that I don’t even know existed.

So, I decided to find out. I spent some time looking through the [standard library documentation](https://ruby-doc.org/stdlib-2.5.3/), keeping my eyes peeled for things I didn’t recognize. I found some pretty weird and wonderful things, and I wanted to share some of my favourites.

Ready for some contrived examples? Let’s go!

## Shellwords

First up: the `Shellwords` module. It provides a few nice methods which make it easier to build and parse shell commands from within Ruby.

For example: let’s say you have a filename with an apostrophe in it, and you want to use `cat` to get the contents of the file. (I did say these were contrived, didn’t I? 😉)

You could do something like this:

~~~ruby
$> filename = "Alex's Notes.txt"
$> `cat #{filename}`
~~~

But bash doesn’t like unescaped single quotes, so you end up with an error:

~~~
sh: -c: line 0: unexpected EOF while looking for matching `''
sh: -c: line 1: syntax error: unexpected end of file
=> ""
~~~

Never fear! `#shellescape` is here!

~~~ruby
$> `cat #{filename.shellescape}`
=> "Apostrophes in a filename? 🤔"
~~~

Hurray, your problem is solved! Although you might want to have a chat with whoever put that apostrophe there in the first place…

## English: for when you want less $$

Pop quiz: what does `$$` return?

If your answer is “why, the current process ID, of course!”, then I suppose you can skip this section.

For the rest of us, Ruby’s `$$` is an homage to Perl, and returns the ID of the current system process. But it’s not the most developer-friendly of names, so Ruby’s `English` module provides some helpful aliases: `$PROCESS_ID` and `$PID`.

This is a pretty small thing, but I think it’s a perfect example of Matz’s original goal with Ruby, which was to create a language that’s understood by humans first and computers second.

`English` provides a handful of these aliases. Another useful one is `$CHILD_STATUS`, which will return the exit code of the last shell command:

~~~ruby
$> `exit 42`
=> ""

$> $CHILD_STATUS   # or $? for the purists
=> #<Process::Status: pid 25566 exit 42>
~~~

## Prime

If you require the `Prime` module, Ruby can tell you if a number is prime:

~~~ruby
$> 5.prime?
=> true
~~~

Ok, cool.

But did you know that Ruby has not one, not two, but _two-and-a-half*_ implementations for determining the primality of a number?

First up, there’s `TrialDivision`, a brute-force approach which divides the number in question by other smaller numbers until it has a definitive answer.

There’s also `EratosthenesSieve`, which as you can probably tell from the name, was invented over 2,000 years ago by a Greek mathematician. Go figure!

~~~ruby
$> Prime::EratosthenesGenerator.new.take(10)
=> [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
$> Prime.take(10)   # uses Eratosthenes under the hood, by default
=> [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
~~~

*Last, and probably least — this is why there’s only two and a half, after all — we have `Generator23`. This is a special one, because it doesn’t actually generate prime numbers, but rather numbers which are not divisible by 2 or 3. This is a clever optimization invented by Mathematicians to make validating a prime more memory-efficient. As such, this generator is used by `#prime?`, along with some additional computations, to check primality.

## Abbrev

This is probably the weirdest and most wonderful module I found in my spelunking. According to the docs, `Abbrev`:

> Calculates the set of unique abbreviations for a given set of strings.

Interesting… let’s see it in action:

~~~ruby
$> require 'abbrev'
=> true

$> %w(ruby rules).abbrev
=> {
     "ruby"=>"ruby",
     "rub"=>"ruby",
     "rules"=>"rules",
     "rule"=>"rules",
     "rul"=>"rules"
   }
~~~

Give `Abbrev` an array of strings, and it will give you a hash where those words become the values, and each key is a way of unambiguously referring to that word. In the example above, since both words start with “ru”, we have to get more specific if we want to refer to one or the other.

This module is arguably limited in its use cases, but it’s elegant and wonderful nonetheless. I just love that data structure: taking advantage of a hash’s unique keys and having it point back to the original word? 👌👌

The only uses of `Abbrev` I can find are in [`RDoc`](https://docs.ruby-lang.org/en/2.1.0/RDoc/RI/Driver.html#method-i-expand_class), and [a miscellaneous script in Ruby core](https://github.com/ruby/ruby/blob/trunk/tool/redmine-backporter.rb#L578), but I imagine one could put it to good use in things that need command-line autocompletion.

Or, you could use it to write your very own Unambiguous Nickname Generator!

~~~ruby
$> names = %w(Alex Amy Ayla Amanda)
$> names.abbrev.keys.select { |n| n.length > 2 }

=> ["Alex", "Ale", "Amy", "Ayla", "Ayl", "Amanda", "Amand", "Aman", "Ama"]
~~~

From now on, call me Ale. 🍻

## Last, but not least...

Chances are you’ve made an HTTP request from your Ruby program at some point. You probably used `Net::HTTP` (or maybe another gem that uses it under the hood).

But let me ask you this — have you ever checked your e-mail with Ruby?

🥁 🥁 🥁

Introducing `Net::POP3`!

That’s right, you can check your e-mail without ever leaving IRB:

~~~ruby
$> inbox = Net::POP3.new('pop.gmail.com')
=> #<Net::POP3 pop.gmail.com: open=false>

$> inbox.start('your-email-here@gmail.com', 'supersecret')
=> #<Net::POP3 pop.gmail.com: open=true>

$> inbox.each_mail { |m| puts m.pop.split("\n").grep(/Subject/) }
Subject: Hello IRB!

$> pop.finish
=> "+OK Farewell."
~~~

---

![](/images/i-heart-ruby.png){:class="pure-img"}

---

## Conclusion

What a ride! I hope I’ve opened your mind to some new possibilities with the language you know and love. I certainly learned a ton, and digging into these weird, dusty corners of Ruby just makes me love it even more. ❤️
