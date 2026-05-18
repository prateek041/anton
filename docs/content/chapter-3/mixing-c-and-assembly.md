---
title: "Mixing C and Assembly"
order: 25
---

# Mixing C and Assembly

The bootloader is pure assembly. The kernel is mostly C. But the kernel
constantly needs to do things that C cannot express: reading control registers,
writing to I/O ports, disabling interrupts, halting the CPU. The solution is
**inline assembly**: embedding assembly instructions directly inside C
functions, so the compiler can integrate them into the generated code.

GCC provides a powerful (and initially confusing) inline assembly syntax. This
section breaks it down piece by piece, then shows you the practical helper
functions we will build for Anton's kernel.

## The Basic Syntax

GCC inline assembly uses the `asm` keyword (or `__asm__` for strict C standard
compliance). The simplest form is:

```c
asm("cli");
```

This emits the `CLI` instruction (disable hardware interrupts) directly into the
compiler's output. No operands, no complications.

But most assembly instructions need to interact with C variables. For that, you
need the extended syntax:

```c
asm volatile (
    "assembly template"
    : output operands
    : input operands
    : clobber list
);
```

Four parts, separated by colons:

1. **Assembly template**: A string containing the assembly instructions. Uses
   `%0`, `%1`, etc. as placeholders for operands.
2. **Output operands**: C variables that receive results from the assembly.
3. **Input operands**: C variables whose values feed into the assembly.
4. **Clobber list**: Registers or resources the assembly modifies that GCC needs
   to know about.

The `volatile` keyword tells GCC "do not optimize this away or rearrange it,
even if it looks like it has no effect." For hardware operations, you almost
always want `volatile`.

![Anatomy of GCC inline assembly](../images/ch3/inline-asm-anatomy.svg)

## A Concrete Example: Reading CR0

Let's start with a real example. We want to read the current value of the `CR0`
control register into a C variable:

```c
static inline uint32_t read_cr0(void) {
    uint32_t val;
    asm volatile ("mov %0, cr0" : "=r" (val));
    return val;
}
```

Breaking this down:

- `"mov %0, cr0"` is the assembly template. `%0` is a placeholder for the first
  operand.
- `"=r" (val)` is the output operand. `"=r"` means "the result goes into any
  general-purpose register" and `(val)` is the C variable that receives the
  value. The `=` means write-only.
- There are no input operands and no clobber list (so those sections are empty
  and omitted).

GCC might compile this into `mov eax, cr0`, with `val` being mapped to `EAX`. Or
it might use `ECX` or `EDX`. The `"r"` constraint lets the compiler choose
whichever register is most convenient.

## Constraint Letters

Constraints tell GCC how to map C variables to assembly operands. Here are the
ones you will use in kernel development:

### Output Constraints (prefixed with `=`)

| Constraint | Meaning                      |
| ---------- | ---------------------------- |
| `"=r"`     | Any general-purpose register |
| `"=a"`     | `EAX` specifically           |
| `"=b"`     | `EBX` specifically           |
| `"=c"`     | `ECX` specifically           |
| `"=d"`     | `EDX` specifically           |
| `"=m"`     | A memory location            |
| `"=S"`     | `ESI`                        |
| `"=D"`     | `EDI`                        |

The `=` prefix means the operand is output-only (written but not read). If the
assembly both reads and writes the operand, use `"+"` instead of `"="`:

```c
asm volatile ("inc %0" : "+r" (count));
```

This reads `count` into a register, increments it, and writes the result back.

### Input Constraints

| Constraint | Meaning                                                     |
| ---------- | ----------------------------------------------------------- |
| `"r"`      | Any general-purpose register                                |
| `"a"`      | `EAX`                                                       |
| `"N"`      | A constant in the range 0-255 (useful for I/O port numbers) |
| `"i"`      | An integer constant                                         |
| `"m"`      | A memory location                                           |

Input constraints do not have the `=` prefix because the compiler does not
expect them to be modified.

### A Two-Operand Example: Writing to an I/O Port

```c
static inline void outb(uint16_t port, uint8_t val) {
    asm volatile ("out %1, %0"
        :
        : "a" (val), "Nd" (port)
    );
}
```

Let's decode this:

- `"out %1, %0"`: The `OUT` instruction. `%0` is the first operand (the value),
  `%1` is the second (the port number). Note that Intel syntax for `OUT` is
  `OUT port, value`, so the port comes first.
