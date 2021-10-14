---
title: "Design Patterns in Ruby: Strategy Pattern"
created_at: 2018-01-02
kind: article
---

_Originally published on [Medium](https://medium.com/rubyinside/design-patterns-in-ruby-strategy-pattern-17e2fa191d9c)_

Design patterns can be powerful conceptual models for thinking about how to solve problems in software development. [Popularized in the ’90s by the Gang of Four](https://en.wikipedia.org/wiki/Design_Patterns), many of them have remained relevant to this day.

They can also be great shortcuts for understanding the architecture of a system. As soon as you recognize the presence of a pattern, your mental model of that system snaps into focus, and you suddenly have a high-level idea of the structure while you wade through individual classes and methods.

When I’m learning new concepts and patterns, I always like having practical examples. Since I was brushing up on my patterns recently, I thought I would share a real-world example of the Strategy pattern at work in a popular Ruby library.

---

## A Brief Overview of the Strategy Pattern

The funny thing about patterns is, abstract descriptions of them always sound impenetrable and intimidating. If you want to go into more depth, check out the [excellent Wikipedia article](https://en.wikipedia.org/wiki/Strategy_pattern).

Briefly, the Strategy pattern is most useful when you want to provide multiple ways of processing a request, without hard-coding knowledge about those different methods into the object that handles the request.

For a practical example, we’re going to look at [Devise](https://github.com/plataformatec/devise), and one of its dependencies, [Warden](https://github.com/hassox/warden).

## The Strategy Pattern in Warden

[Warden](https://github.com/hassox/warden) is a Ruby gem that provides authentication for Rack applications. It’s a dependency of [Devise](https://github.com/plataformatec/devise), which uses Warden under the hood to authenticate requests.

Warden provides mechanisms for authenticating a session, but it remains agnostic about how exactly to perform the authentication; it leaves that up to the client code. For example, Devise provides a `DatabaseAuthenticatable` strategy for authorizing against a username and password, and a `Rememberable` strategy for validating a pre-existing session cookie.

Here’s where we see the Strategy pattern at work; by keeping the authentication algorithms separate from the code that performs the authentication, new algorithms can be employed without modifying Warden itself, and Warden can select a “winning” strategy at runtime without knowledge of how the algorithm works.

This concept of multiple strategies is perhaps a slight twist on the classic Strategy pattern; instead of selecting a single algorithm at runtime based on characteristics of the incoming request, Warden loops through all the selected strategies until it finds one that works.

## Let’s See Some Code

It’s always useful seeing how these patterns are implemented. Let’s dive into Warden!

[`Warden::Strategies::Base`](https://github.com/wardencommunity/warden/blob/master/lib/warden/strategies/base.rb) provides a common, abstract interface for all strategies to inherit from. Each strategy simply needs to implement its own authenticate! method, and Warden takes care of the rest.

For example, here’s what Devise’s [DatabaseAuthenticatable](https://github.com/plataformatec/devise/blob/master/lib/devise/strategies/database_authenticatable.rb) strategy looks like:

~~~ruby
module Devise
  module Strategies
    # Default strategy for signing in a user, based on their email and password in the database.
    class DatabaseAuthenticatable < Authenticatable
      def authenticate!
        resource  = password.present? && mapping.to.find_for_database_authentication(authentication_hash)
        hashed = false

        if validate(resource){ hashed = true; resource.valid_password?(password) }
          remember_me(resource)
          resource.after_database_authentication
          success!(resource)
        end

        mapping.to.new.password = password if !hashed && Devise.paranoid
        fail(:not_found_in_database) unless resource
      end
    end
  end
end
~~~

Here, we look up the “authenticatable” resource (usually a user) after verifying that a password was supplied. Then, we validate the password and call `#success!`, which Warden defines in the parent class. If the strategy was not successful — i.e. if the password was invalid — we `#fail` the strategy and allow Warden to attempt another method of authentication.

What does this look like from Warden’s perspective? When a request for authentication is triggered, it’s handled by [Warden::Proxy](https://github.com/hassox/warden/blob/master/lib/warden/proxy.rb).

In `#_run_strategies_for`, we iterate through the strategies set up for the resource and determine if any of them will provide access:

~~~ruby
# Run the strategies for a given scope
def _run_strategies_for(scope, args) #:nodoc:
  self.winning_strategy = @winning_strategies[scope]
  return if winning_strategy && winning_strategy.halted?

  # ...
  
  (strategies || args).each do |name|
    strategy = _fetch_strategy(name, scope)
    next unless strategy && !strategy.performed? && strategy.valid?

    strategy._run!
    self.winning_strategy = @winning_strategies[scope] = strategy
    break if strategy.halted?
  end
end
~~~

The Strategy pattern comes into play on line 12 above; `strategy._run!` ultimately calls `#authenticate!` in the strategy class.

We can see that the code in `#_run_strategies_for` is concerned with one thing: figuring out which of the many potential strategies will successfully authenticate the request. Imagine what this method would look like if it also contained the logic from those strategies. Imagine how difficult it would be to add a new one!

## Separation of Concerns
Used as it is here, the Strategy pattern provides a really nice interface between Warden, Devise, and your application, and allows each component to focus on a single responsibility. Warden concerns itself with the gory details of handling sessions in Rack. Devise hooks into Rails to provide user flows and other niceties. Strategies provide a plug-and-play interface that keeps those concerns separate.

---

## Conclusion

Employing the Strategy pattern in your own code can be an effective way of managing complexity. It embraces polymorphism and allows your code to focus on sending messages instead of switching on type. It also emphasizes a separation of concerns; your client code doesn’t need to concern itself with the internals of multiple algorithms.
