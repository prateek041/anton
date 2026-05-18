---
title: "CPUID: Asking the CPU What It Is"
order: 20
---

# CPUID: Asking the CPU What It Is

Not all x86 CPUs are the same. A chip from 1995 does not support the same
features as a chip from 2025. Some CPUs support PAE (Physical Address
Extension). Some support SSE instructions. Some support the NX bit for marking
memory as non-executable. An operating system cannot just assume these features
exist. It needs to ask.

The mechanism for asking is the `CPUID` instruction. You tell it what you want
to know, it tells you the answer.

## How CPUID Works

The `CPUID` instruction takes no explicit operands. Instead, you set `EAX` to a
**leaf number** that identifies what information you want, and optionally set
`ECX` to a **sub-leaf** for more specific queries. Then you execute `CPUID`, and
the CPU fills `EAX`, `EBX`, `ECX`, and `EDX` with the results.

```text
MOV EAX, 0            ; leaf 0: vendor identification
CPUID                  ; results in EAX, EBX, ECX, EDX
```

Different leaf numbers give you different information. The CPU tells you how
many leaves it supports by returning the maximum supported leaf number when you
query leaf 0.

![CPUID instruction input and output registers](../images/ch2/cpuid-flow.svg)

## Leaf 0: Vendor Identification

When you execute `CPUID` with `EAX = 0`:

- `EAX` returns the maximum standard leaf number the CPU supports.
- `EBX`, `EDX`, `ECX` (in that order, not `EBX`, `ECX`, `EDX`) contain a
  12-character ASCII string identifying the CPU vendor.

For Intel processors, the string is `"GenuineIntel"`:

- `EBX` = `0x756E6547` ("Genu")
- `EDX` = `0x49656E69` ("ineI")
- `ECX` = `0x6C65746E` ("ntel")

For AMD processors, the string is `"AuthenticAMD"`:

- `EBX` = `0x68747541` ("Auth")
- `EDX` = `0x69746E65` ("enti")
- `ECX` = `0x444D4163` ("cAMD")

Note the unusual register order: `EBX`, `EDX`, `ECX`. This is one of those x86
quirks you just have to know.

In QEMU (which is what we will use to run Anton), the vendor string depends on
the emulated CPU model. The default is usually `"GenuineIntel"` or
`"AuthenticAMD"` depending on the host.

## Leaf 1: Feature Flags

This is the leaf you will use most. When you execute `CPUID` with `EAX = 1`:

- `EAX` returns the CPU's family, model, and stepping (identifying the exact
  chip revision).
- `EBX` returns additional information (brand index, cache line size, number of
  logical processors).
- `ECX` and `EDX` return **feature flags**: each bit indicates whether the CPU
  supports a specific feature.

The feature flags in `EDX` (leaf 1) that matter for OS development:

| Bit | Flag    | Feature                                                      
|
| --- | ------- |
------------------------------------------------------------------------ |
| 0   | FPU     | x87 Floating-Point Unit on chip                              
|
| 4   | TSC     | Time Stamp Counter (the `RDTSC` instruction)                 
|
| 5   | MSR     | Model-Specific Registers (the `RDMSR`/`WRMSR` instructions)  
|
| 6   | PAE     | Physical Address Extension (36-bit physical addresses)       
|
| 9   | APIC    | On-chip Advanced Programmable Interrupt Controller           
|
| 11  | SEP     | `SYSENTER`/`SYSEXIT` support                                 
|
| 13  | PGE     | Page Global Enable (global pages that are not flushed on
context switch) |
| 15  | CMOV    | Conditional move instructions (`CMOV`)                       
|
| 19  | CLFLUSH | Cache line flush instruction                                 
|
| 25  | SSE     | Streaming SIMD Extensions                                    
|
| 26  | SSE2    | SSE2                                                         
|

The feature flags in `ECX` (leaf 1):

