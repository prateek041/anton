---
title: "Why x86?"
order: 13
---

# Why x86?

In Chapter 1, we talked about computers in the abstract: a CPU that fetches
instructions, memory that stores them, buses that connect everything. But "a
CPU" is not something you can program. You need a specific CPU with a specific
instruction set, specific registers, and specific rules. You need to know the
exact machine you are targeting.

For Anton, that machine is x86.

If you have ever used a desktop computer, a laptop, or a server, there is an
overwhelming chance the processor inside it was x86. Intel and AMD have been
building x86 chips for decades, and the architecture dominates personal
computing and the server world. It is the platform that Linux was born on, that
Windows runs on, and that the vast majority of OS development tutorials target.

But x86 is not just popular. It is also deeply weird, full of historical
baggage, and far more complex than it needs to be. Understanding why requires a
brief trip through history.

## A Timeline of x86

The story starts in 1978 with the **Intel 8086**. This was a 16-bit processor
with a 20-bit address bus, which meant it could address 1 megabyte of memory.
Programs ran in what we now call **real mode**: 16-bit registers, segmented
memory addressing, no memory protection, no privilege levels. Every program
could access any memory address and any hardware device. The 8086 was simple,
cheap, and successful. IBM chose it (well, the slightly cheaper 8088 variant)
for the original IBM PC in 1981, and that decision locked x86 into the center of
personal computing forever.

The **80286** arrived in 1982 and introduced **protected mode**: a way to
restrict which memory a program could access. But 286 protected mode was awkward
and limited. It could address 16 MB of memory, but switching between real mode
and protected mode was so clunky that most software just stayed in real mode.

Then came the **80386** in 1985, and this is where x86 becomes the architecture
we actually care about. The 386 was the first 32-bit x86 processor. It
introduced 32-bit registers, a flat 4 GB address space, proper protected mode
with privilege rings, and **paging**: the ability to map virtual addresses to
physical addresses through page tables. Almost everything we will build in Anton
for the first ten phases uses features that were introduced in the 386.

After the 386, Intel released the 486, the Pentium, the Pentium Pro, and many
more. Each added performance features (caches, pipelining, out-of-order
execution, SIMD instructions) but the core programming model stayed the same. A
32-bit protected mode program written for the 386 still runs on a modern Intel
Core processor. That is not an accident. It is the defining principle of x86.

In 2003, AMD introduced **x86-64** (also called AMD64 or x86_64), extending the
architecture to 64-bit. Intel eventually adopted the same extensions (calling it
Intel 64 or EM64T). This added 64-bit registers, a vastly larger address space,
and some cleanup of legacy features. But even a 64-bit x86 processor still boots
in 16-bit real mode, just like the original 8086 from 1978. Every single time.

![The x86 timeline from the 8086 in 1978 to x86-64 in
2003](../images/ch2/x86-timeline.svg)

## Backward Compatibility: The Sacred Cow

Here is the thing about x86 that you need to understand before anything else:
**backward compatibility is sacred**. Intel and AMD will not break old software.
Period. A program compiled for the 8086 in 1978 will still run on a chip
manufactured in 2026. That is almost 50 years of compatibility.

This has enormous consequences for us as OS developers.

When you press the power button, the CPU does not start in its most capable
mode. It starts in 16-bit real mode, pretending to be an 8086. It has to,
because the BIOS firmware (which runs first) was originally designed for 16-bit
processors, and breaking that chain would break billions of existing systems.

So our bootloader will start in 16-bit real mode with only 1 MB of addressable
memory, 16-bit registers, and no memory protection. Our first job is to set up
the necessary data structures and switch the CPU into 32-bit protected mode,
which gives us 4 GB of address space, 32-bit registers, and hardware-enforced
privilege levels. Later, in Phase 11, we will switch again into 64-bit long
mode.

This progression is not optional. You cannot skip ahead. Every x86 operating
system must walk this path: real mode to protected mode, and optionally to long
mode. The CPU physically requires it.

![The progression from Real Mode to Protected Mode to Long
Mode](../images/ch2/x86-modes-progression.svg)

The cost of backward compatibility extends beyond boot. The x86 instruction
encoding is a tangled mess of variable-length instructions, optional prefixes,
and special cases accumulated over decades. The memory segmentation model from
the 8086 era is still present in protected mode, even though modern operating
systems set up a flat memory model and effectively ignore it. There are
instructions in the architecture that have not been useful since the 1980s but
cannot be removed because some ancient program somewhere might use them.

None of this makes x86 elegant. But it makes x86 real. This is the hardware you
have. These are the rules you play by.

## What "x86" Means for Anton

When we say Anton targets x86, here is what that concretely means:

**Phase 1 (Bootloader)**: The CPU starts in **16-bit real mode**. We write a
bootloader in assembly that runs in this mode. We can use BIOS services
(keyboard, screen, disk) through software interrupts. Memory is limited to 1 MB
and addressed through segment:offset pairs.

**Phases 2 through 10 (Kernel)**: We switch the CPU into **32-bit protected
mode** (also called IA-32). This is where we spend most of the book. We have
32-bit registers (`EAX`, `EBX`, etc.), a flat 4 GB address space, hardware
privilege rings (ring 0 for the kernel, ring 3 for user programs), and paging
for virtual memory. The kernel is written in C with some assembly for hardware
interaction.

**Phase 11 (64-bit Transition)**: We switch the CPU into **64-bit long mode**
(x86-64). Registers widen to 64 bits (`RAX`, `RBX`, etc.), the address space
becomes enormous, and we get some architectural improvements. But the
fundamentals are the same: fetch, decode, execute. Registers, memory, I/O.

## Why Not ARM? Why Not RISC-V?

You might wonder why we do not target a cleaner, more modern architecture. ARM
powers every phone on the planet and is making serious inroads into laptops and
servers. RISC-V is an open-source instruction set that is gaining momentum in
education and embedded systems. Both are simpler and more elegant than x86.

The answer is pragmatic. x86 has the best tooling for OS development. QEMU
emulates x86 brilliantly. GCC and NASM produce excellent x86 code. The Intel and
AMD manuals are freely available and exhaustively detailed. Decades of OS
development tutorials, forums, and wikis target x86. When you get stuck (and you
will get stuck), the answer to your specific x86 question is almost certainly
already on the internet.

ARM and RISC-V are great architectures for other projects. For learning how to
build an operating system from scratch, x86 is the path with the fewest
unnecessary obstacles.

## What You Need to Know Going Forward

The rest of this chapter is a deep dive into the x86 architecture as it matters
to Anton. We will cover the registers you will use every day, how memory
addressing works in real mode and protected mode, the instruction set that the
CPU understands, how the call stack works, the privilege ring system that
separates kernel code from user code, and the exception and interrupt mechanism
that lets the CPU respond to errors and hardware events.

By the end of this chapter, you will know the machine. Not in the abstract. Not
"a CPU." This CPU. The one that will run every line of code we write.