- No output operands (the first `:` section is empty).
- `"a" (val)`: The value must be in `AL`/`AX`/`EAX` (the `OUT` instruction
  requires this). We pass `val`.
- `"Nd" (port)`: The port can be either an immediate byte (`N`, for ports 0-255)
  or the `DX` register (`d`). GCC picks whichever form works. We pass `port`.

The complementary function for reading:

```c
static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    asm volatile ("in %0, %1"
        : "=a" (ret)
        : "Nd" (port)
    );
    return ret;
}
```

Same pattern, reversed: the output goes into `AL` (constraint `"=a"`), the port
number is the input.

## The Clobber List

The clobber list tells GCC which registers (or other resources) your inline
assembly modifies that are not captured by the output operands. This is critical
for correctness.

Consider this example that reads from the `CPUID` instruction:

```c
static inline void cpuid(uint32_t leaf, uint32_t *eax, uint32_t *ebx,
                          uint32_t *ecx, uint32_t *edx) {
    asm volatile ("cpuid"
        : "=a" (*eax), "=b" (*ebx), "=c" (*ecx), "=d" (*edx)
        : "a" (leaf)
    );
}
```

`CPUID` reads `EAX` (the leaf number) and writes to `EAX`, `EBX`, `ECX`, and
`EDX`. All four output registers are captured by output operands, so the clobber
list is empty. GCC knows exactly what changed.

But what if you have assembly that modifies a register that is not an output?

```c
asm volatile (
    "mov ecx, 100\n\t"
    "some_loop: dec ecx\n\t"
    "jnz some_loop"
    :
    :
    : "ecx"
);
```

Here, `ECX` is used as a loop counter inside the assembly, but it is not an
output. Without `"ecx"` in the clobber list, GCC might have been keeping an
important value in `ECX`, and your assembly just destroyed it. The clobber list
says "I trashed `ECX`, do not trust its previous value."

### Special Clobbers

Two special clobber entries appear frequently:

**`"memory"`**: Tells GCC that the assembly reads or writes memory in ways the
compiler cannot track. This forces GCC to flush any cached values from registers
back to memory before the assembly, and reload them afterward. Use this whenever
your assembly writes to memory that C code also accesses (for example, writing
to a memory-mapped device, or modifying a shared data structure).

**`"cc"`**: Tells GCC that the assembly modifies the condition code flags
(`EFLAGS`). Most arithmetic and logic instructions do this, so `"cc"` is
commonly included. On x86, GCC often assumes flags are clobbered anyway, but
being explicit is safer.

A realistic example combining all of these:

```c
static inline void invlpg(void *addr) {
    asm volatile ("invlpg [%0]" : : "r" (addr) : "memory");
}
```

`INVLPG` invalidates the TLB entry for the page containing `addr`. The
`"memory"` clobber tells GCC that memory mappings may have changed, so it must
not assume cached memory values are still valid.

## When to Use Inline Assembly vs. Separate Files

Inline assembly and separate `.asm` files are both tools for embedding assembly
in a C project. Here is when to use each.

**Use inline assembly for:**

- Single-instruction operations: `CLI`, `STI`, `HLT`, `INVLPG`, reading/writing
  control registers, I/O port access.
- Small sequences (2-5 instructions) that interact heavily with C variables.
- Operations where the compiler needs to know the result for further
  optimization (the output constraint lets it track the value).

These are typically wrapped in `static inline` functions in a header file, so
the compiler can inline them at every call site without the overhead of a
function call.

**Use separate `.asm` files for:**

- The bootloader (hundreds of lines of 16-bit real mode code).
- Interrupt entry stubs (must control the stack layout precisely).
- The context switch routine (saves and restores the entire register set).
- Any sequence longer than about 10 instructions, where the GCC inline assembly
  syntax becomes awkward and hard to read.
- Code that mixes 16-bit and 32-bit modes (GCC's inline assembly cannot handle
  `BITS 16`).

The general rule: if you can express it as a one-liner wrapped in a
`static inline` function, use inline assembly. If it is a major routine with its
own control flow, write it in a separate NASM file and link it with your C code.

![Inline assembly vs separate .asm files](../images/ch3/inline-vs-separate.svg)

## Practical Helper Functions for Anton

Here are the inline assembly helpers we will actually use in the kernel. These
will live in a header file and be included wherever hardware access is needed.

### I/O Port Access

