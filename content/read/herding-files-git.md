---
title: "Herding Files — and goats — with git"
created_at: 2020-02-27
kind: article
---

_Originally published on [Clio Labs](https://labs.clio.com/herding-files-and-goats-with-git-a2b70c0e787a)_

`git` is a wonderful tool for version control. As codebases grow and evolve, the history that builds up with each successive change becomes crucial to understanding past decisions in order to refactor code.

Normally, you don’t need to think much about how git keeps track of your changes — you commit, you push, and you’re done. But if you’re refactoring code in a way that involves renaming files, you need to exercise caution to avoid accidentally clobbering the history.

So how can you safely refactor your code and shuffle files about, keeping all of that precious history in the process?

I’m about to tell you. And I’m going to use goats.

## A tribe of goats

Let’s imagine we have a tribe of goats. These are mountain goats, so they live on a mountain. [Grouse Mountain](https://www.grousemountain.com/), to be exact.

![](/images/goats.png){:class="pure-img"}


Here’s what one of our goats look like under the hood:

~~~ruby
# app/models/goat.rb
class Goat
  def call
    "mbaaaahhh"
  end
end
~~~

You can’t tell by looking at it, but these goats are _definitely_ on Grouse Mountain. We know that because for a long time, Grouse Mountain was the only mountain with goats, so we saw no reason to be explicit about it anywhere in our code.

However, let’s say we recently acquired a new tribe of goats. These goats live on [Bear Mountain](https://www.bigbearmountainresort.com/), near Los Angeles. (It’s unclear why goats chose to live on a mountain named after bears, but we won’t get into that.)

What we’re concerned about is making sure we keep these goats separated at first, so they don’t steal each other’s food and start an inter-mountain goat war.

To do that, let’s wrap our Grouse Mountain-living goat in a module so we can tell them apart:

~~~ruby
# app/models/goat.rb
module Grouse
  class Goat
    def call
      "mbaaaahhh"
    end
  end
end
~~~

Since we like our file paths to match our class names, we should also move this goat into another directory:

~~~bash
$> mkdir -p mountains/grouse/app/models/grouse
$> mv app/models/goat.rb mountains/grouse/app/models/grouse/
~~~

Now, all that’s left to do is commit these changes. But first, let’s have some fun!

~~~bash
$> alias goat=git

$> goat add .
$> goat status

On branch goat-namespace
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
 deleted:    app/models/goat.rb
 new file:   mountains/grouse/app/models/grouse/goat.rb
~~~

Hmm, this is a bit of a red flag. `git` thinks that we’ve deleted our original class, and made an entirely new one in another location. Let’s keep going and see what happens:

~~~bash
$> goat commit -m "move the goat"
[goat-namespace aa6d0f5] move the goat
 2 files changed, 7 insertions(+), 5 deletions(-)
 delete mode 100644 app/models/goat.rb
 create mode 100644 mountains/grouse/app/models/grouse/goat.rb
~~~

Now, being responsible goat herders, history is important to us; we want to look back on all the happy moments we’ve shared with our goats over the years. Can we still do that?

~~~bash
$> goat log —-oneline mountains/grouse/app/models/grouse/goat.rb

# (SHAs edited for brevity)
aa6d0f5d (HEAD -> goat-namespace) move the goat
~~~

WTF??! Where’s all of our history? 🤔

What if we use `—-follow`, which tells `git` to follow the history of a file even if it’s renamed?

~~~bash
$> goat log --oneline --follow mountains/grouse/app/models/grouse/goat.rb

aa6d0f5d (HEAD -> goat-namespace) move the goat
~~~

No dice. ☹️

As it turns out, **`git` has a hard time keeping track of history when both the file path and the contents of a file change in the same commit**. We saw a hint of this when we first staged our files for commit: `git` thought that we had deleted our original goat and added a new one.

(Note that using [git mv](https://git-scm.com/docs/git-mv) instead of `mv` above will helpfully stage the rename and not the file modifications, but adding these two operations to the same commit will still have an identical effect.)

So how do we fix it?

Let’s wind back the clock and make these changes a different way. As a reminder, here’s what our goat looked like to begin with:

~~~ruby
# app/models/goat.rb
class Goat
  def call
    "mbaaaahhh"
  end
end
~~~

_First_, let’s move the goat and make _no other changes_:

~~~bash
$> mv app/models/goat.rb mountains/grouse/app/models/grouse
$> goat status
On branch goat-namespace
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
 renamed:    app/models/goat.rb -> mountains/grouse/app/models/grouse/goat.rb
~~~

_Aha!_ Now, `git` detects that all we’ve done is rename the file. It knows this because we didn’t change any of its contents. We can go ahead and commit this.

~~~bash
$> goat commit -m "move the goat's file"
[goat-namespace 8f2d0cd] move the goat's file
 1 file changed, 0 insertions(+), 0 deletions(-)
 rename {app/models => mountains/grouse/app/models/grouse}/goat.rb (100%)
~~~

Now, let’s namespace our goat…

~~~ruby
# app/models/goat.rb
module Grouse
  class Goat
    def call
      "mbaaaahhh"
    end
  end
end
~~~

… and commit that:

~~~bash
$> goat commit -m "namespace the goat"
[goat-namespace 1a4b57c] namespace the goat
 1 file changed, 5 insertions(+), 3 deletions(-)
~~~


Okay, moment of truth. Can we see our history?

~~~bash
$> goat log --oneline --follow mountains/grouse/app/models/grouse/goat.rb
  1a4b57cd namespace the goat
  8f2d0cd6 move the goat's file
  2cb8bf10 Add call method
  3bb3aafc Add goat
~~~

Huzzah! It’s all still there.

## Conclusion

We can learn a lot from history — and from goats! — so it’s important to preserve it. Next time you’re sitting down to start refactoring your code, make sure you’re bringing your history along for the ride.

Happy herding! 🐐🐐
