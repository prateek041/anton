---
title: "Why Assembly?"
order: 22
---

# Why Assembly?

You just spent an entire chapter learning x86 registers, addressing modes, the
instruction set, the call stack, privilege rings, and the interrupt system. That
was the machine as it exists in silicon. Now it is time to talk to it.

The language the CPU speaks is machine code: raw bytes like `B8 05 00 00 00`.
You already know that those bytes mean `MOV EAX, 5`. But nobody writes raw bytes
by hand. Instead, you write **assembly language**: a human-readable text format
where each line corresponds to one (or occasionally a few) machine instruction.
An **assembler** translates your text into the bytes the CPU actually executes.

This chapter teaches you assembly language. Not all of it. Not the 2,000-page
Intel manual. Just the parts you will use to build an operating system.

## The Boot Sequence Demands It

When you press the power button, the CPU starts executing instructions at a
fixed address in 16-bit real mode. There is no operating system yet. There is no
C runtime. There is no stack. There is no `main()` function. There is no
`malloc`. There is no `printf`. There is nothing.

Somebody has to set all of that up. Somebody has to configure the segment
registers, create a stack by pointing `ESP` at a valid memory region, build the
Global Descriptor Table, flip the `PE` bit in `CR0` to enter protected mode, and
perform a far jump to reload `CS`. None of these operations can be expressed in
C, because C assumes a working environment already exists. The compiler emits a
function prologue that pushes `EBP` and adjusts `ESP`, but if `ESP` does not
point to valid memory yet, that prologue will crash the machine.

The bootloader is written in assembly because it has to be. It is the code that
bootstraps the environment that makes C possible.

## Performance-Critical Kernel Paths

Even after the bootloader hands off to the C kernel, certain operations must be
written in assembly.

**Context switching** is the act of saving one process's CPU state and loading
another's. This means saving all general-purpose registers, the instruction
pointer, the flags register, and the segment registers, then loading a
completely different set. The compiler cannot help here. It does not know you
want to replace every register simultaneously. You need to write the
`PUSH`/`POP` sequence yourself, in the exact order the CPU expects.

**Interrupt entry and exit** stubs are another case. When a hardware interrupt
fires, the CPU pushes `EFLAGS`, `CS`, and `EIP` onto the stack (and possibly
`SS` and `ESP` if there is a ring transition). Your handler must save the
remaining registers, call the C handler, restore the registers, and execute
`IRET`. The stack layout must be precise down to the byte. If you get it wrong,
`IRET` pops garbage into `EIP` and the machine crashes. A C function with its
compiler-generated prologue would disturb the stack layout before you have a
chance to save it.

**Atomic operations** like `LOCK CMPXCHG` (compare-and-swap) and `LOCK XADD`
(atomic fetch-and-add) are single instructions that the CPU executes atomically.
They are the building blocks of spinlocks, mutexes, and lock-free data
structures. While GCC provides built-in functions for some of these
(`__sync_val_compare_and_swap`), understanding the underlying assembly is
essential for debugging and for cases where the built-ins do not cover what you
need.

## Direct Hardware Access

Certain operations have no C equivalent at all, even with inline assembly
workarounds:

- Writing to control registers: `MOV CR0, EAX` enables protected mode.
  `MOV CR3, EAX` loads a new page directory.
- Loading descriptor tables: `LGDT [gdt_ptr]` tells the CPU where the GDT lives.
  `LIDT [idt_ptr]` does the same for the IDT.
- Special instructions: `HLT` halts the CPU until the next interrupt. `CLI`
  disables interrupts. `STI` enables them. `INVLPG [addr]` invalidates a single
  TLB entry.
- Port I/O: `IN AL, DX` reads a byte from an I/O port. `OUT DX, AL` writes one.
  These are how you talk to the keyboard controller, the PIC, the PIT, and the
  disk controller.

You will use inline assembly to wrap most of these into C helper functions (like
`outb()` and `inb()`), which we will cover in section 3.4. But you need to
understand the assembly first.

## Reading Compiler Output

Here is a reason for learning assembly that has nothing to do with writing it:
**reading it**.

When you compile a C function with `gcc -S`, the compiler outputs an assembly
listing showing exactly what machine code your C becomes. When a kernel function
behaves unexpectedly, when a variable seems to have the wrong value, when an
optimization breaks something, the assembly output tells you the truth. The C
source code is what you intended. The assembly is what actually happens.

Consider a simple C function:

```c
int add(int a, int b) {
    return a + b;
}
```

GCC with `-O0` (no optimization) produces something like:

```text
add:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    add eax, [ebp+12]
    pop ebp
    ret
```

You already know what every line does from Chapter 2. The prologue saves `EBP`
and sets up the frame. The function loads its first argument from `[EBP+8]`,
adds the second argument from `[EBP+12]`, and returns the result in `EAX`. The
epilogue restores `EBP` and returns.

With `-O2` (optimization), GCC might produce:

```text
add:
    mov eax, [esp+4]
    add eax, [esp+8]
    ret
```

The optimizer eliminated the frame pointer entirely. No `PUSH EBP`, no
`MOV EBP, ESP`. It accesses arguments directly relative to `ESP`. Same result,
fewer instructions. Being able to read this output lets you verify that the
compiler is doing what you expect and understand why performance differs between
optimization levels.

![From C source to machine code
pipeline](../images/ch3/c-to-assembly-pipeline.svg)

## How Much Assembly Do We Actually Write?

Let's be clear about the proportions. Anton's kernel will be thousands of lines
of C. The assembly portion is maybe 500 lines total, spread across:

- **The bootloader** (about 200 lines): Sets up the environment, loads the
  kernel from disk, switches to protected mode, and jumps to the C entry point.
- **Interrupt stubs** (about 50 lines): Small assembly wrappers that save
  registers, call the C handler, restore registers, and execute `IRET`. One stub
  per exception/interrupt vector, but most are generated by macros.
- **The context switch routine** (about 30 lines): Saves one process's registers
  and loads another's.
- **Inline assembly helpers** (about 100 lines across many small functions):
  `outb`, `inb`, `cli`, `sti`, `hlt`, `invlpg`, `read_cr0`, `write_cr0`, and
  similar one-liners.
- **GDT/IDT loading** (about 20 lines): The `LGDT` and `LIDT` sequences and the
  far jump after enabling protected mode.

That is it. Assembly is the scaffolding that supports the C building. You do not
write the entire building in assembly. But the scaffolding must be perfect,
because if it fails, the building collapses.

![Assembly vs C proportions in Anton](../images/ch3/assembly-in-anton.svg)

## What This Chapter Covers

In the following sections, we will learn the NASM assembler syntax that Anton
uses, write several complete assembly programs to practice the patterns we
learned in Chapter 2, explore how C and assembly code interoperate through
inline assembly and separate object files, and catalog the BIOS interrupt
services that the bootloader will use before protected mode makes them
unavailable.

By the end of this chapter, you will be able to read and write the assembly that
Anton needs. Not fluently, not from memory. But well enough to write a
bootloader, debug an interrupt handler, and understand what the compiler is
doing with your C code.