```c
static inline void outb(uint16_t port, uint8_t val) {
    asm volatile ("out %1, %0" : : "a" (val), "Nd" (port));
}

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    asm volatile ("in %0, %1" : "=a" (ret) : "Nd" (port));
    return ret;
}

static inline void outw(uint16_t port, uint16_t val) {
    asm volatile ("out %1, %0" : : "a" (val), "Nd" (port));
}

static inline uint16_t inw(uint16_t port) {
    uint16_t ret;
    asm volatile ("in %0, %1" : "=a" (ret) : "Nd" (port));
    return ret;
}
```

These are the workhorses for communicating with hardware: the PIC, the PIT, the
keyboard controller, the disk controller, the serial port. Every device driver
calls `outb` and `inb`.

### I/O Wait

Some older hardware needs a brief delay between I/O operations. The standard
trick is to write to an unused port:

```c
static inline void io_wait(void) {
    asm volatile ("out 0x80, al" : : "a" ((uint8_t)0));
}
```

Port `0x80` is the POST diagnostic port. Writing to it takes just enough time to
satisfy slow hardware.

### Interrupt Control

```c
static inline void cli(void) {
    asm volatile ("cli");
}

static inline void sti(void) {
    asm volatile ("sti");
}

static inline void hlt(void) {
    asm volatile ("hlt");
}
```

`cli()` disables hardware interrupts (entering a critical section). `sti()`
re-enables them. `hlt()` halts the CPU until the next interrupt. The kernel's
idle loop is literally `for(;;) { hlt(); }`.

### Control Register Access

```c
static inline uint32_t read_cr0(void) {
    uint32_t val;
    asm volatile ("mov %0, cr0" : "=r" (val));
    return val;
}

static inline void write_cr0(uint32_t val) {
    asm volatile ("mov cr0, %0" : : "r" (val));
}

static inline uint32_t read_cr2(void) {
    uint32_t val;
    asm volatile ("mov %0, cr2" : "=r" (val));
    return val;
}

static inline uint32_t read_cr3(void) {
    uint32_t val;
    asm volatile ("mov %0, cr3" : "=r" (val));
    return val;
}

static inline void write_cr3(uint32_t val) {
    asm volatile ("mov cr3, %0" : : "r" (val));
}
```

`read_cr2()` is how the page fault handler gets the faulting address.
`write_cr3()` is how the kernel switches address spaces during a context switch.
`read_cr0()`/`write_cr0()` are used during boot to enable protected mode and
paging.

### TLB Invalidation

```c
static inline void invlpg(void *addr) {
    asm volatile ("invlpg [%0]" : : "r" (addr) : "memory");
}
```

When the kernel modifies a page table entry, the CPU's Translation Lookaside
Buffer (TLB) may still have the old mapping cached. `INVLPG` invalidates the
cache entry for a specific address. Without this, the CPU would use stale
translations and access the wrong physical memory.

## Naked Functions

GCC provides `__attribute__((naked))`, which tells the compiler to emit a
function with no prologue or epilogue. No `push ebp`, no `mov ebp, esp`, no
`pop ebp`, no `ret`. The function body is entirely your responsibility.

```c
__attribute__((naked)) void isr_stub(void) {
    asm volatile (
        "pusha\n\t"
        "call isr_handler\n\t"
        "popa\n\t"
        "iret"
    );
}
```

This is useful for interrupt stubs where the stack layout must be exactly what
the CPU pushed (EFLAGS, CS, EIP, and possibly an error code). A
compiler-generated prologue would push `EBP` and adjust `ESP` before you have a
chance to save the CPU-pushed values, corrupting the expected layout.

In practice, we will write most of our interrupt stubs in separate NASM files
rather than using naked functions, because NASM gives us more control over the
exact byte sequence. But naked functions are useful for very short stubs or when
you want to keep everything in one C file.

## A Word of Caution

Inline assembly is powerful, but it is also a source of subtle bugs. The
compiler trusts your constraint specifications completely. If you tell GCC that
a register is not modified (by leaving it out of the clobber list) when it
actually is, the compiler will generate incorrect code. There will be no warning
and no error. The bug will manifest as seemingly random corruption in unrelated
variables, and it will be extremely difficult to track down.

The rules are simple: declare every output, declare every input, clobber
everything you touch. When in doubt, add `"memory"` and `"cc"` to the clobber
list. A few unnecessary clobbers cost almost nothing in performance. A missing
clobber costs hours of debugging.

In the next section, we will look at the BIOS interrupt services available in
real mode: the firmware routines that provide video, disk, keyboard, and memory
detection services before the kernel has its own drivers.
