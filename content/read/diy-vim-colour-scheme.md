---
title: "Hacking up a vim colour scheme"
kind: article
created_at: 2022-08-19
---

For our hackathon this week at Clio, the theme was "purple," so I thought I'd try my hand at making a colour scheme for vim. I've never really messed around with colours in the terminal before – beyond the odd highlighted line in a script – so I figured it would be a fun way to learn more about how ANSI colours work and how vim goes about implementing syntax highlighting.

Let's dive in!

## ANSI escape codes: confounding programmers since 1979
vim, and other terminal programs, use [ANSI escape codes](https://en.m.wikipedia.org/wiki/ANSI_escape_code) to render colours to the terminal. They look like this:

~~~
ESC[38;5;9m
~~~

That's the "escape" character (`\e` in Ruby), followed by an opening square bracket `[`. Then comes the code:

- `38` means "set the foreground colour";
- `5` means "we're gonna use 8-bit" (you can use `2` to specify a series of RGB values instead);
- `9` means "use colour number 9", which is red;
- and `m` means "OK, we're done - what comes next is real text."

... but we're not done yet! We need a way to tell the terminal to stop using red and go back to the default colour - otherwise everything would be red 'til the end of time. To do that, we use a stop code:

~~~
ESC[0m
~~~

Putting it all together, it would look something like this:

~~~
ESC[38;5;9m hello world! ESC[0m
~~~

... or, in Ruby:

~~~ruby
puts "\e[38;5;9m hello world! \e[0m"
~~~

As for the colours themselves, 8-bit colours can be specified by using the numbers 0 through 255. I'm used to specifying colours with an RGB value or a hex value, so it was definitely not intuitive to select the right colour I needed. [There's a handy table on Wikipedia](https://en.m.wikipedia.org/wiki/ANSI_escape_code#Colors) that lists the colour codes, but for fun I wrote a little Ruby script to output them all for me, because Hackathon!

~~~ruby
# Reference: https://en.m.wikipedia.org/wiki/ANSI_escape_code
def fg(text, colour)
  "\e[38;5;#{colour}m#{text}\e[0m"
end

def bg(text, colour)
  "\e[48;5;#{colour}m#{text}\e[0m"
end

(0..255).each do |index|
  puts "#{index}\t🎨 #{bg("hello world!", index)}"
  sleep 0.05
end

(0..255).each do |index|
  puts "#{index}\t🎨 #{fg("hello world!", index)}"
  sleep 0.05
end
~~~

![](/images/colours-rb.png){:class="pure-img"}


## Syntax highlighting in vim
vim defines a bunch of "highlight groups" that work kind of like CSS classes: any text that belongs to that group will get the same style treatment. So defining your own colour scheme is a matter of telling vim what colours you want for each group.

~~~
highlight Normal ctermbg=9 ctermfg=15
~~~

This `highlight` command will set the "Normal" group to use white text on a red background. "Normal" is the base layer; any text that's not part of another group will receive this style.

You can run this command at any point in a vim session, but using that for a whole theme would be tedious! There's a `colors` folder where the default themes are defined, so that's where I started hacking on mine - I just made a new `.vim` file in there. (You can get to the folder by running `:e $VIMRUNTIME/colors`).

## Whack-a-mole
So, now I knew how to specify a colour, and how to apply it to some text. Time to figure out how to put a theme together!

The highlight groups aren't always the most intuitively-named, so it's tricky figuring out how to change the colour of the thing you're looking at. For example, the `Constant` group highlights literals in Ruby – such as numbers, strings and symbols – while the `Type` group is for _actual_ Ruby constants (which includes class names).

It definitely felt like whack-a-mole at times, because not only was I unfamiliar with the colour codes, I also didn't know which highlight groups styled each part of the code. I reduced the variables for myself by choosing a group, and highlighting it in `200` pink so I could see what lit up.

I also wanted a quick way to reload my theme each time I made a change, so I made two little shortcuts:

~~~
map <leader>c :source $VIMRUNTIME/colors/test.vim<CR>
map <leader>d :colorscheme solarized<CR>
~~~

`source` will evaluate the contents of that file, so by hitting `<leader>c` I could load up my new theme. `<leader>d` would flip back to my current theme, [solarized](https://github.com/altercation/vim-colors-solarized), for comparison. (`<leader>` is a vim hotkey which can be customized to your liking; I use the apostrophe `'`). With these two shortcuts in hand, I could quickly compare how my theme was coming along using a test file:


![](/images/vim-colour-compare.gif){:class="pure-img"}


## I purple you 💜
Since the Hackathon theme was purple, I needed a name that was on-theme. I settled on "borahae", which is a Korean portmanteau of "bora 보라" (purple), and "saranghae 사랑해", ("I love you"). So, it roughly translates to "I purple you!" It was coined by a member of the K-pop band [BTS](https://ibighit.com/bts/eng/), who you should all listen to because they're awesome.


## The finished product
[`vim-borahae` is up on Github](https://github.com/mctaylorpants/vim-borahae)! I would consider it _extremely_ alpha but it was a fun project to learn a bit more about ANSI colours and customizing vim.

![](https://user-images.githubusercontent.com/7259082/185664193-6faf62c8-7fa1-4cc5-a97b-73d1bba2c023.png){:class="pure-img"}
