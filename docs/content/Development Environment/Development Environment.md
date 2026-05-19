---
title: "Development Environment"
order: 4
---

# Setting up the development Environment

At this step, we are trying to think, what our development environment should
look like.

For any development environment a few things matter the most:

- How fast can I make changes and see them it's affect
- How fast can I re-create the environment by destroying it
- How maintainable is it?

Now, to get answers for all these questions, there are different types of tools
that are already present in the world. Let's start with first one.

## Making Changes

This is actually layered and often overlaps with other aspects of the
development environment setup. We want a functionality as close as to
[[Hot Reloading]] in dynamically interpreted programming languages.

Let's look at the technology stack that enables it. There are layers to it as
well

### Programming Language

This programming language needs to be fast, well documented, with a lot of
community support, extremely close to the low level systems, with absolutely
zero assumptions. See, a long list to begin with and honestly, not even
complete.

You might be wondering, "why so many requirements?" for that, we need to think
deeper into what we are trying to build.

We are trying to build an operating system that literally runs on the hardware,
directly interacts with the CPU, memory, disks, network interfaces and what not,
which means it needs to have all the tools to properly deal with
[Assembly Code](/docs/content/Basics/chapter-3/why-assembly.md),
memory addresses (pointers) etc.

We are literally building the Operating System, which means there is nothing
underneath to support our software, it runs on bare metal. So, No Dependencies at
all. Low profile, zero magic, and predictable. We don't want something like a
Garbage collector to halt the entire system. Anton should be able to
handle every aspect and only the software that is part of it should run,
nothing magical.

- Community support, we want a language that has been used a lot to write
  similar software so that in case we get stuck somewhere, we can get answers
  super fast. Also, we don't want to re-invent every wheel, we want to use some
  base level tools that are pre-built for the job.

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
[Everything About the CPU](/docs/content/Basics/chapter-1/the-cpu.md), even though you don't
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
