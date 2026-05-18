---
title: "CPU Privilege Levels"
order: 18
---

# CPU Privilege Levels

Here is a question that cuts to the heart of operating system design: if any
program can execute any instruction and access any memory address, what stops a
buggy or malicious program from destroying the entire system?

On the 8086, nothing stopped it. Real mode has no concept of privilege. Every
program is equally powerful, and a single bad write to the wrong address can
crash the whole machine. This is fine for a single-user computer running one
program at a time. It is completely unacceptable for an operating system that
runs multiple programs written by different people.

The x86 solution, introduced with the 80286 and refined in the 386, is a
hardware-enforced **privilege ring** system. The CPU itself knows the difference
between trusted code (the kernel) and untrusted code (user programs), and it
prevents untrusted code from doing dangerous things.

## The Ring Model

x86 defines four privilege levels, numbered 0 through 3. These are called
**rings**, and they are visualized as concentric circles with ring 0 at the
center and ring 3 at the outside.

**Ring 0** is the most privileged. Code running in ring 0 can execute any
instruction, access any memory address, and talk to any hardware device. This is
where the operating system kernel runs. Ring 0 is often called **kernel mode**
or **supervisor mode**.

**Ring 3** is the least privileged. Code running in ring 3 cannot execute
privileged instructions, cannot access memory that belongs to the kernel, and
cannot directly talk to hardware. This is where user-space programs run. Ring 3
is called **user mode**.

**Rings 1 and 2** exist in the architecture but are almost never used. They were
intended for device drivers and other semi-trusted code, but in practice,
operating systems found it simpler to use just two levels: ring 0 for the kernel
and everything it trusts, ring 3 for everything else. Linux, Windows, macOS, and
Anton all follow this two-ring model.

The current privilege level (CPL) is encoded in the lowest two bits of the `CS`
(Code Segment) register. When `CS` contains a selector with the lowest two bits
set to `00`, the CPU is in ring 0. When they are `11`, the CPU is in ring 3. You
cannot directly write to `CS` with a `MOV` instruction, so the privilege level
cannot be changed by ordinary code. The CPU controls ring transitions through
specific, well-defined mechanisms.

![x86 protection rings from Ring 0 (kernel) to Ring 3
(user)](../images/ch2/privilege-rings.svg)

## What Ring 0 Can Do

Code running in ring 0 has unrestricted access to the machine:

- **All instructions are available.** `CLI` (disable interrupts), `STI` (enable
  interrupts), `IN`/`OUT` (I/O ports), `HLT` (halt the CPU), `LGDT`/`LIDT` (load
  descriptor tables), writes to control registers (`CR0`, `CR3`, `CR4`), all of
  these execute normally.

- **All memory is accessible.** Ring 0 code can read and write any physical or
  virtual address, including the page tables themselves.

- **All I/O ports are accessible.** The kernel can talk directly to hardware
  devices using `IN` and `OUT`.

This is why the kernel must be trusted. Ring 0 code has the power to do
anything, including disabling all protections. A bug in the kernel can bring
down the entire system. A bug in a user program can only crash that program.

## What Ring 3 Cannot Do

Code running in ring 3 is restricted by the CPU hardware:

- **Privileged instructions are forbidden.** If a ring 3 program tries to
  execute `CLI`, `HLT`, `LGDT`, `MOV CR0, EAX`, or any other privileged
  instruction, the CPU immediately raises a **General Protection Fault** (#GP,
  exception 13). The operating system's exception handler catches this, and
  typically kills the offending program.

- **Kernel memory is inaccessible.** The page tables can mark pages as
  "supervisor only." When ring 3 code tries to read or write a supervisor page,
  the CPU raises a **Page Fault** (#PF, exception 14). The kernel's page fault
  handler catches this and kills the program.

- **I/O ports are restricted.** Whether ring 3 code can use `IN` and `OUT`
  depends on the I/O Permission Bitmap in the Task State Segment (TSS). In
  practice, the kernel sets this bitmap to deny all I/O to user programs. Any
  attempt triggers #GP.

The hardware does all of this checking automatically, on every instruction.
There is no performance cost for being in ring 3 (the CPU does not slow down).
The protection is built into the instruction decoding and memory access
pipelines.

## Why This Matters for Anton

The privilege ring system is the foundation of the security model we will build.
Here is how it maps to Anton's design:

**The kernel runs in ring 0.** All of Anton's kernel code, from the interrupt
handlers to the memory manager to the scheduler, runs with full CPU privileges.
The kernel can modify page tables, handle hardware interrupts, switch between
processes, and access any hardware device.

**User programs run in ring 3.** When we implement user-space programs in Phase
6, they will run in ring 3. They will not be able to directly access hardware,
modify the kernel's memory, or interfere with other programs. If a user program
needs to do something privileged (like reading from the disk or writing to the
screen), it must ask the kernel to do it through a **system call**.

**The boundary is enforced by hardware.** This is the key point. The separation
between kernel and user space is not a software convention or a "gentleman's
agreement." It is enforced by the CPU at the transistor level. A ring 3 program
physically cannot execute a `CLI` instruction. The silicon will not allow it.

## Ring Transitions

If ring 3 code cannot execute privileged instructions, how does a user program
ask the kernel to do something? It needs a controlled way to transition from
ring 3 to ring 0: a "gate" that the kernel controls.

There are several mechanisms for this on x86:

### Software Interrupts (`INT n`)

The classic approach. A user program executes `INT 0x80` (or whatever vector the
OS designates). The CPU looks up the handler in the Interrupt Descriptor Table,
verifies that the IDT entry permits calls from ring 3, switches to the kernel
stack, saves the user's state (including the ring 3 `CS`, `EIP`, `EFLAGS`, `SS`,
`ESP`), and begins executing the handler in ring 0.

