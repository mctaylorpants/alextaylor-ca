---
title: My Obsidian Workflow
kind: article
created_at: 2025-06-06
---

I've been using [Obsidian](https://obsidian.md/) for a few years to keep track of my work notes and tasks. I love how customizable it is, but that can also be a curse: you can end up spending ages configuring it, trying out new plugins, and lose track of why you're using it in the first place!

I've been actively iterating on my workflow for the past few months and have hit on something that's been working pretty well for me, so I wanted to capture it.

## TOODOO
At the root level of my vault, I have a note called "TOODOO". (Why the extra Os? Why not!)

There are two components to this view:

**A "Project Overview" section**. I keep a list of the projects I have on the go and what's next for each of them. I update this each week, and I find it helps me context-switch more quickly between projects when I have a lot on the go.

**Tasks for today and for later**. I use the [Tasks plugin](https://publish.obsidian.md/tasks/Introduction#Task+management+for+the+Obsidian+knowledge+base) to pull tasks from my daily notes and projects, like so:

~~~
tasks

filter by function task.file.root === '1-- projects/' || \
  task.file.folder.includes('reflections/daily')

sort by priority, due, done
~~~

I've fiddled around a lot with my grouping of tasks, and I'll probably keep fiddling forever. I go back and forth between "daily + everything else", "daily, weekly, later", and other flavours. But I like how easy the Tasks plugin makes it to iterate on these queries.

## Starting each day with a fresh "page"
The first thing I do in the morning is create my daily note. It's my landing pad for what I'm doing, new tasks that come to mind, and other random notes throughout the day. I love it - it's like turning to a new page in a notebook, free of cruft and full of possibility.

I use the [Daily Notes plugin](https://help.obsidian.md/plugins/daily-notes) which helps automate the creation of these notes from a template, and lets me pull up today's note quickly from the command palette. I've iterated a lot on the template; recently I've settled on a list of open tasks with today's due date, a list of tasks I've completed, and an open space below.

Throughout the day, I'll do a [Bullet Journal](https://bulletjournal.com/)-esque workflow where I jot down stuff I'm doing. This helps me reflect on what I did that week, and can often help remind me of something I wanted to look into but didn't have time when it first came up. It's also a great source of inspiration for my [brag document](https://jvns.ca/blog/brag-documents/)!

In my Monday daily note, I've recently taken to writing down a quick breakdown of how I want the week to go. Something like:

~~~
**Monday**
- Timeout bug: add logging, understand how our monitoring works

**Tuesday**
- Presentation and doc-writing for Project X

**Wednesday**
- Project Y: groom and prioritize tweak tickets

... etc...
~~~

I've found it helpful to do this when I'm juggling a lot and need to prioritize, but I'm not ready to break out granular tasks. That's the beauty of Obsidian: it's just Markdown, it doesn't lock you into a certain way of working.

## Projects, big and small
Any larger initiative I'm working on gets its own note in the `projects` folder. I typically keep a work log by date, and use the top of the note to link out to Github/Linear issues, relevant notes, slack channels, PRs, things in Google Docs - basically a collection of bookmarks.

These notes aren't just for capital-P Projects, though. Often, I'll start taking notes on something in my daily note for that day, but it's something I want to come back to the next day or the next week. When that happens, I'll pull the notes up into a project note and then link to it from those daily notes.

For example, I recently switched from vim to [Cursor](https://www.cursor.com/), and did a bunch of fiddling and customizing along the way. I found I would be working on something and suddenly miss a shortcut or function from vim, and wonder how to reproduce it, but not want to interrupt my focus to figure it out in the moment. These were getting lost across my various daily notes, so I made a `switch to cursor` note where I started keeping a list of all these little issues. When I have time, I pick an issue from the list and fix it. When that list is empty, I'll move that note to the `archives` folder.

Having an `archives` folder helps keep the `projects` folder focused, so I can see at-a-glance what I'm working on and thinking about. If I haven't worked on something in awhile, I just put it in `archives`.

If a project gets even bigger than a note, I'll make a folder for it. I'll have an index note, usually prefixed with an underscore, that serves as a jumping-off point for whatever other notes I have in that folder.


## Conclusion

This workflow has really helped me stay on top of things:
- Starting with an empty daily note helps me start the day with a clear mind
- My TOODOO note serves as a high-level overview of everything that's happening
- Project notes help organize larger and smaller initiatives so I can always pick up where I left off

Obsidian is the first digital note-taking tool I've stuck with for longer than a few months. I've been using it for about 3 years. How I use it has evolved over time and will continue to evolve. It's the flexibility that keeps me using it!
