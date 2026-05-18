---
title: "The CPU in Detail"
order: 10
---

# The CPU in Detail

We have talked about memory as the giant array of bytes where programs live. We
have talked about binary numbers and how to manipulate them. Now it is time to
look closely at the thing that brings it all together: the Central Processing
Unit.

The CPU is the engine of the computer. It does not store data long-term. It does
not talk to the screen or the keyboard directly. All it does is read
instructions from memory, one at a time, and execute them. But it does this so
fast, and with such a rich set of possible instructions, that the result is a
machine capable of doing anything you can describe as a sequence of steps.

## The Fetch-Decode-Execute Cycle

We introduced this cycle briefly in the first section. Now let's go through it
in real detail, because this is the loop that runs from the moment your computer
turns on to the moment it shuts off.

The CPU maintains a special register called the **instruction pointer** (or
**program counter**). On x86, this register is called `EIP` in 32-bit mode and
`RIP` in 64-bit mode. It holds the memory address of the next instruction the
CPU will execute. The entire cycle revolves around this one register.

### Step 1: Fetch

The CPU reads the value in the instruction pointer. Let's say it is
`0x00100000`. The CPU sends this address to the memory subsystem over the bus
and gets back the bytes stored at that location. Those bytes are the next
instruction.

Instructions are not all the same size. Some x86 instructions are just 1 byte
long. Others can be up to 15 bytes. The CPU reads enough bytes to determine the
complete instruction. (It knows how many bytes to read because the first byte,
called the **opcode**, tells it what kind of instruction this is and how long it
will be.)

### Step 2: Decode

Now the CPU has a sequence of bytes that represents an instruction. It needs to
figure out what this instruction means.

Let's say the bytes it fetched are `B8 05 00 00 00`. The CPU's decoding logic
examines this and determines:

- `B8` is the opcode for "move an immediate 32-bit value into the `EAX`
  register."
- `05 00 00 00` is the 32-bit value `0x00000005` in little-endian byte order
  (that is, the number 5).

So this instruction means: "put the value 5 into the `EAX` register."

In assembly language, we would write this as `MOV EAX, 5`. But the CPU does not
see assembly language. It sees `B8 05 00 00 00`. The assembler's job (which we
will cover in Chapter 3) is to translate human-readable assembly into these raw
bytes.

### Step 3: Execute

The CPU carries out the operation. In this case, it writes the value 5 into its
`EAX` register. For other instructions, execution might mean adding two register
values, reading a byte from a memory address, comparing two numbers, or jumping
to a different location in the code.

### Step 4: Advance

After executing the instruction, the CPU updates the instruction pointer to
point to the next instruction in memory. The instruction we just executed was 5
bytes long (`B8` + 4 bytes of the immediate value), so the instruction pointer
advances by 5: from `0x00100000` to `0x00100005`.

Then we go back to Step 1 and do it all again.

There are only two things that can change this progression. A **jump**
instruction explicitly sets the instruction pointer to a new address, breaking
the sequential flow. And an **interrupt** or **exception** (which we will cover
in detail in Chapter 2) can cause the CPU to temporarily jump to a handler
routine, regardless of what instruction it was about to execute.

But the fundamental rhythm never changes. Fetch, decode, execute, advance. Over
and over, billions of times per second.

![The fetch-decode-execute cycle in detail: CPU, bus, and memory
interaction](../images/ch1/fetch-decode-execute-detail.svg)

## What Machine Code Actually Is

Let's stay with this for a moment, because it is important. When we say a
program is "running," we mean the CPU is reading and executing **machine code**:
raw bytes in memory that the CPU interprets as instructions.

Machine code is not something you normally look at or write by hand. You write C
code or assembly code, and the compiler or assembler translates it into machine
code for you. But as an OS developer, you need to understand what machine code
is, because you will encounter it in debuggers, hex dumps, and disassembly
output.

Here are a few examples of x86 machine code:

| Machine Code (hex) | Assembly       | Meaning                                
|
| ------------------ | -------------- |
------------------------------------------- |
| `B8 05 00 00 00`   | `MOV EAX, 5`   | Put 5 into EAX                         
|
| `01 D8`            | `ADD EAX, EBX` | Add EBX to EAX, store result in EAX    
|
| `89 C3`            | `MOV EBX, EAX` | Copy EAX into EBX                      
|
| `CD 80`            | `INT 0x80`     | Trigger software interrupt 0x80        
|
| `EB FE`            | `JMP $`        | Jump to the current address (infinite
loop) |
| `F4`               | `HLT`          | Halt the CPU                           
|

A few things to notice. Instructions are different lengths: `HLT` is just 1
byte, `MOV EAX, 5` is 5 bytes. The first byte (or sometimes the first few bytes)
is the **opcode**, which tells the CPU what operation to perform. The remaining
bytes, if any, are the **operands**: registers, memory addresses, or immediate
values that the instruction operates on.

The CPU does not know or care that `B8` means "MOV EAX, immediate." It does not
know the word "MOV." Inside the CPU, the decoding hardware is a circuit that
takes in bit patterns and activates the appropriate functional units. But for us
humans, the assembly language representation is essential. It is the
lowest-level language we can reasonably read and write.