The handler does whatever the user requested (reading a file, allocating memory,
sending a network packet), then returns to ring 3 using `IRET`, which restores
the saved state.

This is how Linux originally implemented system calls on x86, and it is how we
will implement them in Anton initially.

### `SYSENTER`/`SYSEXIT`

A faster mechanism introduced by Intel. Instead of going through the IDT (which
involves multiple memory reads), `SYSENTER` loads the kernel's `CS`, `EIP`,
`SS`, and `ESP` from Model-Specific Registers (MSRs) that the kernel set up at
boot. This is faster because it avoids the IDT lookup. `SYSEXIT` returns to
ring 3.

### `SYSCALL`/`SYSRET`

AMD's equivalent of `SYSENTER`/`SYSEXIT`, used in 64-bit mode. Even faster than
`SYSENTER` in some respects. This is what modern 64-bit Linux uses.

We will implement the `INT 0x80` approach first (Phase 6) because it is the
simplest to understand, then potentially upgrade to `SYSENTER`/`SYSEXIT` or
`SYSCALL`/`SYSRET` for performance.

## The Stack Switch

There is an important detail about ring transitions that we need to mention now,
even though we will not implement it until Phase 6.

When the CPU transitions from ring 3 to ring 0 (via an interrupt or `SYSENTER`),
it switches to a different stack. The kernel has its own stack, separate from
the user program's stack. If the kernel used the user's stack, a malicious
program could set `ESP` to point to invalid memory before triggering a system
call, crashing the kernel.

The CPU knows which stack to switch to by reading the **Task State Segment**
(TSS), a data structure that contains (among other things) the ring 0 stack
pointer (`SS0` and `ESP0`). When an interrupt moves the CPU from ring 3 to ring
0, it automatically loads `SS` and `ESP` from the TSS and pushes the old
(ring 3) `SS`, `ESP`, `EFLAGS`, `CS`, and `EIP` onto the new (ring 0) stack.

We will set up the TSS and the kernel stack when we implement user mode. For
now, the takeaway is that ring transitions are not just about changing the CPL.
They also involve switching stacks to maintain security.

## A Concrete Example

Let's trace through what happens when a ring 3 program executes `INT 0x80`:

1. The program is running in ring 3. `CS` has CPL = 3.
2. The CPU executes `INT 0x80`. It looks up vector `0x80` in the IDT.
3. The IDT entry has DPL (Descriptor Privilege Level) = 3, meaning ring 3 code
   is allowed to use this gate. (If DPL were 0, the CPU would raise #GP
   instead.)
4. The CPU reads the ring 0 stack from the TSS: `SS0` and `ESP0`.
5. The CPU switches to the ring 0 stack: loads `SS0` into `SS` and `ESP0` into
   `ESP`.
6. The CPU pushes the old `SS`, `ESP`, `EFLAGS`, `CS`, and `EIP` onto the ring 0
   stack.
7. The CPU loads the handler's `CS` and `EIP` from the IDT entry. The new `CS`
   has CPL = 0.
8. Execution begins in ring 0 at the handler's address.

After the handler finishes:

1. The handler executes `IRET`.
2. The CPU pops `EIP`, `CS`, `EFLAGS`, `ESP`, and `SS` from the stack.
3. The restored `CS` has CPL = 3. The CPU is back in ring 3.
4. The user program continues from where it left off.

This entire sequence is orchestrated by the hardware. The kernel just has to set
up the data structures (IDT, TSS, GDT) correctly. The CPU handles the actual
transitions.

![Ring transition sequence showing INT 0x80 system call
flow](../images/ch2/ring-transition.svg)

In the next section, we will look at the exception and interrupt system in
detail: what happens when things go wrong (exceptions) and what happens when
hardware needs attention (interrupts).
