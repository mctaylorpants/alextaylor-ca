---
title: "Adventures in Time: Debugging a Daylight Saving Bug"
kind: article
created_at: 2023-03-04
---

What's more fun than bugs? Bugs involving time! And none are so fascinating as bugs involving _daylight saving time._

With Daylight saving time almost upon us again, I thought it would be fun to revisit this bug my team and I stumbled across last fall.

## Once upon a time...
When subscribing a customer to a monthly plan in our billing system, we calculate the date of the customer's next bill by adding 30 days to their current time, and using that to create a subscription on Stripe.

However, at some point in October, we started to see this fail:

~~~ruby
Stripe::InvalidRequestError: 
  billing_cycle_anchor cannot be later than next
  natural billing date (1669817382) for plan
~~~

When comparing the "natural billing date" to the time we sent the request, it was indeed more than 30 days in the future – by exactly an hour. Curious!

## Arithmetick-tock ⏰

In the code, we were doing something roughly like this to calculate the billing date:

~~~ruby
subscription.started_at + 30.days
~~~

`started_at` is a `Time` object, and we're using the `ActiveSupport::Duration` helpers to advance that time by exactly 30 days. So what's the issue?

I fired up a console and started poking at this particular line of code to learn how it behaved.

First, a sanity-check: I want to make sure I know that `.days` is giving me what I expect:

~~~ruby
$> Time.parse("2022-10-15 12:00:00 -0700") + 1.day
=> 2022-10-16 12:00:00 -0700

$> Time.parse("2022-10-15 12:00:00 -0700") + (1 * 24 * 60 * 60)
=> 2022-10-16 12:00:00 -0700
~~~

Ok, good! I get the same answer if I add the total number of seconds in a day. Makes sense.

Now, what happens if I do the same thing, but add 30 days?

~~~ruby
$> Time.parse("2022-10-15 12:00:00 -0700") + 30.days
=> 2022-11-14 12:00:00 -0800

$> Time.parse("2022-10-15 12:00:00 -0700") + (30 * 24 * 60 * 60)
=> 2022-11-14 11:00:00 -0800
~~~

Aha! There's our bug. Depending on whether I use a `Duration` object or plain old seconds, I get a different answer. This feels like a daylight saving issue, since we're crossing the boundary here, and our two times disagree by *exactly* an hour.

Next, I want to confirm that this has something to do with crossing the daylight saving boundary. Let's try the same test, but using a time that's right before the boundary. Daylight saving ended on November 6, 2022 at 2am, so let's start from 1 second before and add 1 day:

~~~ruby
$> Time.parse("2022-11-06 01:59:59 -0700") + 1.day
=> 2022-11-07 01:59:59 -0800

$> Time.parse("2022-11-06 01:59:59 -0700") + (1 * 24 * 60 * 60)
=> 2022-11-07 00:59:59 -0800
~~~

Still behaves the same. So we can confidently say that **when crossing the DST boundary, adding a Duration to a timestamp yields a different time than adding a number of seconds.** 

## Testing the hypothesis

So which of the two answers above is correct?

It's easier to answer that question with a shorter duration, so let's work with plain seconds:

~~~ruby
$> Time.parse("2022-11-06 01:59:59 -0700") + 5
=> 2022-11-06 01:00:04 -0800
~~~

This makes sense:

- We added 5 seconds to get to 02:00:04.
- Since daylight saving ended at 2am, we roll the clock back by 1 hour.
- We end up with 01:00:04, in GMT -8 instead of GMT -7.

Numbers don't lie, but it seems like `ActiveSupport::Duration` may be stretching the truth in this case.

So why does `1.day` behave so differently?

## Down the rabbit hole

In order to explain the bug, we need some context on what happens when we add these two values together. Remember, since everything in Ruby is an object, an operation like `2 + 1`  is really invoking the `+` method on `2`, and passing `1` as an argument.

ActiveSupport implements methods like `+` on `Duration` objects so that you can add two of them together:

~~~ruby
$> 1.day + 1.day
=> 2 days
~~~

That's all fine and good when you have two `Duration` objects, or at least when a `Duration` object is the receiver (on the left-hand side of the operation). But we've got a plain ol' Ruby class on the left:

~~~ruby
Time.parse("2022-11-06 01:59:59 -0700") + 1.day
~~~

