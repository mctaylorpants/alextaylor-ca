---
title: "Upgrading Rails: Tracking down deprecated callbacks in Rails 5.0"
kind: article
created_at: 2020-04-20
---

We’re in the process of upgrading some of our Rails apps at [Clio](https://www.clio.com/) from Rails 5.0 to 5.1 (and onwards to 6 in the coming months 🚀). Part of our upgrade strategy involves addressing the deprecation warnings that Rails helpfully provides, in order to prepare our app for the next version before upgrading.

[One of the features deprecated in Rails 5.1](https://guides.rubyonrails.org/5_0_release_notes.html#active-record-deprecations) is the ability to return `false` from a model callback to halt the chain. As the warning itself helpfully points out:

> Returning `false` in Active Record and Active Model callbacks will not implicitly halt a callback chain in Rails 5.1. To explicitly halt the callback chain, please use `throw :abort` instead.

The change itself is pretty trivial: if you come across a callback that returns `false`, you simply rewrite it to `throw(:abort)` and move on with your life. Easy, right? 🤷‍♂️

Well, it turns out that _finding those callbacks_ isn’t always that simple. And unfortunately, in this particular instance Rails’ helpful deprecation warnings fall short of the mark because of the nature of how callbacks get executed. Most of our deprecation warnings looked something like this:

~~~
DEPRECATION WARNING: Returning `false` in Active Record and
Active Model callbacks will not implicitly halt a callback
chain in Rails 5.1. To explicitly halt the callback chain,
please use `throw :abort` instead.
(called from within_new_transaction at
extensions/active_record/transaction_manager_patch.rb:26)
~~~

By default, `ActiveSupport::Deprecation` will attempt to extract a useful bit of stack trace to help you track down the offending code. But it’s not so easy with callbacks. In this particular case, it’s pointing to a patch we added for gathering statistics on transaction times, but the important takeaway is that **using a stack trace to find a callback is a recipe for a headache.**😫

What we _really_ want to know is where the callback is _defined_, not where it happens to be _executed_ from. And for that, we need the model name and the method name. Consider this callback:

~~~ruby
class User < ApplicationRecord
  before_destroy :check_ownership

  def check_ownership
    if account_owner?
      false
    end
  end
end
~~~

If all we have is a deprecation warning in our logs, we want to know that the callback we’re looking for is `User#check_ownership`.
Let’s see if we can add more context to this deprecation warning.

## The Current Approach 🔎

Let’s take a closer look at how this deprecation warning is generated under the hood to figure out how we might improve it.

The `ActiveSupport::Callbacks` module has what we’re looking for:

~~~ruby
def deprecated_false_terminator # :nodoc:
  Proc.new do |target, result_lambda|
    terminate = true
    catch(:abort) do
      result = result_lambda.call if result_lambda.is_a?(Proc)
      if Callbacks.halt_and_display_warning_on_return_false && result == false
        display_deprecation_warning_for_false_terminator
      else
        terminate = false
      end
    end
    terminate
  end
end
~~~

In Rails 5.0, the `deprecated_false_terminator` method is the [default terminator for ActiveModel callbacks and validations](https://github.com/rails/rails/blob/c4d3e202e10ae627b3b9c34498afb45450652421/activemodel/lib/active_model/callbacks.rb#L106). A terminator wraps the callback code itself and determines if its return value should halt the rest of the callback chain. In the snippet above, `result_lambda` is this wrapper.

By calling `result_lambda` and inspecting its return value, we can figure out if we need to throw a deprecation warning. If we do, we call `display_deprecation_warning_for_false_terminator`:

~~~ruby
def display_deprecation_warning_for_false_terminator
  ActiveSupport::Deprecation.warn(<<-MSG.squish)
    Returning `false` in Active Record and Active Model callbacks will not implicitly halt a callback chain in Rails 5.1.
    To explicitly halt the callback chain, please use `throw :abort` instead.
  MSG
end
~~~

At this point, the standard `ActiveSupport::Deprecation` infrastructure will kick in to help generate a callstack and send the warning to a log, or STDERR, or [whichever behaviour you’ve configured](https://api.rubyonrails.org/v5.0.7.2/classes/ActiveSupport/Deprecation/Behavior.html).

Anyway, we’ve found the most reasonable place to improve the deprecation warning. Inside `deprecated_false_terminator`, we have access to `target`, which represents the model name. Great! Unfortunately, the callback itself has been abstracted away by the `result_lambda`.

If we take a step back and look at where `result_lambda` is defined, we can see it’s got what we need:

~~~ruby
def self.halting(callback_sequence, user_callback, halted_lambda, filter)
  callback_sequence.before do |env|
    target = env.target
    value  = env.value
    halted = env.halted

    unless halted
      result_lambda = -> { user_callback.call target, value }
      env.halted = halted_lambda.call(target, result_lambda)

      if env.halted
        target.send :halted_callback_hook, filter
      end
    end

    env
  end
end
~~~

`halting` seems to be where it all comes together: we’ve got the `target`, the `user_callback` itself, and also the `filter`, which would be the symbol `:check_ownership` in our example above (or a reference to the Proc).

This is a bit of a conundrum: ideally we’d like to patch `deprecated_false_terminator` so we can pass the model and callback name to the warning message, but now we might need to patch `halting` to get all of our eggs in one basket, so to speak. There has to be a better way!

As it turns out, we can weasel our way up into `halting` by doing some introspection on the `result_lambda`. In Ruby, Procs (of which a lambda is a type) save a reference to the scope in which they were defined; [this is exposed as the `#binding` method](https://ruby-doc.org/core-2.6/Proc.html#method-i-binding).

~~~ruby
$> result_lambda.binding
=> #<Binding:0x00007fceb33a9448>

$> result_lambda.binding.local_variables
=> [:env, :target, :value, :halted, :result_lambda, :callback_sequence, :user_callback, :halted_lambda, :filter]
~~~

Check it out! Like some stealthy closure ninja, we’ve got access to everything we need without ever leaving the comfort of our method.

~~~ruby
$> result_lambda.binding.local_variable_get(:filter)
=> :check_ownership
~~~

We have our model, and we have our callback name. All that’s left to do is to apply a monkey-patch to our application.

## A Better Way ✨
Here’s what the final patch looks like ([see the full gist here](https://gist.github.com/mctaylorpants/1e20eb4a3756906f75413103fa839dc1)):

~~~ruby
# A monkey-patch to make detecting deprecated
# callbacks easier, because a stack trace is
# not the greatest when it comes to callbacks.
#
#
# Original code:
# https://github.com/rails/rails/blob/c4d3e202e10ae627b3b9c34498afb45450652421/activesupport/lib/active_support/callbacks.rb#L766-L788
require "active_support/callbacks"

module ActiveSupport
  module Callbacks
    module ClassMethods
      def deprecated_false_terminator # :nodoc:
        Proc.new do |target, result_lambda|
          terminate = true
          catch(:abort) do
            result = result_lambda.call if result_lambda.is_a?(Proc)
            if Callbacks.halt_and_display_warning_on_return_false && result == false
              # the scope that `result_lambda` is created in contains the filter
              # that we need to identify the callback with, so let's pull it
              # out of the binding.
              filter = result_lambda.binding.local_variable_get(:filter) rescue nil
              display_deprecation_warning_for_false_terminator(target, filter)
            else
              terminate = false
            end
          end
          terminate
        end
      end

      def display_deprecation_warning_for_false_terminator(target=nil, filter=nil)
        ActiveSupport::Deprecation.warn(<<~MSG)
          Returned `false` from callback in `#{target.class.name}##{filter}`!
          Returning `false` in Active Record and Active Model callbacks will not implicitly halt a callback chain in Rails 5.1.
          To explicitly halt the callback chain, please use `throw :abort` instead.
        MSG
      end
    end
  end
end
~~~



Thanks to the context provided by `result_lambda`, we’re able to extract the model in question and the name of the callback, and pass it down to the warning message.

Check out our deprecation warning now:

~~~
DEPRECATION WARNING: Returned `false` from callback in
`User#check_ownership`! Returning `false` in Active
Record and Active Model callbacks will not implicitly
halt a callback chain in Rails 5.1. To explicitly halt
the callback chain, please use `throw :abort` instead.
~~~

Given how old Rails 5.0 is at this point, I admit this tip is a bit late, but if it helps a few people avoid these kinds of headaches in the future, it’s worth it! 🙌
