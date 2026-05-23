---
title: Running things on Bare Metal
order: 6
---

When we strip our computer of everything, how do we run software on it?
In the article [Why do we need an Operating System](/docs/content/Basics/chapter-1/why-do-we-need-an-os.md)
we explicitly talked about how operating system helps us with almost everything
we do with our computer.

Now, we don't have it. So, what is the absolute minimum requirements that
we are dealing with in order to run our own operating system.

One of the things is the cross compiler.

Okay, so to get started, we practically need three sections to deal with.

The Boot, where we define our own bootloader.
The actual Kernel logic that will run.
The dependencies it will have, and it will depend on.
Then finally, we have the linker file.

Now, let's look at different files and try to understand what they are doing.

There is a thing or two that you need to properly understand. The world without
the operating system is very hard to live in. Usually, whatever software we have
written exists and runs on top of the operating system. It expects xyz things to
already exist, which do not right now.

Practically, to understand whatever is happening or needs to be done, you should
understand.

And now, we have to think about a few things.

- What are the tools that are required or we are building with.
- What environment is our program going to run in.
- What are the things that are needed to run a program. Understanding this is
  crucial to understand the Assembly file that we have written. Questions like
  what is an execution context is at the core of this part, because this ASM
  file just sets up this context that is needed to run a program.
- What is a binary, how is it laid out in a memory and how it's execution actually
  happens and works.
- What is a multi-boot compatible loader? What is the work of it, Also, need to
  understand what is the work of a loader here really.

We start with some Assembly code, because that is what the computer understands.
And, we start with it for some initial control, that is needed for the "first program
ever" to run. So we use Assembly initially to get things started.

Looking at the tool-chain that we are working with, we can see that following
tools is what we begin with.

- NASM: This converts our Assembly code into machine code, why do we need it and
  why cannot we just convert a C code into machine code, is something I need to
  research.
- i686-elf-gcc: This is cross compiler (this needs to be understood), that targets
  32 bit x86 architecture, Bare metal, why? I need to research about this a bit more,
  all I know for now, that is that the basic GCC, compiles C code with an assumption
  that there is an Operating system with basic libraries present just beneath the
  system, we cannot run our OS with such an assumption, because we ourself are
  writing the Operating System.
- i686-elf-ld: This is a linker or loader whatever you wanna call it, I need to
  learn a bit more as to what is the purpose of this. The computer says that it
  'Links object files into a kernel binary according to our memory layout, not
  the host OS's defaults.' need to read about this.
- -freestanding: Tells the compiler: "this is not a hosted normal C environment."
  In other words, don't assume full standard-library/runtime behavior. I need
  to look into why exactly is this needed, aren't we already compiling our
  kernel with a cross compiler that already assumes this.
- -nostdlibP: Tells the linker: "do not silently pull in the normal C runtime
  and system libraries."
