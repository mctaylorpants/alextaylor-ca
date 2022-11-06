---
title: Writing Neovim plugins with Ruby
created_at: 2022-11-06
kind: article
---

I've been using [Neovim](https://neovim.io/) for years, but the other day I made a delightful discovery: you can write plugins in Ruby! [There's even an officially-supported library for it](https://github.com/neovim/neovim-ruby).

Let's take it for a spin and see what it can do.

## The unseen hand of RPC
Neovim's architecture supports the concept of remote plugins. These can be implemented as a process which receives RPC calls from the editor, and vice-versa. 

neovim-ruby has a [small example](https://github.com/neovim/neovim-ruby#usage) of how we can start a Ruby process and connect it to a running instance of Neovim. I took it a step further and used [pry](https://github.com/pry/pry) so I could play around in a REPL:

~~~ruby
#!/usr/bin/env ruby

require "neovim"
require "pry"

client = Neovim.attach_unix("/tmp/nvim.sock")
binding.pry
~~~

We can start Neovim and have it listen on the socket we specified...

~~~
nvim --listen /tmp/nvim.sock
~~~

... and then boot the Ruby console. And voila! We can drive Neovim from Ruby 🤩

![](/images/neovim-in-ruby.png){:class="pure-img"}

neovim-ruby gives you a nice object-oriented interface into the editor. Here, `client` is Neovim itself, and I can access the currently-visible buffer with `get_current_buf`.

This is all well and good, but let's have some more fun! Can we programatically insert a new line into the buffer? Of course we can:

![](/images/the-unseen-hand-of-rpc.gif){:class="pure-img"}

## Writing a remote plugin
Of course, booting a side process like this is fun, but not very practical. If we really want to drive Neovim with Ruby, we can write a remote plugin.

neovim-ruby lets us define a vim command as a block which will be called when that command is invoked in the editor. The "hello world" looks like this:

~~~ruby
Neovim.plugin do |plug|
  plug.command(:HelloWorld) do |nvim|
    nvim.command("echo 'Hello, world! 👋'")
  end
end
~~~

![](/images/neovim-hello-world.gif){:class="pure-img"}

Just like in our REPL, we've got access to the Neovim client itself, as the first argument to the block. If our command took arguments, those would get passed too.

## EvalRuby: my first Neovim plugin
Armed with this newfound power, I was thinking of something interesting I could do.

I always liked the "inline REPL" that Avdi Grimm uses for his [Graceful.Dev](https://graceful.dev/) (formerly RubyTapas) screencasts. It lets him write a line of code in his editor, where it can be evaluated and returned as a comment. Kind of like this:

~~~ruby
1 + 1
# => 2
~~~

That sounds fun. Let's build it!

First, we need to define our command. **EvalRuby** seems like a fitting name.

I want to be able to select one or more lines to evaluate, so my command will need to work on ranges. According to [the Neovim docs](https://neovim.io/doc/user/map.html#E177), we just need to declare this up front:

~~~ruby
plug.command(:EvalRuby, range: true) do |nvim, range_start, range_end|

end
~~~

`range_start` and `range_end` will be the line numbers of the selection, or they'll
be the same if we're only selecting a single line.

Next, we need to pull out the content so we can `eval` it! neovim-ruby gives us a handy `lines` array in the current buffer. Since this array will be zero-indexed, we need to account for that:

~~~ruby
plug.command(:EvalRuby, range: true) do |nvim, range_start, range_end|
  ruby_code = nvim
    .get_current_buf
    .lines[(range_start - 1)..(range_end - 1)]
    .join("\n")
end
~~~

Now that we've got the code, we have a legitimate excuse to use `eval`. Hopefully we trust our own input 🤓

~~~ruby
plug.command(:EvalRuby, range: true) do |nvim, range_start, range_end|
  ruby_code = nvim
    .get_current_buf
    .lines[(range_start - 1)..(range_end - 1)]
    .join("\n")

  result = begin
             eval ruby_code
           rescue => e
             "! #{e.message} (#{e.class})"
           end
~~~

To account for syntax errors, or lines that just aren't Ruby, we can rescue any
errors and spit that out as a comment, too.

Now that we've got the result, we can close the loop by appending it back
into our editor below the selection:

~~~ruby
plug.command(:EvalRuby, range: true) do |nvim, range_start, range_end|
  ruby_code = nvim
    .get_current_buf
    .lines[(range_start - 1)..(range_end - 1)]
    .join("\n")

  result = begin
             eval ruby_code
           rescue => e
             "! #{e.message} (#{e.class})"
           end

  nvim
    .get_current_buf
    .append(range_end, "# => #{result.inspect}")
end
~~~

And, behold! It works great 🎉

![](/images/neovim-evalruby.gif){:class="pure-img"}


## Conclusion
This was a fun project, and I think I'll actually get some use out of it, too; I often find myself jumping into IRB while I'm coding to try things out or demonstrate something while I'm pairing.

Now that I wield this power, I can see myself making all sorts of fun plugins.

If you want to check out the full code for EvalRuby, [I've put it up as a gist!](https://gist.github.com/mctaylorpants/04a9353583681f48d90d4ac9f58d3485)


