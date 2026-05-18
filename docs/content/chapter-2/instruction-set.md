---
title: "The x86 Instruction Set"
order: 16
---

# The x86 Instruction Set

The x86 instruction set is enormous. Intel's official manual documenting every
instruction is over 2,000 pages. But you do not need all of it. The vast
majority of kernel code, and nearly everything in Anton, uses a core set of
maybe 50 to 60 instructions. This section walks through those instructions
organized by what they do, with examples and notes about when you will use each
one in practice.

We are not writing runnable programs yet (that comes in Chapter 3). Think of
this as learning the vocabulary before you start writing sentences.

![x86 instruction set categories](../images/ch2/instruction-categories.svg)

## Data Movement

These instructions move data between registers, between registers and memory,
and between the stack and registers. They are the most common instructions in
any program.

### `MOV` (Move)

The workhorse. Copies a value from one place to another.

```text
MOV EAX, 5            ; put the number 5 into EAX
MOV EBX, EAX          ; copy EAX into EBX
MOV [0x1000], ECX     ; write ECX to memory address 0x1000
MOV EDX, [EBP - 4]    ; read a local variable into EDX
```

`MOV` does not "move" in the sense of removing the source. It copies. After
`MOV EBX, EAX`, both registers hold the same value.

One restriction: you cannot `MOV` directly from memory to memory. Both operands
cannot be memory addresses. To copy one memory location to another, you must go
through a register:

```text
MOV EAX, [source]     ; load from source
MOV [dest], EAX       ; store to dest
```

### `PUSH` and `POP`

`PUSH` writes a value to the top of the stack and decrements `ESP`. `POP` reads
from the top of the stack and increments `ESP`.

```text
PUSH EAX              ; ESP -= 4, then write EAX to [ESP]
POP EBX               ; read [ESP] into EBX, then ESP += 4
PUSH 42               ; push an immediate value
```

We will cover the stack in detail in section 2.5.

### `XCHG` (Exchange)

Swaps the values of two operands atomically.

```text
XCHG EAX, EBX         ; EAX and EBX swap their values
```

The atomicity matters: when one of the operands is a memory location, `XCHG`
automatically locks the bus, making it useful for implementing spinlocks. We
will use this in Phase 5 when we build synchronization primitives.

### `LEA` (Load Effective Address)

This instruction is deceptively powerful. It computes an effective address but
instead of reading from that address, it stores the address itself into the
destination register.

```text
LEA EAX, [EBX + ECX*4 + 8]
```

This does not access memory at all. It computes `EBX + ECX*4 + 8` and puts the
result in `EAX`. The CPU's address calculation hardware is being repurposed as a
general-purpose arithmetic unit. Compilers love `LEA` because it can do a
multiply-and-add in a single instruction. You will see it constantly in compiler
output.

## Arithmetic

### `ADD` and `SUB`

Add or subtract. The result replaces the first operand, and the flags are set.

```text
ADD EAX, 10           ; EAX = EAX + 10
SUB ECX, 1            ; ECX = ECX - 1
ADD EAX, EBX          ; EAX = EAX + EBX
ADD EAX, [0x1000]     ; EAX = EAX + value at address 0x1000
```

### `INC` and `DEC`

Increment or decrement by 1. Slightly more compact than `ADD`/`SUB` with 1, but
note that `INC`/`DEC` do not affect the carry flag. This matters in certain
multi-precision arithmetic scenarios.

```text
INC EAX               ; EAX = EAX + 1
DEC ECX               ; ECX = ECX - 1
```

### `NEG` (Negate)

Two's complement negation. Flips the sign of a value.

```text
NEG EAX               ; EAX = -EAX (equivalent to 0 - EAX)
```

### `MUL` and `IMUL` (Multiply)

Unsigned and signed multiplication. The basic form multiplies `EAX` by the
operand and stores the 64-bit result in `EDX:EAX` (high 32 bits in `EDX`, low 32
bits in `EAX`).

