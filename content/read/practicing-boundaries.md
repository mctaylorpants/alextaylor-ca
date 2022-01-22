---
title: Practicing boundaries
kind: article
created_at: 2022-01-20
---

Code which is loosely-coupled is easier to work with. It's easy to say, right? I find a lot of software patterns _sound_ really nice, but it can be hard to apply them. And for that, examples always help!

I've been trying to pay more attention to this rule recently, and I found a good example yesterday in some code I was writing.

## How it started
I'm working on a feature that needs to accept a CSV containing rows of account details, and apply those changes to each account. Even from that simple sentence alone, a pretty obvious boundary emerges:

> *accept a CSV ... **and** apply changes to each account*

If we decouple the CSV handling from the business logic for processing each row, we're in good shape.

Here's what I started with (and no, we don't actually track our users' favourite tea, but wouldn't that be nice 😌):

~~~ruby
class ImportCsvController < ApplicationController
  def create
    csv = CSV.parse(params[:file][:content], headers: true)
    csv.each do |row|
      AccountUpdater.new(row).update!
    end
  end
end
~~~

~~~ruby
class AccountUpdater
  attr_reader :row

  def initialize(row)
    @row = row
  end

  def update!
    account_id = row["Account Id"]
    favourite_tea = row["Favourite Tea"]

    Account
      .find(account_id)
      .update!(favourite_tea: favourite_tea)
  end
end
~~~

Here we can see the boundary in action: the controller handles the nitty-gritty of parsing the CSV file, and `AccountUpdater` just receives some data and updates the account.

But once I had finished and I was looking it over again, I realized I had still broken a boundary. Can you spot it?

##  The (hidden?) dependency
It might look like `AccountUpdater` doesn't have a dependency on the CSV, but it absolutely does:

~~~ruby
csv.each do |row|
  AccountUpdater.new(row).update!
end
~~~

In order to provide `AccountUpdater` with the data it needs, we're passing in the `row` that we parsed from the CSV. Since we used [`CSV.parse`](https://ruby-doc.org/stdlib-3.0.0/libdoc/csv/rdoc/CSV.html#method-c-parse) with the `headers` option, we at least get a nice Hash-like object to work with...

~~~ruby
{ "Account Id" => "123", "Favourite Tea" => "Assam" }
~~~

... however, we're still leaking knowledge about the format of our CSV into `AccountUpdater`: it knows about our columns named `"Account Id"` and `"Favourite Tea"`.  We have subtly embedded knowledge about the structure of our user input into a class that should have no business handling user input.

## How it's going
As soon as I realized this, I pulled that knowledge back up into the controller:

~~~ruby
csv.each do |row|
  AccountUpdater.new(
    account_id: row["Account Id"],
    favourite_tea: row["Favourite Tea"]
  ).update!
end
~~~

~~~ruby
class AccountUpdater
  attr_reader :account_id, :favourite_tea

  def initialize(account_id:, favourite_tea:)
    @account_id = account_id
    @favourite_tea = favourite_tea
  end

  ...
~~~

Now, we're using keyword arguments to create a simple boundary between the structure of the CSV data and the data that `AccountUpdater` needs.

## Lessons learned
By taking a closer look at our boundaries, we managed to create an even sharper delineation. Now, our user input is completely decoupled from our business logic, and both classes should be easier to change in the future.
