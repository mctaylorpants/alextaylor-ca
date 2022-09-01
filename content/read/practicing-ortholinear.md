---
title: Practicing Ortholinear
kind: article
created_at: 2022-08-31
---

I recently bought an [ErgoDox EZ](https://ergodox-ez.com/) keyboard. The learning curve is quite steep; not only does the split design take some getting used to, the layout is ortholinear, meaning the rows of keys are not staggered like a normal keyboard, but are arranged in a straight line:

~~~
# a typical staggered layout:
Q  W  E  R  T
 A  S  D  F  G
~~~

~~~
# an ortholinear layout:
Q  W  E  R  T
A  S  D  F  G
~~~

Ortholinear really messes with your muscle memory at first, in particular for the top and bottom rows. For example, to type 'i' on a staggered keyboard, your middle finger needs to move up and slightly to the left. On an ortholinear layout, you simply move straight up. Move too far to the left, and you might end up with a 'u' instead!

I've been using [Monkeytype](https://monkeytype.com/) regularly for typing pratice, but I wanted a way to specifically retrain my fingers for the new top row/bottom row positioning. I wanted to focus on building good habits and making sure I was always moving straight up and down with each finger instead of reaching when I shouldn't be. It occurred to me that I could focus my practice on the top and bottom rows more if I had a list of words consisting of only letters from those rows. So, I built one!

## Bash-ing together a word list
macOS ships with a dictionary file containing some 230,000+ "words". You can find it here:

~~~bash
$> cat /usr/share/dict/words | head -n 10

A
a
aa
aal
aalii
aam
Aani
aardvark
aardwolf
Aaron
~~~

After a brief Wikipedia detour to learn that an [Aardwolf](https://en.wikipedia.org/wiki/Aardwolf) is, in fact, a real creature, I used `grep` to filter the list down to only words that were composed of letters from the top and bottom rows:

~~~bash
$> cat /usr/share/dict/words \
  | grep -E '^[qwertyuiopzxcvbnm]+$' \
  | head -n 10

b
be
bebeerine
bebeeru
bebite
bebop
bebrine
bebump
becivet
becobweb
~~~

As strange as some of these words turned out to be, they made an excellent list for practicing ortholinear. I loaded this into [Monkeytype](https://monkeytype.com/) and set about typing at a ponderous pace, staring at my hands to ensure I was reaching with the right fingers. So far, so good!
