---
title: "Development Environment"
order: 4
---

# Setting up the development Environment

So at this step, we are trying to think, what our development environment should
look like.

For any development environment a few things matter the most:

- How fast can I make changes and see them
- How fast can I see the affect of changes I made
- How fast can I re-create the environment by destroying
- How maintainable is it?

Now, to get answers for all these questions, there are different types of tools
that already present in the world. Let's start with first one.

## How fast can I make changes and see them

This is actually layered and often overlaps with other aspects of the
development environment setup. We want a functionality as close as to
[[Hot Reloading]] in dynamically interpreted programming languages.

In our case, we are going to get as close as possible to this development setup.
Let's look at the technology stack that enables it. There are layers to it as
well

### Programming Language

This programming language needs to be fast, well documented, with a lot of
community support, quite close the low level systems as possible and so on. Now,
you might be wondering, "why such requirements?" for that, we need to think
deeper into what we are trying to build.

We are trying to build a system that exists between the hardware and the outside
world. If you think about computers, they are just three layers working
together.

- Hardware
- Software Managing that Hardware (This is anton)
- Endless software written on top of Anton

#### Hardware

This is the combination of everything you can see, touch and feel. The RAM, CPU,
Disk, Motherboard, Mouse, Keyboard and what not. This is just like an engine, it
doesn't do anything until someone "drives" it.

Now, let's take a deeper look at just one of these components. CPU, CPU is just
like a dumb machine, that looks at whatever is written in it's notepad
(Register), reads it, and it just knows how to perform whatever it read. This is
a bunch of operations that it is "built to do". Things like adding, subtracting,
moving things from one location to another.

It is a very specialized piece of machinery that just does this one thing well,
it doesn't know anything about RAM, about Disk or whatever. It just always runs
a fetch, decode and execute cycle. Do you think it is smart enough to understand
that complex website you are building? No. It needs help.

To get a deeper understanding of how CPU works, you should read
[Everything About the CPU](/Basics/chapter-1/the-cpu.md), even though you don't
need to finish it right now, it's a web of it's own. Everything you need to know
for now, is already in this article.

#### Software managing that hardware (Operating System)

This is the software that manages everything in the hardware space. This is the
driver of that engine (hardware). It knows how to use the CPU for a bigger
picture, because it knows about all the other components of the system, and also
knows how to orchestrate it, when to use memory management to get CPU right
instruction so it can perform xyz action.

This is what we will write, this complex pipeline implementation and we will
have to decide a programming language that allows us to do all this while being
the fastest.

#### Endless Software Written on Top

This is what you have written or used up till now directly. Uber, Domino's,
Amazon, Browsers and what not. This is the software that most of the world
writes and uses directly.

Here is the fun fact, all of it runs at the mercy of the Operating System. Your
uber App doesn't even know how to start itself, It literally relies on the
Operating System to do [[Everything needed to run a Program]]. Your Uber app
can't even connect to the internet if not facilitated by the Uber app.

For example, you think the Uber App itself handles everything end to end to
connect it to the internet? No. Something as plain as sending a "Hi" to your
friend using WhatsApp is insanely complex. We don't want every company, every
engineer to write a new implementation of how to send a chunk of data over the
internet. Therefore, the Operating System has a Network Management module
in-built. All the other apps that want to connect to the internet, use this.
Similarly for every other aspect of interacting with the hardware.

---

So, if we combine the understanding we gained with whatever we read up till now,
we can say we want a programming language that is

- Extremely Fast
- Can work at the Hardware Level
- Not too complex
- Quite widely accepted by the world for writing this kind of software
- and fill in whatever things are needed to come up with using C.