| Bit | Flag   | Feature       |
| --- | ------ | ------------- |
| 0   | SSE3   | SSE3          |
| 20  | SSE4.2 | SSE4.2        |
| 21  | x2APIC | Extended APIC |

## Extended Leaves

Beyond the standard leaves (0 and above), x86 supports **extended leaves**
starting at `0x80000000`. You query the maximum extended leaf the same way:

```text
MOV EAX, 0x80000000
CPUID
; EAX now contains the maximum extended leaf number
```

The most important extended leaf for OS development is `0x80000001`, whose `EDX`
result includes:

| Bit | Flag | Feature                                                  |
| --- | ---- | -------------------------------------------------------- |
| 20  | NX   | No-Execute bit support (marking pages as non-executable) |
| 29  | LM   | Long Mode (64-bit mode) support                          |

The NX bit is a security feature that allows the OS to mark memory pages as
non-executable. Without it, a buffer overflow exploit can place machine code in
a data region and jump to it. With NX, the CPU raises a page fault if code tries
to execute from a page marked non-executable. We will enable this when we set up
paging.

The LM bit tells you whether the CPU supports 64-bit long mode. We will check
this in Phase 11 before attempting the transition.

## Why the OS Checks Features

You might wonder why we bother checking. If we are running in QEMU, we control
the emulated CPU and know what it supports. But checking CPU features is a best
practice that costs almost nothing and prevents subtle, hard-to-debug failures.

Consider PAE. If the kernel enables PAE paging without checking whether the CPU
supports it, and the CPU does not, the result is not a clear error message. It
is an immediate triple fault and a CPU reset. No stack trace, no crash dump,
just a reboot. Checking the CPUID flag first lets you print a useful error
message like "PAE not supported" and halt gracefully.

In Anton, we will add CPUID checks at the beginning of the kernel, before
enabling any optional CPU features. It takes a few lines of code and saves hours
of debugging.

## A Simple CPUID Routine

Here is the conceptual flow for checking whether the CPU supports a specific
feature:

```text
1. Set EAX to the appropriate leaf number.
2. Execute CPUID.
3. Test the specific bit in the result register.
4. If the bit is set, the feature is available. Proceed.
5. If the bit is clear, the feature is not available. Handle accordingly.
```

For example, to check for PAE support:

```text
MOV EAX, 1            ; leaf 1: feature flags
CPUID
TEST EDX, (1 << 6)    ; bit 6 of EDX = PAE
JZ no_pae             ; if zero, PAE not supported
; PAE is supported, proceed
```

We will write proper CPUID helper functions in C when we start building the
kernel in Phase 2.

## Wrapping Up Chapter 2

Let's look at where we are. We started this chapter by zooming from the generic
computer (Chapter 1) into the specific machine we are building on: x86. We
traced its history from the 8086 to modern x86-64, understanding why backward
compatibility forces every boot to start in 16-bit real mode.

We learned the registers: eight general-purpose registers for computation, six
segment registers for memory addressing, `EIP` for tracking execution, `EFLAGS`
for recording the outcomes of operations, and control registers for managing CPU
modes.

We covered memory addressing: segment:offset in real mode, GDT-based
segmentation in protected mode, and the page-table translation that maps virtual
addresses to physical ones. We learned the effective address formula that lets a
single instruction compute complex memory offsets.

We surveyed the instruction set: data movement, arithmetic, logic, comparison,
control flow, string operations, I/O, and system instructions. We saw how the
call stack gives every function its own workspace, how the cdecl calling
convention lets C and assembly interoperate, and how the privilege ring system
enforces the boundary between kernel and user code.

Finally, we looked at exceptions and interrupts, the mechanism the CPU uses to
handle errors and hardware events, and at CPUID, which lets the OS discover what
features the CPU provides.

This is the hardware platform. Every line of code we write for Anton, from the
first byte of the bootloader to the last system call handler, runs on this
machine. In Chapter 3, we will start writing code for it: assembly language, the
lowest-level programming language that maps directly to the x86 instructions we
just learned.
