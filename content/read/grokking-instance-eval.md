---
title: Grokking instance_eval
kind: article
created_at: 2023-11-10
---

During a recent hackathon at work, I wanted to see how far I could get implementing Rails from scratch. (Spoiler alert: we got a basic "hello world" working with some routes, a controller and a model!)

One of the first things we did was implement a [DSL](https://en.wikipedia.org/wiki/Domain-specific_language) for defining routes. We wanted to mimic the `draw` interface from Rails, where you provide a block:

~~~ruby
Rails.application.routes.draw do
  get "users", to: "users#index"
end
~~~

Along the way, I finally wrapped my head around `instance_eval`, one of the great staples of metaprogramming in Ruby.

## Starting small

Normally, passing a block around is pretty easy if all you want to do is control when it's executed. You could do something like this:

~~~ruby
def draw_routes(&block)
  puts "Defining routes..."
  routes = block.call
  puts "Routes:", routes.inspect
end

draw_routes do
  [
    :get, "users", "users#index"
  ]
end

# Defining routes...
# Routes:
# [:get, "users", "users#index"]
~~~

... but that's not very useful! We can't really make a DSL this way because our block isn't running within any special context, so we have nowhere to define methods like `#get`, `#post`, etc.

One option would be to pass some kind of configuration class into the block:

~~~ruby
class RouteConfig
  attr_reader :routes

  def initialize
    @routes = []
  end

  def get(path, controller_action)
    routes << [path, controller_action]
  end
end

def draw_routes(&block)
  puts "Defining routes..."
  route_config = RouteConfig.new
  block.call(route_config)
  puts "Routes:", route_config.routes.inspect
end

draw_routes do |routes|
  routes.get "users", "users#index"
end

# Defining routes...
# Routes:
# [["users", "users#index"]]
~~~

Now we're getting somewhere: we can start building up a DSL in the `RouteConfig` class.

But hang on - the Rails implementation doesn't do this. The block passed to `draw` takes no arguments, yet we can still use the routes DSL within it. What's going on?

## The magic of instance_eval ✨
Enter [`instance_eval`](https://www.rubydoc.info/stdlib/core/BasicObject:instance_eval). This Ruby method allows you to execute code in the context of another object. Effectively, it sets the value of `self` within the block to be whatever object you're calling `instance_eval` on.

With this in mind, we can refactor to call `instance_eval` on an instance of `RouteConfig`. Cool!

~~~ruby
def draw_routes(&block)
  puts "Defining routes..."
  route_config = RouteConfig.new
  route_config.instance_eval(&block)
  puts "Routes:", route_config.routes.inspect
end

draw_routes do
  get "users", "users#index"
end

# Defining routes...
# Routes:
# [["users", "users#index"]]
~~~

(Under the hood, Rails actually uses [`#instance_exec`](https://www.rubydoc.info/stdlib/core/BasicObject#instance_exec-instance_method), which functions the same but allows you to pass arguments into the block, too. Although based on [how it's being used](https://github.com/rails/rails/blob/16607e349a0a371b403ae04489f9af9acfab9f17/actionpack/lib/action_dispatch/routing/route_set.rb#L444-L450), I think `instance_eval` would work just as well.)

## Detour: blocks and closures

Along the way to arriving at the solution, we ended up making a small mistake which led to a deeper understanding - my favourite kind of mistake!

The first time we tried using `instance_eval`, we wrapped `block.call` within another block, like this:

~~~ruby
def draw_routes(&block)
  ...
  route_config.instance_eval do
    block.call
  end
end

draw_routes do
  get "users", "users#index"
end
~~~

This did not work:

~~~ruby
undefined method `get' for main:Object (NoMethodError)
~~~

This left us scratching our heads for awhile until my coworker suggested `instance_eval(&block)`, which worked. But *why* did it work?

It's subtle, but in the example above there are two execution contexts:

1. The context within the `instance_eval` block, in which we already know `self` will point to the receiving object;
2. The context of the block itself.

When we execute `block.call` explicitly, the code within our block will run in its own context. The things it has access to - methods, variables, etc - are determined by this context. Another way of saying this is that the block *creates a [closure](https://en.wikipedia.org/wiki/Closure_(computer_programming))* around the things it had access to wherever it was defined.

That's why we can define a local variable outside of the block, but still have access to it when the block eventually executes:

~~~ruby
def run_block(&block)
  name = "Pepper"
  block.call
end

name = "Alex"
run_block do
  puts "My name is #{name}"
end

# My name is Alex
~~~

It's also what the error was trying to tell us: `undefined method 'get' for main:Object` is saying that the context in which the block was defined - the top-level, `main` context - doesn't have a method named `get`.

So, back to `instance_eval`. When we write our `#draw_routes` method like this:

~~~ruby
def draw_routes(&block)
  route_config = RouteConfig.new
  route_config.instance_eval(&block)
end
~~~

We're passing our block *directly* to `instance_eval`, which means that our block will have its execution context modified so that `self` refers to the receiving object.

But wait, does it still keep its original closure? It sure does:

~~~ruby
users_endpoint = "users"
users_action = "users#index"

draw_routes do
  get users_endpoint, users_action
end

# Defining routes...
# Routes:
# [["users", "users#index"]]
~~~

I probably won't have occasion to use `instance_eval` any time soon in my day-to-day work, but it's always fun digging into Ruby and gaining a deeper understanding.