```text
MUL EBX               ; EDX:EAX = EAX * EBX (unsigned)
IMUL EBX              ; EDX:EAX = EAX * EBX (signed)
```

`IMUL` also has two- and three-operand forms that are more convenient:

```text
IMUL EAX, EBX         ; EAX = EAX * EBX (truncated to 32 bits)
IMUL EAX, EBX, 10     ; EAX = EBX * 10
```

### `DIV` and `IDIV` (Divide)

Unsigned and signed division. Divides the 64-bit value in `EDX:EAX` by the
operand. Quotient goes to `EAX`, remainder to `EDX`.

```text
XOR EDX, EDX          ; clear EDX (upper 32 bits of dividend)
MOV EAX, 100          ; lower 32 bits of dividend
DIV EBX               ; EAX = 100/EBX, EDX = 100 % EBX
```

If the divisor is zero, or if the quotient does not fit in 32 bits, the CPU
raises a Divide Error exception (#DE). This is one of the first exceptions you
will handle when building the interrupt system.

## Logic and Bitwise Operations

These operate on individual bits, exactly as we covered in Chapter 1.

### `AND`, `OR`, `XOR`, `NOT`

```text
AND EAX, 0xFF         ; mask: keep only the lowest byte
OR  EAX, 0x80         ; set bit 7
XOR EAX, EAX          ; zero out EAX (fastest way, smaller encoding than MOV
EAX, 0)
NOT EAX               ; flip all bits
```

`XOR EAX, EAX` deserves special mention. It is the standard way to zero a
register in x86 because it is shorter (2 bytes) than `MOV EAX, 0` (5 bytes) and
the CPU recognizes it as a zeroing idiom and optimizes accordingly.

### `SHL`, `SHR`, `SAR` (Shift)

```text
SHL EAX, 4            ; shift left by 4 (multiply by 16)
SHR EAX, 1            ; logical shift right by 1 (unsigned divide by 2)
SAR EAX, 1            ; arithmetic shift right by 1 (signed divide by 2,
preserves sign bit)
```

`SHL` and `SHR` are the unsigned versions. `SAR` (Shift Arithmetic Right)
preserves the sign bit, making it correct for dividing signed numbers by powers
of 2.

## Comparison

### `CMP` (Compare)

Subtracts the second operand from the first and sets the flags, but does not
store the result. Used before conditional jumps.

```text
CMP EAX, 5            ; compute EAX - 5, set flags
```

### `TEST`

ANDs the two operands and sets the flags, but does not store the result. Used to
check if specific bits are set.

```text
TEST EAX, EAX         ; is EAX zero? (sets ZF if so)
TEST EAX, 0x01        ; is bit 0 set? (sets ZF if not)
```

## Control Flow

### `JMP` (Unconditional Jump)

```text
JMP label             ; set EIP to the address of 'label'
```

### Conditional Jumps (`Jcc`)

There are many, but they all read the flags set by a previous `CMP`, `TEST`,
`SUB`, or `ADD`:

| Instruction   | Condition          | When to use                     |
| ------------- | ------------------ | ------------------------------- |
| `JE` / `JZ`   | ZF = 1             | Equal / result was zero         |
| `JNE` / `JNZ` | ZF = 0             | Not equal / result was not zero |
| `JL` / `JNGE` | SF != OF           | Less than (signed)              |
| `JG` / `JNLE` | ZF = 0 and SF = OF | Greater than (signed)           |
| `JLE` / `JNG` | ZF = 1 or SF != OF | Less than or equal (signed)     |
| `JGE` / `JNL` | SF = OF            | Greater than or equal (signed)  |
| `JB` / `JNAE` | CF = 1             | Below (unsigned less than)      |
| `JA` / `JNBE` | CF = 0 and ZF = 0  | Above (unsigned greater than)   |
| `JC`          | CF = 1             | Carry set                       |
| `JNC`         | CF = 0             | Carry not set                   |
| `JS`          | SF = 1             | Sign flag set (result negative) |
| `JO`          | OF = 1             | Overflow                        |

This looks like a lot, but in practice you use `JE`/`JNE` constantly, `JL`/`JG`
for signed comparisons, and `JB`/`JA` for unsigned comparisons. The rest are
variations.

### `CALL` and `RET`

`CALL` pushes the return address (the address of the instruction after the
`CALL`) onto the stack and jumps to the target. `RET` pops the return address
and jumps back.

```text
CALL my_function      ; push return address, jump to my_function
; ... execution continues here after my_function returns

my_function:
    ; ... do work ...
    RET               ; pop return address, jump back to caller
```

These are the foundation of function calls. We will explore them in depth in
section 2.5.

## String Operations

x86 has a set of instructions designed for bulk memory operations: copying,
filling, and scanning. They operate on bytes, words, or doublewords, using `ESI`
as the source pointer, `EDI` as the destination pointer, and `ECX` as the count.

### `REP MOVSB` (Repeat Move String Byte)

Copies `ECX` bytes from `[ESI]` to `[EDI]`, incrementing both pointers after
each byte.

```text
MOV ESI, source       ; source address
MOV EDI, dest         ; destination address
MOV ECX, 1024         ; number of bytes
CLD                   ; clear direction flag (increment pointers)
REP MOVSB             ; copy 1024 bytes
```

This is the assembly equivalent of `memcpy`. You will use it (or its 32-bit
variant `REP MOVSD`) in the kernel for copying memory blocks.

### `REP STOSB` (Repeat Store String Byte)

Fills `ECX` bytes at `[EDI]` with the value in `AL`.

```text
MOV EDI, dest         ; destination address
MOV AL, 0             ; fill value
MOV ECX, 4096         ; number of bytes
CLD
REP STOSB             ; zero 4096 bytes
```

This is the assembly equivalent of `memset`. You will use it to zero out pages
of memory.

### `SCASB` and `LODSB`

`SCASB` compares `AL` with the byte at `[EDI]` and advances `EDI`. Combined with
`REPNE` (repeat while not equal), it scans for a byte value in memory. `LODSB`
loads a byte from `[ESI]` into `AL` and advances `ESI`.

These are less common in kernel code but show up in string handling routines.

## I/O Instructions

### `IN` and `OUT`

These read from and write to I/O ports, the port-mapped I/O mechanism we covered
in Chapter 1.

```text
IN AL, 0x60           ; read one byte from port 0x60 (keyboard)
OUT 0x20, AL          ; write one byte to port 0x20 (PIC)
IN AX, DX             ; read a word from the port number in DX
OUT DX, EAX           ; write a doubleword to the port number in DX
```

The port number can be an immediate byte (0 to 255) or the value in `DX` (0 to
65,535). These instructions are privileged: they can only execute in ring 0.
User-space programs that attempt `IN` or `OUT` get a General Protection Fault.

You will use `IN` and `OUT` extensively for talking to the keyboard controller,
the interrupt controller (PIC), the timer (PIT), the disk controller (ATA), and
the serial port.

## System Instructions

### `INT` (Software Interrupt)

Triggers a software interrupt. The CPU looks up the handler in the Interrupt
Descriptor Table and jumps to it, just like a hardware interrupt.

```text
INT 0x80              ; trigger interrupt 0x80 (used for system calls on Linux)
INT 3                 ; breakpoint (used by debuggers)
```

### `IRET` (Interrupt Return)

Returns from an interrupt or exception handler by popping `EIP`, `CS`, and
`EFLAGS` from the stack. This is the counterpart to the CPU's automatic
state-saving when an interrupt fires.

### `HLT` (Halt)

Stops the CPU until the next hardware interrupt arrives. Used in the kernel's
idle loop: when there is nothing to do, halt and wait for an interrupt.

```text
HLT                   ; stop until next interrupt
```

### `CLI` and `STI` (Clear/Set Interrupt Flag)

`CLI` clears the interrupt flag in `EFLAGS`, disabling hardware interrupts.
`STI` sets it, re-enabling them.

```text
CLI                   ; disable interrupts (critical section begins)
; ... modify shared data structures ...
STI                   ; re-enable interrupts (critical section ends)
```

These are essential for protecting critical sections in the kernel. When you are
updating the page tables or modifying the scheduler's run queue, you cannot
afford an interrupt arriving in the middle of the operation. `CLI`/`STI` give
you that guarantee.

### `NOP` (No Operation)

Does nothing. Advances `EIP` by one byte. Used for alignment and as a
placeholder.

### `CPUID`

Queries CPU features. We cover this in section 2.8.

## Protected Mode Instructions

These instructions are used during boot and kernel initialization to set up the
CPU's operating environment.

### `LGDT` (Load Global Descriptor Table Register)

Loads the address and size of the GDT into the CPU's `GDTR` register. This is
the instruction that tells the CPU where the GDT lives in memory.

```text
LGDT [gdt_descriptor]  ; load GDT from the descriptor at this address
```

You execute this once during boot, right before switching to protected mode.

### `LIDT` (Load Interrupt Descriptor Table Register)

Loads the address and size of the IDT (Interrupt Descriptor Table) into the
`IDTR` register. This is how the CPU knows where to find interrupt and exception
handlers.

```text
LIDT [idt_descriptor]  ; load IDT from the descriptor at this address
```

### `LTR` (Load Task Register)

Loads a selector for the Task State Segment (TSS) into the task register. The
TSS is a data structure the CPU uses during privilege level transitions. We will
set this up in Phase 6 when we implement user mode.

### `LMSW` (Load Machine Status Word)

An older way to set the low 16 bits of `CR0`. Rarely used directly; we typically
use `MOV CR0, EAX` instead.

## Prefixes

x86 instructions can be modified by **prefixes**: one-byte modifiers placed
before the instruction.

**`REP`**: Repeats a string instruction `ECX` times, as we saw above. Variants
include `REPE` (repeat while equal) and `REPNE` (repeat while not equal).

**`LOCK`**: Makes the following instruction atomic with respect to other
processors. Used for implementing locks and atomic operations in a
multi-processor system.

```text
LOCK INC [counter]    ; atomically increment the value at 'counter'
```

**Segment override**: Forces an instruction to use a specific segment register
instead of the default. For example, `ES:[EDI]` uses the `ES` segment.

**Operand size override (`0x66`)**: Switches between 16-bit and 32-bit operands.
In 32-bit mode, this prefix makes an instruction operate on 16-bit values
instead of 32-bit.

**Address size override (`0x67`)**: Switches between 16-bit and 32-bit address
calculations. Mostly relevant when mixing 16-bit and 32-bit code.

You will not use prefixes often in handwritten assembly, but understanding them
helps when reading disassembly output or debugging instruction encoding issues.

## The Big Picture

That is a lot of instructions, but the pattern is consistent. Data movement
instructions (`MOV`, `PUSH`, `POP`, `LEA`) get values where they need to be.
Arithmetic and logic instructions (`ADD`, `SUB`, `AND`, `OR`, `SHL`) transform
values. Comparison instructions (`CMP`, `TEST`) set flags. Control flow
instructions (`JMP`, `Jcc`, `CALL`, `RET`) decide what to execute next. String
instructions (`REP MOVSB/STOSB`) handle bulk operations. I/O instructions (`IN`,
`OUT`) talk to hardware. System instructions (`INT`, `CLI`, `STI`, `HLT`) manage
the CPU's operating state.

Every program, from the simplest bootloader to the most complex kernel routine,
is built from these building blocks. In the next section, we will see how some
of these instructions work together to implement one of the most fundamental
patterns in computing: the call stack.