![Instruction encoding of MOV EAX, 5: opcode B8 followed by 4-byte immediate
value](../images/ch1/instruction-encoding.svg)

## Instruction Encoding

Let's break down one more example to see how an instruction is encoded in bytes.
Consider the instruction `ADD EAX, EBX`, which adds the value in register EBX to
the value in register EAX and stores the result in EAX.

The machine code is `01 D8`. Here is what each part means:

- `01` is the opcode for "ADD r/m32, r32" (add a 32-bit register to a 32-bit
  register or memory location).
- `D8` is the **ModR/M byte**, which encodes the two operands. This byte has
  three fields packed into it:
  - Bits 7-6 (the "Mod" field): `11`, meaning both operands are registers (no
    memory access).
  - Bits 5-3 (the "Reg" field): `011`, which is the code for EBX.
  - Bits 2-0 (the "R/M" field): `000`, which is the code for EAX.

So `01 D8` encodes: "add the register identified by bits 5-3 (EBX) to the
register identified by bits 2-0 (EAX)."

![ModR/M byte breakdown: Mod, Reg, and R/M fields in
0xD8](../images/ch1/modrm-byte.svg)

You do not need to memorize x86 instruction encoding. That is what assemblers
are for. But understanding that instructions are just structured byte patterns,
with opcodes and operand fields packed into specific bit positions, helps you
make sense of what you see in a disassembler. And it connects back to everything
we covered in the previous sections: bit fields, masks, the hex representation
of binary data. This is where it all comes together.

## The Instruction Pointer

Let's talk more about the instruction pointer, because this little register is
arguably the most important piece of state in the entire CPU.

The instruction pointer (`EIP` in 32-bit x86) always holds the address of the
next instruction the CPU will execute. You cannot read `EIP` directly in most
contexts. There is no `MOV EAX, EIP` instruction. But every `JMP`, `CALL`,
`RET`, and conditional branch instruction modifies it, and every normal
instruction advances it.

The instruction pointer is what makes programs sequential. Without it, the CPU
would have no idea what to do next. When you think about "where is the program
right now?", the answer is the value in `EIP`.

When Anton boots up, the CPU's instruction pointer starts at a fixed address
defined by the hardware (we will cover the exact details in Chapter 6, The Boot
Sequence). Our bootloader will be sitting at that address, and from that moment
forward, the CPU just follows the instruction pointer. Every piece of code our
OS runs, from the bootloader to the kernel to user-space programs, executes
because the instruction pointer eventually points to it.

When we get to multitasking in Phase 5, the concept of "switching between
processes" becomes concrete: you save one process's instruction pointer and
registers, load another process's instruction pointer and registers, and the CPU
continues executing from where the second process left off. The instruction
pointer is the thread of execution.

## Clock Speed and Cycles

The CPU does not execute instructions at random intervals. It is driven by a
**clock signal**: a regular electronic pulse that ticks at a fixed frequency.
Each tick is one **clock cycle**. The CPU does a small unit of work on each
cycle.

When people say a CPU runs at "3 GHz," they mean the clock ticks 3 billion times
per second. Each tick is one cycle, which takes about 0.33 nanoseconds.

In the simplest model, the CPU executes one instruction per cycle. Fetch,
decode, execute, done. But modern CPUs are much more sophisticated than that:

**Pipelining**: Instead of finishing one instruction before starting the next,
the CPU overlaps them. While one instruction is being executed, the next one is
being decoded, and the one after that is being fetched. It is like an assembly
line in a factory. The throughput is one instruction per cycle, even though each
individual instruction takes multiple cycles to complete.

**Superscalar execution**: Modern CPUs have multiple execution units and can
execute multiple instructions in the same cycle, as long as the instructions do
not depend on each other.

**Out-of-order execution**: The CPU can reorder instructions to keep its
execution units busy, executing later instructions before earlier ones (as long
as the result is the same).

These optimizations are fascinating, but for building Anton, we do not need to
worry about them. Our OS will work correctly regardless of whether the CPU
pipelines, reorders, or executes multiple instructions at once. The hardware
guarantees that the visible behavior matches the simple sequential model: fetch,
decode, execute, advance.

What we do care about is the relationship between clock speed and memory speed.
We saw in the memory hierarchy that a RAM access takes roughly 100-200 clock
cycles. That means if the CPU needs a value from RAM and it is not in any cache,
the CPU sits idle for hundreds of cycles waiting for the data to arrive. This is
called a **memory stall**, and it is one of the biggest performance bottlenecks
in modern computing. The caches exist specifically to reduce these stalls by
keeping frequently used data close to the CPU.

For OS development, the practical takeaway is that "fast" is not just about
clock speed. A CPU with a slower clock but better caches might outperform a CPU
with a faster clock but more cache misses. Performance is complex, and clock
speed alone does not tell the story. But at the level we are working at, writing
a hobby OS, raw performance is not our primary concern. Correctness is. We just
need to understand enough about the CPU's timing to write code that does not
hang waiting forever for an I/O operation.

In the next and final section of this chapter, we will look at the bus system
that connects the CPU to everything else: memory, the screen, the keyboard, the
disk. This is the system bus, and understanding it explains how the CPU actually
talks to the rest of the machine.
