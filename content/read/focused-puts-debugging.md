---
title: "Focused `puts` debugging with STDERR"
created_at: 2018-03-23
kind: article
---

_Originally published on [Medium](https://medium.com/rubyinside/focused-puts-debugging-with-stderr-5343655255ed)_

I’m a big fan of `puts` debugging when I’m trying to reproduce a particularly tricky bug, or I want to quickly get a sense of the code path of some action. Sprinkling log lines throughout your code is pretty low-tech, but extremely effective! (As long as it doesn’t end up in master, right? 😉)

This method of debugging becomes especially useful when examining something below your own code, in a gem for instance. You can use `bundle open <gem>` to open the gem code in your editor, then stuff those `puts` in there! (Sidenote: once you’re finished with your hackery you can use `gem pristine <gem>` to undo all your changes.)

One thing that can get in the way of this style of debugging is the other log messages on your console. By default, `puts` outputs to STDOUT, along with... well, pretty much everything else on a running development server. If you’re using Rails, your little line of debug logs are probably going to get buried in an avalanche of SQL, request/response logging, etc.

The other day I thought of a quick way of making your debug lines stand out without going through too much effort: use STDERR!

A lot of command line programs take advantage of STDERR to separate errors from output. But most web servers will just output all their logs to STDOUT by default.

This is good for us, because we can put the stuff we care about on STDERR...

~~~ruby
def my_method(*args)
  $stderr.puts "Hello from #my_method!"
  
  # ...
end
~~~

... and temporarily silence STDOUT, like the Solo button on a mixing board:

~~~sh
bin/rails server 1>/dev/null
~~~

For those not familiar, `1>/dev/null` will redirect a program’s STDOUT to `/dev/null`, the glorious black hole of silence. All you’ll see when running your server will be output from STDERR, which is most likely just your own lines.

I found this to be a really useful way of focusing in on your log messages while you’re troubleshooting. I hope it helps you too!

Also, since I’m talking about `puts` debugging, I would be remiss if I didn’t mention 
[Aaron Patterson’s excellent post on the topic](https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer.html). `puts` debugging for life.