Here, we know the `+` method is being invoked on our `Time` object, yet somehow it knows what to do with an `ActiveSupport::Duration`. How is that possible? Let's introspect `+` and see where it takes us:

~~~ruby
$> Time.now.method(:+)
=> #<Method: Time#+(plus_with_duration)(other) /ruby/gems/2.7.0/gems/activesupport-5.2.8.1/lib/active_support/core_ext/time/calculations.rb:261>
# active_support/core_ext/time/calculations.rb:261
~~~

Hey, look! A monkey patch! 🙈

[Let's peek at that code](https://github.com/rails/rails/blob/8030cff808657faa44828de001cd3b80364597de/activesupport/lib/active_support/core_ext/time/calculations.rb#L261-L269):

~~~ruby
def plus_with_duration(other) #:nodoc:
  if ActiveSupport::Duration === other
    other.since(self)
  else
    plus_without_duration(other)
  end
end
alias_method :plus_without_duration, :+
alias_method :+, :plus_with_duration
~~~

Here, ActiveSupport has hooked into `+` to customize the path taken if the value being added is a `Duration` class. Otherwise, we can fall back on the original `+` method.

This is the point where I break out a debugger like [pry](https://github.com/pry/pry) to step through the code and see where it takes me. After `step`ping into `#since` and following the code path, [I end up here](https://github.com/rails/rails/blob/8030cff808657faa44828de001cd3b80364597de/activesupport/lib/active_support/core_ext/time/calculations.rb#L175):

~~~ruby
time_advanced_by_date = change(year: d.year, month: d.month, day: d.day)
~~~

Well, that's interesting. Just looking at that method call, I can see that we're dropping the hour, minute and second. And since I'm investigating a bug relating to an incorrect hour offset, this really piques my curiosity.

Let's step down [one more level into `#change`](https://github.com/rails/rails/blob/8030cff808657faa44828de001cd3b80364597de/activesupport/lib/active_support/core_ext/time/calculations.rb#L120), which lives in another monkey-patch on the `Time` class:

~~~ruby
  def change(options)
    new_year   = options.fetch(:year, year)
    new_month  = options.fetch(:month, month)
    new_day    = options.fetch(:day, day)
    new_hour   = options.fetch(:hour, hour)
    new_min    = options.fetch(:min, options[:hour] ? 0 : min)
    new_sec    = options.fetch(:sec, (options[:hour] || options[:min]) ? 0 : sec)
    new_offset = options.fetch(:offset, nil)

    ...

    if new_offset
      ::Time.new(new_year, new_month, new_day, new_hour, new_min, new_sec, new_offset)
    elsif utc?
      ::Time.utc(new_year, new_month, new_day, new_hour, new_min, new_sec)
    elsif zone
      ::Time.local(new_year, new_month, new_day, new_hour, new_min, new_sec)
    else
      ::Time.new(new_year, new_month, new_day, new_hour, new_min, new_sec, utc_offset)
    end
~~~

`change` is finally the method which returns a new `Time` object based on the results of the operation. Ultimately, we're calling some variant of `Time.new`, providing all-new values for the year, month, etc.

And where do we get all these new values?

~~~ruby
new_hour   = options.fetch(:hour, hour)
~~~

If we didn't pass it in from the arguments, then we fall back *to the existing `hour`, `min` and `sec` value on the current `Time` object.*

In other words, given our initial `Time` object of `Time.parse("2022-11-06 01:59:59 -0700")`, we're going to add `1.day` to the date only, then pin `01:59:59` on the end of it.

And there's our bug!

## The end... or is it?

Ultimately, the workaround on our side was a simple 5-character change: do our math with seconds instead of a `Duration` object:

~~~ruby
subscription.started_at + 30.days.to_i
~~~

I was also curious to see if others had run into it, and sure enough, [this bug had been reported a few months prior](https://github.com/rails/rails/issues/45055). It was [fixed shortly afterwards](https://github.com/rails/rails/pull/46251) in edge Rails, although it does seem like there's still some discrepancies when doing arithmetic around the DST boundary. My takeaway: when in doubt, stick with plain ol' seconds.

I always have a hard ... ahem, *time* ... wrapping my head around time-related bugs. This one was a fun opportunity to dive in and get to the bottom of a hairy problem.

Thanks for reading!
