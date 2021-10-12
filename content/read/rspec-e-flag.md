---
title: Run specific RSpec examples with -e
created_at: 2021-10-12
kind: article
---

I've been using RSpec for years, but I had no idea about this flag until a coworker pointed it out today.

You can use `bin/rspec -e` to run examples whose name matches a particular string:

~~~sh
-e, --example STRING
  Run examples whose full nested names include STRING (may be
  used more than once)

-E, --example-matches REGEX
  Run examples whose full nested names match REGEX (may be
  used more than once)
~~~

When is this useful? The place where I found it useful was a spec which we dynamically generate to run shitlists,
which help us keep bad/outdated code patterns under control.

~~~ruby
# spec/shitlists_spec.rb

  SHITLISTS = [
    DeprecatedMethodsShitlist,
    EnsureStringColumnsLengthsValidatedShitlist,
    ExecutableFilesShitlist,
    ...
  ]

  SHITLISTS.each do |shitlist|
    RSpec.describe shitlist do
      it do
        expect(described_class).to have_no_violations
      end
    end
  end
~~~

This spec generates a bunch of examples dynamically. Running `bin/rspec -e ExecutableFilesShitlist spec/shitlists_spec.rb` will
only run the one generated for `ExecutableFilesShitlist`, which saves a ton of time if you don't need to run the rest of them!

