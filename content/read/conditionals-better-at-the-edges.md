---
title: "Conditionals: Better at the Edges"
kind: article
created_at: 2022-02-24
---

I think a lot about conditionals. They proliferate with astonishing speed, and each new branch adds a cognitive burden to the next person who needs to understand what the code is doing — not to mention, bugs love hiding in conditionals!

There are a lot of strategies out there on how to deal with conditionals, from [refactoring recipes](https://xp123.com/articles/refactoring-pull-common-code-conditional/) to [object-oriented approaches](https://www.youtube.com/watch?v=8bZh5LMaSmE). Something that they all have in common is the idea that **conditionals are better at the edges than in the middle.**

Put another way, if your code path needs to branch, it's often better to do it as early as possible, or as late as possible. Doing this helps cut down on the amount of paths through a given piece of code, and makes it easier to reason about.

## Learning by example

I was doing some code-diving recently and came across this function in our frontend code. It pulls data for a table which displays rows of three similar but distinct records:
  
- Users
- Invitations (for users who haven't yet activated their account)
- Licenses (or "seats", which may be filled by inviting a new user)

The code makes three API calls to fetch each type of data, then builds up one list for the table. It looks like this:

~~~javascript
const userLists: UserLike[][];

// (code to populate userLists goes here)

const users: UserLike[] = [];

for (let userList of userLists) {
  for (let user of userList) {
    users.push(<User>{
      ...user,
      name: user.name || null,
      roles: user.roles || [],
      status: user.status
        ? user.status
        : typeof user.enabled !== "boolean"
        ? UserStatus.Invited
        : user.enabled
        ? UserStatus.Active
        : UserStatus.Inactive,
      user_type: user.user_type || user.subscription_type,
    });
  }
}
~~~

There aren't too many lines, but this code is _dense_ and full of conditionals. Let's break down what's happening:

- If the user has a name, use it - otherwise, set it to `null`.
- If the user has a list of roles, use those - otherwise set it to an empty array.
- If the user has a status, use it - otherwise, check if the user _does not_ have a boolean `enabled`  attribute. If they don't, set their status to "invited". Otherwise, check if they're enabled. If they are, set their status to "active." If they aren't, set their status to "inactive." (phew!)
- If the user has a `user_type` attribute already, use it. Otherwise, set `user_type` to the value of `subscription_type`.

It took me awhile to wrap my head around this, but eventually I realized what was really going on: each of the three data sources (users, invitations and licenses) is of a slightly different shape, and we want to normalize each type into a unified "User-like" type so we can display it in the same table.

Let's think about how we can eliminate these conditionals.

## Pull up! Pull up!

There are different reasons for each conditional in the code above, but ultimately they're all asking the same question: **am I dealing with a user, an invitation, or a license?**

With that in mind, maybe we could pull that question _up_ and deal with it first:

~~~javascript
const invitationsList: UserLike[];
const usersList: UserLike[];
const subscriptionsList: UserLike[];

// (code to populate the lists goes here)

const users: UserLike[] = [];

for (let invitation of invitationsList) {
  users.push(<User>{
    ...invitation,
    name: null,
    rate: null,
    status: UserStatus.Invited,
  });
}

for (let user of usersList) {
  users.push(<User>{
    ...user,
    status: user.enabled ? UserStatus.Active : UserStatus.Inactive,
    user_type: user.subscription_type,
  });
}

for (let subscription of subscriptionsList) {
  users.push(<User>{
    ...subscription,
    name: null,
    rate: null,
    roles: [],
    user_type: undefined,
  });
}
~~~

Here, the question of "what thing am I dealing with" is answered by each separate `for` loop: inside each loop, we only need to worry about one type of thing.

Nearly all of the conditionals that existed in the old version are gone. The only exception is a simple ternary which sets a user to "active" or "inactive" based on the `enabled` boolean, which makes a lot of sense now that it's not buried in the nested ternary statement from earlier.

You might notice we've traded conditionals for duplication. I think that's a worthwhile tradeoff in this case, because the resulting code is easier to understand. The duplication is trivial, and it actually serves to highlight how each type of object differs from each other.

## Conclusion
Whenever I see a conditional now, I try to ask myself the question, "can I pull this up or push it down?" Sometimes the answer is "no", but it's a useful exercise nonetheless.
