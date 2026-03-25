# Anton — The Book: Complete Curriculum & Structure Design

> _A self-sufficient, context-complete textbook for building a real operating system from absolute zero — no CS degree required._

---

## Philosophy of This Book

This book operates on one unbreakable contract: **you will never encounter a concept in a phase chapter that you haven't already read about.** Every idea — no matter how small — that appears in the implementation chapters must have been built up from scratch in the prerequisite section. This includes syntax, tools, concepts, mental models, and the invisible "obviously everyone knows this" knowledge that trips up every self-taught builder.

The book is organized as follows:

```
Part I  — The Foundation (Prerequisites)     ← This is the entire universe you need
Part II — Phase 0: Dev Environment
Part III — Phase 1: Bootloader
Part IV  — Phase 2: Bare Kernel
Part V   — Phase 3: Memory Management
Part VI  — Phase 4: Timers & Keyboard
Part VII — Phase 5: Multitasking
Part VIII — Phase 6: User Mode & Syscalls
Part IX  — Phase 7: Storage & Filesystem
Part X   — Phase 8: ELF Loader & Shell
Part XI  — Phase 9: Graphics & Window Manager
Part XII — Phase 10: Networking
Part XIII — Phase 11: 64-bit Transition
Part XIV — Phase 12: Text Editor
Part XV  — Phase 13: Self-Hosting Compiler
```

Each Part II–XV follows the same internal chapter structure:

1. **Concept Chapter** — the theory unique to this phase
2. **Design Chapter** — decisions made for Anton specifically
3. **Implementation Chapter** — code, line by line
4. **Verification Chapter** — how to prove it works

---

# PART I — THE FOUNDATION

### _Everything a person needs to know before writing a single line of Anton_

This part is not a summary. It is a complete, self-contained education. It is long on purpose.

---

## Chapter 1 — How a Computer Actually Works

_The physical machine, from electrons to programs._

### 1.1 — What Is a Computer, Really?

- The stored-program concept: instructions and data live in the same memory
- The von Neumann architecture: CPU, memory, I/O, and the bus connecting them
- Harvard vs. von Neumann — why modern CPUs blur this line (cache, pipelines)
- What "running a program" means at the most primitive level

### 1.2 — Electricity, Logic Gates, and Binary

- How transistors work as switches (no physics PhD required — just the model)
- NOT, AND, OR, XOR gates from transistors
- How gates compose into adders, multiplexers, flip-flops
- Why computers use binary: only two stable voltage states
- Bits, nibbles, bytes, words, doublewords, quadwords — and why these sizes exist

### 1.3 — Number Systems and Arithmetic

- Binary, octal, decimal, hexadecimal — conversion between all four
- Why programmers use hex: one hex digit = 4 bits, two hex digits = one byte
- Binary addition, subtraction (two's complement)
- Two's complement in depth: why -1 is `0xFFFFFFFF`, overflow behavior
- Bitwise operations: AND, OR, XOR, NOT, left shift, right shift
- Masks: extracting and setting specific bits, why this pervades kernel code
- Sign extension: what happens when you widen a signed value

### 1.4 — Memory: The Giant Array

- Memory as a flat, byte-addressed array starting at address 0
- What an "address" is: just an index into that array
- Memory cells, bytes, alignment, and what "misaligned access" costs
- Endianness: little-endian vs. big-endian, and why x86 is little-endian
- Why the number `0x1234ABCD` stored at address 0x1000 looks like `CD AB 34 12` in memory
- Volatile memory (RAM) vs. non-volatile (disk, ROM, flash)
- Memory hierarchy: registers → L1/L2/L3 cache → RAM → disk (latency at each level)

### 1.5 — The CPU in Detail

- The fetch-decode-execute cycle: the heartbeat of every program
- The instruction set: what machine code actually is
- Instruction encoding: how `MOV EAX, 5` becomes bytes on disk
- The program counter (instruction pointer): what it is, why it matters
- Clock speed, cycles, and why "faster" is complex

### 1.6 — The System Bus

- Address bus, data bus, control bus — what each carries
- Memory-mapped I/O vs. port-mapped I/O
- Why writing to address `0xB8000` puts text on the screen (VGA)
- How the CPU talks to the keyboard, timer, disk: the I/O bus

---

## Chapter 2 — The x86 Architecture

_The specific CPU Anton runs on — registers, modes, instructions._

### 2.1 — Why x86?

- History: Intel 8086 → 286 → 386 → Pentium → modern x86_64
- Backward compatibility as a design philosophy — and its costs
- What "x86" means: 32-bit protected mode (IA-32) and 64-bit long mode (x86_64)
- Anton starts in 32-bit, transitions to 64-bit in Phase 11

### 2.2 — CPU Registers: The Scratch Pad

- What a register is: a tiny, fast memory cell inside the CPU itself
- General-purpose registers (32-bit): EAX, EBX, ECX, EDX, ESI, EDI, ESP, EBP
  - Conventional uses: EAX for return values, ECX for loop counters, ESP for stack, EBP for frame
  - Sub-registers: AX is lower 16 bits of EAX; AL is lower 8 bits of AX
- Segment registers: CS, DS, ES, FS, GS, SS — why they exist, what they do in protected mode
- The instruction pointer: EIP — you never read it directly, but every `JMP` changes it
- The FLAGS register: individual bits that record the outcome of operations
  - Zero flag (ZF), carry flag (CF), overflow flag (OF), sign flag (SF), direction flag (DF)
  - How `CMP` + `JE`/`JNE`/`JL`/`JG` works by setting and reading FLAGS
- Control registers: CR0, CR3, CR4 — enabling/disabling paging, protected mode
- Debug registers, performance counter registers — brief overview

### 2.3 — x86 Memory Addressing

- Real mode (16-bit): segment:offset addressing, the 1 MB limit, why it exists
- Segmentation: segment base + offset = linear address
- Protected mode (32-bit): the segmentation model changes; GDT-based
- Paging: linear address → physical address via page tables (preview — detailed in Chapter 9)
- The effective address calculation: `[base + index * scale + displacement]`
- Examples: `[EBX]`, `[EBP - 4]`, `[EAX + ECX*4 + 8]` — decoding each

### 2.4 — The x86 Instruction Set

- Data movement: `MOV`, `PUSH`, `POP`, `XCHG`, `LEA`
- Arithmetic: `ADD`, `SUB`, `MUL`, `IMUL`, `DIV`, `IDIV`, `INC`, `DEC`, `NEG`
- Logic: `AND`, `OR`, `XOR`, `NOT`, `SHL`, `SHR`, `SAR`
- Comparison: `CMP`, `TEST`
- Control flow: `JMP`, `JE`, `JNE`, `JL`, `JG`, `JLE`, `JGE`, `CALL`, `RET`
- String operations: `MOVS`, `STOS`, `SCAS`, `LODS` with `REP` prefix
- I/O: `IN`, `OUT` — reading and writing I/O ports
- System: `INT`, `IRET`, `HLT`, `CLI`, `STI`, `NOP`, `CPUID`
- Protected mode specific: `LGDT`, `LIDT`, `LLDT`, `LTR`, `LMSW`
- Prefixes: `REP`, `LOCK`, `segment override`, `operand size`, `address size`

### 2.5 — The Call Stack

- What the stack is: a region of memory used LIFO (Last In, First Out)
- ESP (stack pointer): always points to the top of the stack
- `PUSH`: decrements ESP by 4, writes to [ESP]
- `POP`: reads from [ESP], increments ESP by 4
- `CALL`: pushes return address (EIP+instruction_size), jumps to target
- `RET`: pops return address into EIP
- Stack frames: how functions create their own local variable space
  - Prologue: `PUSH EBP; MOV EBP, ESP; SUB ESP, N`
  - Epilogue: `MOV ESP, EBP; POP EBP; RET`
- EBP: the frame pointer, why it makes stack walking possible
- What happens when the stack overflows: the classic stack overflow bug
- The calling convention (cdecl): who pushes arguments, who cleans them up, what EAX holds on return

### 2.6 — CPU Privilege Levels (Rings)

- The ring model: rings 0–3, why x86 implements hardware privilege
- Ring 0 (kernel mode): unrestricted access to all instructions, all memory, all I/O
- Ring 3 (user mode): restricted — cannot execute privileged instructions
- Rings 1 and 2: exist in the architecture, never used in practice by modern OSes
- What happens when user code tries a privileged instruction: General Protection Fault
- Why this matters for OS design: the kernel must be in ring 0; user programs in ring 3
- The ring transition mechanism (preview — detailed in Chapter 15): `int 0x80`, `syscall`

### 2.7 — CPU Exceptions and Interrupts

- The distinction: exceptions are synchronous (caused by the instruction being executed); interrupts are asynchronous (caused by hardware)
- The full x86 exception table (vectors 0–31):
  - #DE (0): Divide Error
  - #DB (1): Debug
  - #NMI (2): Non-Maskable Interrupt
  - #BP (3): Breakpoint
  - #OF (4): Overflow
  - #BR (5): Bound Range Exceeded
  - #UD (6): Invalid Opcode
  - #NM (7): Device Not Available
  - #DF (8): Double Fault
  - #TS (10): Invalid TSS
  - #NP (11): Segment Not Present
  - #SS (12): Stack-Segment Fault
  - #GP (13): General Protection Fault
  - #PF (14): Page Fault
  - #MF (16): x87 Floating-Point
  - #AC (17): Alignment Check
  - #MC (18): Machine Check
- Hardware IRQs: vectors 32–255 (remapped from BIOS defaults by the PIC)
- What the CPU does on an interrupt/exception: save EFLAGS, CS, EIP on the stack; look up IDT; jump to handler
- Error codes: which exceptions push an error code and what it encodes
- The IRET instruction: restoring state after an interrupt handler

### 2.8 — CPUID: Asking the CPU What It Is

- The CPUID instruction: EAX=leaf selects what info you get
- Detecting feature flags: PAE, SSE, NX bit, APIC presence
- Why the OS needs to check features before using them

---

## Chapter 3 — Assembly Language

_Writing code that speaks directly to the CPU._

### 3.1 — Why Assembly?

- The boot sequence requires assembly: the CPU starts with no C runtime
- Performance-critical paths: context switching, interrupt entry/exit
- Direct hardware access patterns that C cannot express
- Reading assembly output from the compiler: understanding what GCC actually produces

### 3.2 — NASM Syntax

- NASM vs. GAS: two assembler dialects, why Anton uses NASM
- Intel syntax vs. AT&T syntax: destination, source order
- Directives: `BITS 16`, `BITS 32`, `ORG`, `SECTION`, `GLOBAL`, `EXTERN`
- Data definitions: `db`, `dw`, `dd`, `dq`, `times`, `resb`, `resw`, `resd`
- Labels: local labels (`.loop`), global labels (`_start`), label arithmetic
- Macros: `%define`, `%macro`, `%endmacro`
- Including files: `%include`
- The `$` and `$$` symbols: current address, section start

### 3.3 — Writing Your First Assembly Programs

- A "Hello World" in pure assembly (for NASM flat binary)
- A loop in assembly: the loop-counter pattern with ECX and `LOOP`
- A function call in assembly: the full prologue/epilogue dance
- Calling a C function from assembly (and vice versa): the ABI interface
- Reading and writing memory from assembly
- Conditional logic: CMP + Jcc chains

### 3.4 — Mixing C and Assembly

- `__asm__` volatile in GCC: inline assembly syntax
- Input and output operands: `"=r"`, `"r"`, `"m"`, `"i"` constraint letters
- Clobber list: why you must tell GCC what registers you trashed
- When to use inline assembly vs. a separate `.asm` file
- Naked functions: a C function with no prologue/epilogue

### 3.5 — x86 BIOS Services (Real Mode Only)

- INT 0x10: video services (print character, set mode)
- INT 0x13: disk services (read sectors — used in the bootloader)
- INT 0x15 EAX=0xE820: memory map detection — the definitive way to ask BIOS "how much RAM is installed and where?"
- INT 0x16: keyboard services
- Why these all stop working after entering protected mode

---

## Chapter 4 — The C Programming Language

_The language Anton's kernel is written in — from scratch, assuming nothing._

### 4.1 — Why C?

- C as portable assembly: close to the metal without being architecture-specific
- Why C (not Rust, not C++, not Go) for a first OS: minimal runtime, predictable memory layout, decades of kernel examples
- What the C standard guarantees vs. what it leaves undefined

### 4.2 — Data Types and Sizes

- `char`, `short`, `int`, `long`, `long long` — sizes are platform-dependent, this is a problem
- `uint8_t`, `uint16_t`, `uint32_t`, `uint64_t`: the fixed-size types from `<stdint.h>` and why the kernel uses only these
- `size_t` and `uintptr_t`: types that hold memory sizes and addresses
- Signed vs. unsigned: when it matters, overflow behavior
- `void *`: the generic pointer type
- `NULL`: what it is (usually 0), why dereferencing it faults
- Structs: padding, alignment, and `__attribute__((packed))`
- Unions: using the same memory as different types
- Enums: named integer constants
- `sizeof`: getting the size of a type or variable at compile time

### 4.3 — Pointers and Memory

- A pointer is a variable that holds a memory address — nothing magical
- Declaring pointers: `int *p`, `char *s`, `void *v`
- The address-of operator `&`: getting the address of a variable
- The dereference operator `*`: reading the value at an address
- Pointer arithmetic: `p + 1` advances by `sizeof(*p)` bytes
- Arrays as pointers: why `arr[i]` is identical to `*(arr + i)`
- Pointer to pointer: `char **argv`
- Function pointers: `void (*handler)(void)` — storing and calling functions by address
- Common pointer bugs: null dereference, use-after-free, buffer overflow, dangling pointer
- Casting pointers: `(uint32_t *)0xB8000` — treating a raw address as a typed pointer

### 4.4 — Control Flow

- `if`, `else if`, `else`
- `while`, `do-while`, `for`
- `switch` / `case` / `default` / `break`
- `goto`: why it exists, when kernel code uses it (cleanup chains)
- `return`: returning values, early exit
- `break`, `continue` in loops

### 4.5 — Functions

- Declaration vs. definition
- Parameters: pass by value (copies), pass by pointer (the C substitute for pass by reference)
- Return values: single value only; returning structs by value vs. by pointer
- The `static` keyword on functions: file-scope linkage
- Variadic functions: `...` and `<stdarg.h>` — how `printf` works
- Recursion: when it's useful, when it'll blow the kernel stack

### 4.6 — The Preprocessor

- `#include`: copying a file's contents in-place; angle brackets vs. quotes
- `#define` for constants: `#define PAGE_SIZE 4096`
- `#define` for macros: function-like macros, their dangers (double evaluation)
- `#ifdef` / `#ifndef` / `#endif`: conditional compilation
- Include guards: why every header file needs `#pragma once` or an `#ifndef` guard
- `#pragma pack`: controlling struct alignment

### 4.7 — Scope, Linkage, and Storage

- Local variables: live on the stack, die when the function returns
- Global variables: live in the data segment, accessible everywhere
- `static` local: persists across function calls
- `extern`: declaring a variable defined in another file
- `volatile`: telling the compiler "this value can change outside your knowledge" — critical for memory-mapped I/O and interrupt-shared variables
- `const`: read-only data; `const` pointers vs. pointers to `const`
- `register` hint: largely irrelevant today

### 4.8 — C for Kernel Programming (Special Patterns)

- No standard library: there is no `malloc`, `printf`, `memset` from libc — you write your own
- No floating point in the kernel: the FPU/SSE state is not saved on interrupt entry unless you explicitly save it
- Freestanding C: the GCC flag `-ffreestanding` and what it permits
- Packed structs for hardware: `__attribute__((packed))` on GDT descriptors, IDT descriptors, packet headers
- `__attribute__((noreturn))`: functions that never return (`halt()`, `panic()`)
- `__attribute__((aligned(N)))`: enforcing alignment on buffers (page tables must be 4KB-aligned)
- `__attribute__((interrupt))`: GCC's interrupt handler function attribute
- Writing `memset`, `memcpy`, `memcmp`, `strlen`, `strcpy` from scratch
- Bit fields in structs: mapping individual bits of a register to named fields

---

## Chapter 5 — Compilers, Assemblers, Linkers, and Loaders

_The complete pipeline from source code to running program._

### 5.1 — What a Compiler Does

- The four stages: preprocessing → compilation → assembly → linking
- Stage 1 — Preprocessing (`cpp`): expanding `#include`, `#define`, conditional compilation; output is a pure C file with no directives
- Stage 2 — Compilation (`cc1`): parsing C into an intermediate representation; optimizing; emitting assembly text (`.s` file)
- Stage 3 — Assembly (`as`): translating assembly text to machine code in an object file (`.o`)
- Stage 4 — Linking (`ld`): combining object files and libraries into a final executable
- Seeing each stage: `gcc -E`, `gcc -S`, `gcc -c`, `gcc` (all stages)

### 5.2 — Object Files

- The ELF format (Executable and Linkable Format) for object files
- Sections inside an object file: `.text` (code), `.data` (initialized global data), `.bss` (zero-initialized global data), `.rodata` (read-only data like string literals)
- Symbols: the names of functions and globals, with their addresses (which are relocatable at this stage)
- Relocations: placeholders where the linker needs to fill in real addresses
- Reading an object file: `objdump -d`, `nm`, `readelf`

### 5.3 — The Linker

- What linking means: resolving symbols across object files
- The linker script: the most important file in the Anton build system
  - `ENTRY`: declaring the first instruction to execute
  - `SECTIONS`: deciding where `.text`, `.data`, `.bss` go in the final binary's address space
  - `. = 0x100000`: placing the kernel at 1 MB
  - The `. = ALIGN(4096)` idiom: page-aligning sections
  - `KEEP()`: preventing the linker from discarding symbol table entries
  - Providing symbols from the linker script that C code can use: `extern uint32_t _kernel_start;`
- Static vs. dynamic linking: why the kernel is always statically linked
- Undefined symbol errors: what they mean, how to fix them
- Multiple definition errors: what they mean, how to fix them

### 5.4 — The Loader

- What a loader does: the OS-level component that reads an executable and sets it up in memory
- In the context of the boot sequence: Stage 2 of the bootloader **is** a loader
- In Phase 8: Anton's ELF loader does this for user-space programs
- Loading steps: read the ELF header, parse program headers, map each segment to the right address, set up the stack, jump to the entry point
- The difference between the OS loader and the runtime dynamic linker

### 5.5 — Cross-Compilation

- Why you cannot use your host GCC to compile Anton: it targets Linux, links against Linux's libc, adds Linux's startup code
- What "target triple" means: `i686-elf` — architecture `i686`, vendor none, OS `elf` (bare metal)
- Building `i686-elf-gcc` from source: binutils first, then GCC (with `--without-headers`)
- The cross-compiler toolchain: `i686-elf-gcc`, `i686-elf-ld`, `i686-elf-objcopy`, `i686-elf-objdump`
- GCC flags critical for kernel builds:
  - `-ffreestanding`: no assumptions about a standard library
  - `-nostdlib`: do not link against any standard library
  - `-nostartfiles`: do not add the `crt0.o` startup object
  - `-fno-builtin`: do not replace functions with compiler built-ins
  - `-fno-stack-protector`: no stack canaries (the canary setup code requires libc)
  - `-mno-red-zone`: important for 64-bit; the red zone is an ABI assumption that breaks interrupt handlers
  - `-m32`: target 32-bit x86

### 5.6 — Build Systems: Make

- What Make is: a tool that rebuilds only the files that changed
- Makefile structure: targets, dependencies, recipes
- Pattern rules: `%.o: %.c` — compile every `.c` into a `.o`
- Variables: `CC`, `CFLAGS`, `LDFLAGS`, `OBJS`
- Phony targets: `all`, `clean`, `run`, `debug`
- Recursive make vs. non-recursive make
- Automatic variables: `$@` (target), `$<` (first dependency), `$^` (all dependencies)
- The Anton Makefile: understanding every line

---

## Chapter 6 — The Boot Sequence

_What happens between pressing the power button and the first line of kernel code running._

### 6.1 — Firmware: BIOS

- What BIOS is: firmware stored in ROM on the motherboard
- POST (Power-On Self-Test): what the BIOS checks before handing off
- BIOS vs. UEFI: what Anton uses (BIOS) and why, and what UEFI provides differently
- The boot device selection: BIOS reads the first sector of each boot device looking for the boot signature

### 6.2 — The Master Boot Record (MBR)

- The MBR: the very first 512 bytes of a bootable disk
- Structure: 446 bytes of bootstrap code + 64 bytes of partition table + 2-byte signature (`0x55 0xAA`)
- The BIOS loads the MBR to address `0x7C00` and jumps to it
- Why 512 bytes: the original IBM PC sector size, still with us today
- `ORG 0x7C00` in NASM: telling the assembler where the code will live

### 6.3 — Real Mode

- The CPU state at power-on: 16-bit real mode, all segment registers zeroed, CS:IP = `0xFFFF:0x0000` (jumps to BIOS ROM)
- After BIOS jumps to MBR: CS=0, IP=0x7C00
- Real mode memory addressing: `segment * 16 + offset`
- The 1 MB + 64 KB address space: why you cannot address more
- A20 line: the 21st address bit was disabled by default on 286+ for 8086 compatibility; you must enable it before entering protected mode

### 6.4 — Protected Mode

- Why protected mode: 32-bit registers, 4 GB address space, hardware memory protection, privilege rings
- Prerequisites for entering protected mode:
  1. Disable interrupts (`CLI`)
  2. Enable the A20 line
  3. Load the GDT (`LGDT`)
  4. Set bit 0 (PE) of CR0
  5. Far jump to flush the instruction pipeline and load CS
  6. Update all other segment registers
  7. Set up a stack
- What changes in protected mode: segment registers now hold selectors (indices into the GDT), not raw base addresses

### 6.5 — The Global Descriptor Table (GDT)

- The GDT: a table of 8-byte segment descriptors telling the CPU about memory segments
- A segment descriptor's fields: base address (32-bit), limit (20-bit), type, DPL (privilege level), present, granularity, default operation size
- The null descriptor: the first entry must always be zero
- The minimum GDT for Anton: null descriptor + code segment (ring 0) + data segment (ring 0)
- The GDT register (GDTR): loaded with `LGDT [gdtr_pointer]`; contains base address and limit of the GDT
- Segment selectors: index into the GDT, shifted left by 3 bits; the low 3 bits encode table type and RPL (Requested Privilege Level)
- The flat memory model: setting base=0, limit=0xFFFFFFFF for all segments, effectively disabling segmentation's address translation

### 6.6 — Loading the Kernel from Disk

- INT 0x13 AH=0x02: BIOS disk read — reads sectors from CHS (Cylinder, Head, Sector)
- INT 0x13 AH=0x42: extended BIOS disk read — reads sectors by LBA (Logical Block Address, a flat sector number)
- The DAP (Disk Address Packet) structure used by LBA reads
- Where to load the kernel: address `0x100000` (1 MB) is the conventional starting point
- Why you cannot load directly to 1 MB in real mode (above 0x100000 requires the A20 line and either unreal mode or protected mode)
- The two-stage strategy: Stage 1 (MBR) loads Stage 2 to `0x0600`; Stage 2 switches to protected mode, then loads the kernel to `0x100000`

---

## Chapter 7 — Memory: The Deep Dive

_RAM, virtual memory, paging — from hardware to software._

### 7.1 — Physical Memory

- RAM as a flat array of bytes, addressed from 0 to the top of installed RAM
- The x86 physical address space: what lives where
  - `0x00000000–0x000FFFFF` (0–1 MB): BIOS area, VGA memory, real-mode interrupt table
  - `0x00100000` (1 MB): start of usable RAM
  - `0xC0000000` (3 GB): conventional start of kernel virtual space in 32-bit
  - `0xFEC00000`+: APIC, PCI configuration space mapped here
- Detecting how much RAM is installed: INT 0x15 E820 map — a list of memory regions with types (usable, reserved, ACPI, bad)
- Physical Memory Manager: tracking which 4KB frames are free; the bitmap allocator
- Why 4 KB pages: the fundamental unit of the MMU

### 7.2 — Segmentation (The Old Way)

- How x86 segmentation originally worked (pre-386): dividing memory into segments
- In protected mode: the segment descriptor's base address is added to every effective address to get a linear address
- Why modern OSes use the flat model: set all segment bases to 0 so linear address = effective address
- Segmentation cannot be disabled on x86 — but it can be made invisible

### 7.3 — Paging (The Modern Way)

- The problem paging solves: isolation between processes, virtual address spaces, swap
- Virtual address vs. physical address: every process sees the same virtual layout; the MMU translates to different physical locations
- The Translation Lookaside Buffer (TLB): a cache of recent virtual→physical translations; `INVLPG` to flush one entry, `CR3` write to flush all
- x86 two-level paging (32-bit, non-PAE):
  - CR3: physical address of the page directory
  - Page Directory (PD): 1024 entries, each covering 4 MB; each entry points to a Page Table
  - Page Table (PT): 1024 entries, each covering 4 KB; each entry points to a physical frame
  - Virtual address bits: [31:22] = PD index, [21:12] = PT index, [11:0] = byte offset within page
  - Page directory entry fields: present, read/write, user/supervisor, write-through, cache-disable, accessed, dirty, PS (4 MB page), global, available, address
  - Page table entry fields: same, plus the physical frame address
- Enabling paging: set CR0.PG (bit 31) after loading CR3
- Kernel space vs. user space: the split at `0xC0000000`
- Kernel-mapped identity pages: mapping physical 0–N to virtual 0–N so the kernel can still run while paging is enabled
- Higher-half kernel: mapping the kernel at `0xC0100000` virtual while it lives at `0x00100000` physical
- Page faults (#PF): the CPU invokes the page fault handler when a virtual address has no valid mapping or when a write hits a read-only page; CR2 holds the faulting address
- Copy-on-write: a technique using read-only page mappings and fault-on-write (preview for Phase 5)

### 7.4 — The Kernel Heap

- Why a heap: dynamic allocation without knowing sizes at compile time
- The bump allocator: the simplest possible allocator — just move a pointer forward
- The free-list allocator: a linked list of free blocks; first-fit, best-fit, worst-fit strategies
- Block headers: size + free flag stored just before each allocation
- Coalescing: merging adjacent free blocks to prevent fragmentation
- Alignment: every allocation must be at least 8-byte aligned; why
- `kmalloc(size)` and `kfree(ptr)`: the kernel's two allocation functions
- Slab allocator: a production optimization — pre-allocating pools of same-size objects (preview)

---

## Chapter 8 — Interrupts and Hardware I/O

_How the CPU gets notified when hardware needs attention._

### 8.1 — Polling vs. Interrupts

- Polling: the CPU constantly asks "is there data yet?" — wastes cycles
- Interrupts: the hardware taps the CPU on the shoulder — efficient
- The interrupt request (IRQ) lines: hardware signals on dedicated pins
- Maskable vs. non-maskable interrupts: `CLI`/`STI` only mask maskable ones

### 8.2 — The 8259A PIC (Programmable Interrupt Controller)

- The 8259A: the classic IBM PC interrupt controller, two chained (master + slave)
- IRQ assignments: IRQ0=timer, IRQ1=keyboard, IRQ2=PIC cascade, IRQ3=COM2, IRQ4=COM1, IRQ6=floppy, IRQ7=parallel, IRQ8=RTC, IRQ14/15=ATA
- The BIOS programs the PIC to use vectors 0x08–0x0F and 0x70–0x77 — which conflict with CPU exceptions at 0x00–0x1F
- Remapping the PIC: sending initialization control words (ICWs) to I/O ports 0x20/0x21 (master) and 0xA0/0xA1 (slave) to move IRQs to vectors 0x20–0x2F
- The End-Of-Interrupt (EOI) command: sending `0x20` to port `0x20` after handling an IRQ
- Masking individual IRQs: write to the IMR (Interrupt Mask Register) at ports 0x21/0xA1
- APIC: the modern replacement for the 8259A (Anton uses the 8259A; brief overview of APIC for awareness)

### 8.3 — The Interrupt Descriptor Table (IDT)

- The IDT: a table of 256 8-byte interrupt gate descriptors
- IDT entry types: interrupt gate (clears IF on entry), trap gate (does not clear IF), task gate (not used)
- IDT entry fields: handler offset (low 16 bits), segment selector, type/DPL, present, handler offset (high 16 bits)
- The IDT register (IDTR): loaded with `LIDT [idtr_pointer]`
- Wiring all 256 vectors: the assembly trampoline pattern
- ISR trampolines: why you need assembly stubs for every exception handler
  - Exceptions without error codes: push a dummy 0 before pushing the vector number
  - Exceptions with error codes: the CPU pushes the error code automatically
- The common handler: all trampolines jump to one C function that dispatches by vector
- Stack frame layout on interrupt entry: SS, ESP (only if ring change), EFLAGS, CS, EIP, error code (if any), then your pushed registers

### 8.4 — Writing Interrupt Handlers

- Save all registers: `PUSHAD` (or individual pushes)
- Acknowledge the interrupt: send EOI to PIC
- Call the C handler
- Restore registers: `POPAD`
- Return: `IRET` (not `RET`) — restores EFLAGS, CS, EIP atomically
- Nested interrupts and reentrancy: when is it safe?
- The `volatile` keyword and memory barriers: why interrupt handlers must use them

### 8.5 — I/O Ports

- Port-mapped I/O on x86: a separate 64 KB address space accessed via `IN`/`OUT` instructions
- Common ports used in Anton:
  - `0x60/0x64`: PS/2 keyboard/mouse controller (8042)
  - `0x20/0x21`, `0xA0/0xA1`: PIC master and slave
  - `0x40–0x43`: PIT (Programmable Interval Timer)
  - `0x1F0–0x1F7`, `0x3F6`: ATA primary channel
  - `0x170–0x177`, `0x376`: ATA secondary channel
  - `0x3D4/0x3D5`: VGA CRT controller registers
  - `0x0CF8/0x0CFC`: PCI configuration space access
- The `outb`, `inb`, `outw`, `inw`, `outl`, `inl` helper functions
- I/O wait: why you sometimes need a tiny delay after an I/O write (the `outb(0x80, 0)` idiom)

---

## Chapter 9 — Processes, Scheduling, and Concurrency

_The illusion of simultaneous execution._

### 9.1 — What Is a Process?

- A process: a program in execution — code, data, stack, state
- Process vs. thread: a thread is a sequence of execution within a process's address space
- The Process Control Block (PCB): the kernel's data structure representing a process
  - PID (process ID)
  - State: running, ready, blocked, zombie
  - CPU register state (saved when not running)
  - Memory map: page directory, heap bounds, stack bounds
  - Open file table
  - Parent PID, signal mask, priority
- Process lifecycle: create → ready → running → (blocked ↔ ready) → terminated

### 9.2 — Context Switching

- What context switching means: saving all CPU state for process A, restoring all CPU state for process B
- State that must be saved: all general-purpose registers, EIP, EFLAGS, ESP, segment registers, optionally FPU/SSE state
- The kernel stack per process: why each process needs its own kernel stack for interrupt handling
- The context switch routine: always written in assembly; must not corrupt any register it doesn't explicitly save
- The illusion of parallelism: with context switches happening 100+ times per second, processes appear to run simultaneously

### 9.3 — Scheduling

- The scheduler: the kernel component that decides which process runs next
- Round-robin: each process gets a fixed time quantum; run them in circular order
- Priority scheduling: each process has a priority; higher-priority processes preempt lower ones
- Preemptive vs. cooperative: in preemptive scheduling, the timer interrupt forcibly switches processes; in cooperative, processes yield voluntarily
- Voluntary sleep: `sleep(ms)` — move a process to blocked state, wake it after N timer ticks
- Blocking on I/O: when a process reads from a keyboard that hasn't been typed yet, it blocks; the scheduler gives the CPU to someone else
- The run queue and wait queues: data structures the scheduler maintains

### 9.4 — Concurrency Hazards

- Race conditions: when two code paths access shared data and the outcome depends on timing
- Atomicity: the requirement that certain operations complete without interruption
- The critical section: the region of code that must not be interrupted
- Spinlocks: busy-wait until the lock is available; appropriate for kernel use (short critical sections, interrupt context)
- Disabling interrupts: the simplest mutual exclusion for single-core kernel code
- Deadlock: two parties each wait for a resource held by the other
- Priority inversion: a high-priority task blocked waiting for a low-priority task holding a lock

---

## Chapter 10 — File Systems and Storage

_Persistent data: how bits survive power-off._

### 10.1 — Storage Devices

- Spinning hard drives: platters, heads, CHS geometry, sectors
- SSDs: flash memory cells, wear leveling, garbage collection, why they're faster
- The sector: the fundamental unit of disk I/O (512 bytes historically; 4096 bytes on modern drives)
- ATA (IDE) interface: the most common interface for QEMU's emulated disk
- ATA PIO mode: the CPU directly issues commands via I/O ports; slow but simple
- ATA DMA mode: the disk controller writes directly to memory; faster (preview for advanced phases)
- Addressing sectors: CHS (legacy) vs. LBA28 vs. LBA48

### 10.2 — Filesystems: The Concept

- What a filesystem does: names files, tracks where their data lives on disk, handles free space
- Key abstractions: file (a named sequence of bytes), directory (a container of files and other directories), inode (metadata about a file)
- Common filesystems: FAT12/16/32 (simple, used in boot), ext2 (what Anton uses), ext4, NTFS, HFS+
- Why Anton uses ext2: well-documented, stable on-disk format, industry-standard inode model, no journal complexity

### 10.3 — ext2 On-Disk Layout

- The superblock: at offset 1024 from the start of the partition; contains filesystem metadata (block size, inode count, block count, etc.)
- Block groups: the filesystem is divided into fixed-size block groups; each group has a copy of the superblock + group descriptor
- The group descriptor table: per-group information (block bitmap location, inode bitmap location, inode table location)
- Block and inode bitmaps: one bit per block/inode; 0=free, 1=used
- The inode table: an array of inodes; inode N is at a fixed, calculable disk offset
- The inode structure: mode (file type + permissions), size, timestamps, 12 direct block pointers, 1 singly indirect pointer, 1 doubly indirect, 1 triply indirect
- Direct blocks: for files up to 12×block_size bytes, data is directly in the inode's block pointers
- Indirect blocks: for larger files; a block whose contents are more block pointers
- Directory entries: variable-size records inside a directory's data blocks; each contains inode number, entry length, name length, file type, name
- Path resolution: splitting a path by `/`, looking up each component as a directory entry, following inode pointers

### 10.4 — The Virtual File System (VFS)

- The VFS: an abstraction layer that presents a uniform interface regardless of underlying filesystem
- The VFS inode: a kernel-internal structure mirroring the on-disk concept
- VFS operations: `open`, `read`, `write`, `readdir`, `stat`, `create`, `unlink`, `mkdir`
- Function pointer tables (vtable pattern): each filesystem provides a set of operations; the VFS calls them generically
- Mounting: attaching a filesystem to a directory in the name tree
- The file descriptor: a per-process integer that indexes into the process's open file table; each entry points to a VFS file object

---

## Chapter 11 — The ELF Binary Format

_How executables are structured — from disk to memory._

### 11.1 — ELF Overview

- ELF (Executable and Linkable Format): the standard binary format on Linux and Anton
- Three types of ELF files: relocatable (`.o`), executable, shared library (`.so`)
- The ELF magic number: `\x7FELF` at offset 0 of every ELF file

### 11.2 — The ELF Header

- `e_ident`: magic, class (32/64-bit), endianness, version
- `e_type`: ET_REL, ET_EXEC, ET_DYN
- `e_machine`: EM_386 (0x03) for x86_32; EM_X86_64 (0x3E) for 64-bit
- `e_entry`: virtual address of the entry point
- `e_phoff`: offset of the program header table
- `e_shoff`: offset of the section header table
- `e_phentsize`, `e_phnum`: size and count of program headers
- `e_shentsize`, `e_shnum`: size and count of section headers

### 11.3 — Program Headers (Loading)

- Program headers describe how to load the file into memory
- `PT_LOAD`: a loadable segment — copy from `p_offset` in file to `p_vaddr` in memory, `p_filesz` bytes, zero-pad to `p_memsz`
- `PT_INTERP`: path to the dynamic linker (not used for statically-linked Anton executables)
- `PT_GNU_STACK`: stack permissions hint
- The loading algorithm:
  1. Read ELF header, verify magic
  2. Iterate program headers, for each PT_LOAD segment: allocate pages at `p_vaddr`, copy `p_filesz` bytes from file, zero remaining `p_memsz - p_filesz` bytes
  3. Jump to `e_entry`

### 11.4 — Section Headers (Linking)

- Section headers describe the file for the linker and debugger
- `.text`, `.data`, `.bss`, `.rodata`, `.symtab`, `.strtab`, `.debug_*`
- The symbol table: name, address, size, binding (local/global), type (function/object)
- Using `readelf -a`, `objdump -d`, `nm` to inspect ELF files

---

## Chapter 12 — Networking Fundamentals

_The protocol stack, from wire to HTTP._

### 12.1 — The OSI and TCP/IP Models

- OSI 7-layer model: Physical, Data Link, Network, Transport, Session, Presentation, Application
- TCP/IP 4-layer model (what matters): Link, Internet, Transport, Application
- Encapsulation: each layer wraps the layer above in its own header

### 12.2 — Ethernet and the Link Layer

- Ethernet frames: preamble + destination MAC (6 bytes) + source MAC (6 bytes) + EtherType (2 bytes) + payload + FCS
- MAC addresses: 48-bit hardware identifiers; the first 3 bytes are the OUI
- EtherType: `0x0800` = IPv4, `0x0806` = ARP, `0x86DD` = IPv6
- The NIC: network interface card; the hardware that sends and receives Ethernet frames
- PCI enumeration: finding the NIC on the PCI bus (config space, BARs)

### 12.3 — ARP (Address Resolution Protocol)

- The problem: you know the IP address of the next hop, but need its MAC address to send an Ethernet frame
- ARP request: broadcast "who has IP X.X.X.X?"
- ARP reply: "I have X.X.X.X; my MAC is Y"
- The ARP cache: storing recent IP→MAC mappings

### 12.4 — IPv4

- IPv4 header: version, IHL, DSCP, total length, identification, flags, fragment offset, TTL, protocol, checksum, source IP, destination IP
- IP addresses: 32-bit, written in dotted-decimal; network portion + host portion
- Subnets and CIDR: `/24` means 24 bits of network, 8 bits of host
- Routing: how does the kernel decide which NIC to use and where to send a packet?
- ICMP: the diagnostic protocol; echo request/reply (`ping`), destination unreachable, time exceeded

### 12.5 — UDP

- UDP header: source port, destination port, length, checksum
- Connectionless, unreliable: no handshake, no guaranteed delivery
- Why UDP: low latency; useful for DNS, DHCP, streaming

### 12.6 — TCP

- TCP header: source port, destination port, sequence number, acknowledgment number, data offset, flags (SYN, ACK, FIN, RST, PSH), window size, checksum, urgent pointer
- The 3-way handshake: SYN → SYN-ACK → ACK
- Reliable delivery: sequence numbers, acknowledgments, retransmission on timeout
- Flow control: the sliding window; receiver advertises how much buffer it has
- Connection teardown: FIN → FIN-ACK → ACK → ACK
- TCP state machine: CLOSED → LISTEN → SYN_RCVD → ESTABLISHED → FIN_WAIT → TIME_WAIT → CLOSED
- Why implementing TCP is the hardest part of Phase 10: handling all edge cases in the state machine

### 12.7 — DNS and DHCP

- DHCP: acquiring an IP address dynamically from a server; Discover → Offer → Request → Acknowledge
- DNS: resolving domain names to IP addresses; query type A for IPv4 address

### 12.8 — HTTP/1.0

- HTTP as text over TCP
- The request: `GET / HTTP/1.0\r\nHost: example.com\r\n\r\n`
- The response: status line + headers + blank line + body
- Why HTTP/1.0 (not 1.1): no persistent connections; simpler for a first implementation

---

## Chapter 13 — Graphics and Display

_Pixels, fonts, and how a framebuffer becomes a GUI._

### 13.1 — VGA Text Mode

- The VGA text buffer at `0xB8000`: a 80×25 array of 2-byte cells (character byte + attribute byte)
- Attribute byte encoding: background color (bits 7-4), foreground color (bits 3-0)
- VGA color codes: 0=black, 1=blue, 2=green, 3=cyan, 4=red, 5=magenta, 6=brown, 7=white, 8-15=bright variants
- Writing to VGA: just write to the right memory address
- Moving the hardware cursor: writing to VGA CRT controller via ports 0x3D4/0x3D5

### 13.2 — VBE (VESA BIOS Extensions) Framebuffer

- VBE: a BIOS extension allowing access to higher-resolution, higher-color video modes
- INT 0x10 AX=0x4F02: switching to a VBE mode (must be done in real mode, i.e., from the bootloader)
- The framebuffer: a contiguous block of memory where each element is a pixel
- Pixel formats: 32bpp BGRA, 24bpp RGB, 16bpp RGB565
- The VBE mode info block: getting framebuffer address, width, height, pitch, bits-per-pixel
- Pitch vs. width: pitch is the number of bytes per row, which may be larger than width × bytes_per_pixel
- Drawing a pixel: `framebuffer[y * pitch + x * 4] = color`

### 13.3 — Bitmap Fonts

- Font files: a bitmap font stores each character as a grid of bits
- The PC Screen Font (PSF) format: a standard bitmap font format for Linux consoles
- Rendering a character: for each bit in the glyph, draw a foreground or background pixel
- Fixed-width vs. variable-width fonts

### 13.4 — Window Manager Concepts

- The compositor: the code that owns the screen and composites all window surfaces onto it
- Z-ordering: which window is on top
- Dirty rectangles: only redraw regions that changed
- Double buffering: render to a back buffer, flip to the front — avoids tearing
- Window chrome: title bar, borders, close button
- Event model: how mouse clicks and key presses reach the correct window

---

## Chapter 14 — x86_64 and 64-bit Computing

_The architecture upgrade from 32-bit to 64-bit — what changes and why._

### 14.1 — Why 64-bit?

- 32-bit limit: 4 GB addressable RAM; modern machines need more
- 64-bit: 48-bit virtual addresses (in practice), 256 TB addressable; 64-bit registers
- x86_64 (AMD64) architecture: backward-compatible with 32-bit code

### 14.2 — New Registers

- Extended general-purpose registers: RAX, RBX, RCX, RDX, RSI, RDI, RSP, RBP (all 64-bit extensions of their 32-bit counterparts)
- New registers: R8–R15 (8 additional general-purpose registers)
- Sub-registers: R8D (32-bit), R8W (16-bit), R8B (8-bit)
- XMM registers: 128-bit SIMD; SSE2 is baseline for x86_64

### 14.3 — Long Mode

- Long mode: x86_64's name for 64-bit protected mode
- Entering long mode: requires protected mode + PAE paging enabled + EFER.LME bit set + paging enabled
- The EFER MSR: Extended Feature Enable Register; read/write via `RDMSR`/`WRMSR`
- 4-level paging (PML4): virtual address bits [47:39]=PML4 index, [38:30]=PDPT index, [29:21]=PD index, [20:12]=PT index, [11:0]=offset
- CR3 in long mode: points to the PML4 table (4 KB aligned)

### 14.4 — 64-bit System Calls: `syscall`/`sysret`

- `int 0x80` still works in 64-bit but is slow
- `syscall` instruction: uses MSRs (LSTAR, STAR, SFMASK) to define the kernel entry point
- `LSTAR` MSR: holds the 64-bit address of the syscall handler
- The `syscall`/`sysret` pair: fast ring 3→ring 0→ring 3 transition
- The 64-bit Linux syscall convention: syscall number in RAX; args in RDI, RSI, RDX, R10, R8, R9

### 14.5 — The System V AMD64 ABI

- The calling convention for 64-bit C on Linux/Anton:
  - Integer/pointer arguments: RDI, RSI, RDX, RCX, R8, R9 (first 6); then on stack
  - Floating-point arguments: XMM0–XMM7
  - Return value: RAX (integer), XMM0 (float)
  - Caller-saved: RAX, RCX, RDX, RSI, RDI, R8–R11
  - Callee-saved: RBX, RBP, R12–R15
- Why this matters: every cross-language call (C from assembly, assembly from C) must respect it

---

## Chapter 15 — The Standard C Library and Porting

_What libc provides, and how to bring it to Anton._

### 15.1 — What libc Is

- The C standard library: the layer between C programs and the OS
- Key components: `<stdio.h>` (I/O), `<stdlib.h>` (memory, process), `<string.h>` (string/memory operations), `<unistd.h>` (POSIX), `<sys/mman.h>`, `<signal.h>`, `<pthread.h>`
- Static vs. dynamic libc: glibc vs. musl vs. newlib
- Why Anton uses newlib: designed for bare-metal/embedded targets; the syscall layer is clearly separated into stubs that you replace with your own implementations

### 15.2 — Syscall Stubs in newlib

- newlib's `syscalls.c`: the set of POSIX functions newlib calls but does not implement — you must provide them
- Required stubs: `_write`, `_read`, `_open`, `_close`, `_lseek`, `_fstat`, `_isatty`, `_getpid`, `_kill`, `_exit`, `_sbrk` (for the heap), `_fork`, `_execve`, `_wait`
- Mapping each stub to an Anton syscall

### 15.3 — Cross-Compiling GCC to Run on Anton

- The host/build/target triple distinction: cross-compiling GCC to run on Anton (host=anton) and generate Anton binaries (target=anton)
- The dependency chain: newlib must be built first; GCC is then built against newlib
- `configure` options for each component
- Testing the self-hosted toolchain

---

## Chapter 16 — QEMU and Debugging

_Your eyes inside the machine._

### 16.1 — QEMU

- QEMU as a full system emulator: emulates the CPU, memory, disk, NIC, timer, keyboard, VGA
- Key QEMU flags for Anton:
  - `-cpu i686` / `-cpu qemu64`: the emulated CPU
  - `-drive file=myos.img,format=raw`: attach a raw disk image
  - `-m 128M`: set RAM size
  - `-serial stdio`: redirect the serial port to your terminal (useful for logging)
  - `-net nic,model=e1000 -net user`: attach an emulated Intel e1000 NIC with user-mode networking
  - `-s -S`: expose GDB stub on port 1234, wait for GDB before starting
  - `-no-reboot`: halt instead of rebooting on triple-fault (crucial for debugging boot crashes)
  - `-d int,cpu_reset`: log all interrupts and CPU resets to stderr
- The QEMU monitor: `Ctrl+Alt+2` opens it; `info registers`, `xp /4xw 0x7C00`, `gdbserver`
- Creating disk images: `dd if=/dev/zero of=myos.img bs=512 count=2880`; `mformat`, `mcopy` for FAT; `mkfs.ext2` for ext2 partitions

### 16.2 — GDB for Kernel Debugging

- Connecting GDB to QEMU: `target remote localhost:1234`
- Loading symbols: `symbol-file build/anton.elf`
- Setting breakpoints: `break kmain`, `break *0x7C00`
- Stepping: `stepi` (one instruction), `nexti` (step over calls), `continue`
- Examining memory: `x/10i $eip` (10 instructions at EIP), `x/4xw 0x100000` (4 hex words at 1 MB)
- Examining registers: `info registers`, `p/x $eax`
- Backtrace: `bt` — requires frame pointers (`-fno-omit-frame-pointer`)
- GDB scripts (`.gdbinit`): automating the connect+load sequence
- The `layout asm` / `layout src` TUI modes: seeing code while stepping

### 16.3 — Serial Port Logging

- The 16550 UART at I/O ports 0x3F8: adding a `serial_write` function to the kernel
- Using QEMU's `-serial stdio`: every byte written to COM1 appears in your terminal
- Why serial logging is better than VGA logging for boot debugging: it works before the VGA driver is initialized

---

## Chapter 17 — Git and Project Hygiene

_Keeping your work safe and reproducible._

### 17.1 — Git Fundamentals

- What Git does: tracks every change to every file; lets you go back in time
- Repository, working tree, staging area, commit
- Essential commands: `git init`, `git add`, `git commit -m "message"`, `git status`, `git log`, `git diff`
- Branching: `git branch phase-1`, `git checkout phase-1`, `git merge phase-1`
- Remote repositories: `git remote add origin URL`, `git push`, `git pull`
- The Anton workflow: one commit per milestone ("Phase 1: bootloader jumps to kernel in protected mode")
- What to put in `.gitignore`: `build/`, `*.o`, `*.img`, `*.iso`

### 17.2 — Project Structure

- The recommended directory layout for Anton:

  ```
  anton/
  ├── boot/          ← Stage 1 and Stage 2 bootloader (NASM)
  ├── kernel/        ← Kernel C and assembly source
  │   ├── arch/      ← Architecture-specific: gdt.c, idt.c, paging.c, context_switch.asm
  │   ├── mm/        ← Memory management: pmm.c, vmm.c, heap.c
  │   ├── drivers/   ← Drivers: vga.c, keyboard.c, pit.c, ata.c
  │   ├── fs/        ← Filesystem: vfs.c, ext2.c
  │   ├── proc/      ← Processes: process.c, scheduler.c
  │   └── main.c     ← Kernel entry point (kmain)
  ├── libc/          ← Kernel's own string.h, stdint.h implementations
  ├── user/          ← User-space programs (Phase 6+)
  ├── scripts/       ← Linker scripts, disk image creation scripts
  └── Makefile
  ```

- Why this structure: separates concerns; mirrors how real kernels (Linux, xv6) organize code

---

## Chapter 18 — The Linux Command Line

_The tools you will use every day building Anton._

### 18.1 — Essential Commands

- Navigation: `ls`, `cd`, `pwd`, `mkdir`, `rm`, `cp`, `mv`
- File inspection: `cat`, `less`, `head`, `tail`, `xxd`, `hexdump`
- Text processing: `grep`, `sed`, `awk`, `sort`, `uniq`, `wc`, `cut`
- Process management: `ps`, `kill`, `top`
- File permissions: `chmod`, `chown`
- Disk tools: `dd`, `fdisk`, `mkfs.ext2`, `mount`, `losetup`

### 18.2 — Shell Scripting Basics

- Variables, conditionals, loops in bash
- The `$?` exit status: checking if a command succeeded
- Piping and redirection: `|`, `>`, `>>`, `<`, `2>`
- Using shell scripts in the Anton build process

### 18.3 — Tools Specific to OS Development

- `hexdump -C myos.img | head -4`: inspect the first 512 bytes of your disk image
- `objdump -d build/anton.elf | grep -A5 "kmain"`: disassemble a specific function
- `nm build/anton.elf | grep " T "`: list all exported kernel symbols with addresses
- `readelf -h build/anton.elf`: inspect ELF headers
- `qemu-system-i386 -d int 2>&1 | grep "#GP"`: catch general protection faults

---

# PART II — PHASE 0: Dev Environment

## Chapter P0.1 — Concepts Specific to Phase 0

_No new concepts — this is the phase where you install and verify all the tools described in Part I._

- Verifying each tool: NASM, GCC cross-compiler, QEMU, GDB, Make, Git
- Understanding the cross-compiler's target triple
- The "Hello, myos!" skeleton: a minimal C `kmain` and a minimal linker script

## Chapter P0.2 — Design Decisions for Anton

- Directory layout initialization
- Makefile structure for Phase 0
- Why the kernel is linked at `0x100000`

## Chapter P0.3 — Implementation

- Writing `kmain.c` with a VGA text write
- Writing the linker script `anton.ld`
- Writing the Makefile
- Creating a flat binary disk image and running in QEMU

## Chapter P0.4 — Verification

- "Hello, myos!" visible in QEMU: confirmed
- `make debug` + GDB connects: confirmed
- Build is clean, no warnings

---

# PART III — PHASE 1: Bootloader

## Chapter P1.1 — Concepts Specific to Phase 1

_(All foundation already in Part I, Chapters 6 and 3)_

- The two-stage strategy in Anton's specific context
- Specific memory map after Stage 2 loads:

  ```
  0x0000 – 0x03FF  Real-mode IVT (Interrupt Vector Table)
  0x0500 – 0x07FF  BIOS data area
  0x0600 – 0x7BFF  Stage 2 lives here
  0x7C00 – 0x7DFF  Stage 1 (MBR) lives here
  0x7E00 – 0x9FFFF Free conventional memory
  0x100000+        Kernel loaded here (above 1 MB)
  ```

- A20 enabling: the three methods (BIOS INT 0x15 AX=0x2401, keyboard controller method, Fast A20 via port 0x92)
- The `times 510-($-$$) db 0` + `dw 0xAA55` MBR signature

## Chapter P1.2 — Design Decisions for Anton

- Sector layout of `myos.img`: MBR in sector 0, Stage 2 in sectors 1–3, kernel from sector 4
- Stage 2 load target: `0x0600`
- A20 method chosen: Fast A20 (port 0x92), with fallback to keyboard controller method
- Kernel load target: `0x100000`
- Kernel size limit for Stage 2 LBA load: 128 KB is reasonable for Phase 1

## Chapter P1.3 — Implementation

Complete, annotated source code for:

- `boot/stage1.asm`: MBR that loads Stage 2
- `boot/stage2.asm`: A20 enable, GDT setup, protected mode switch, kernel load, jump to `kmain`
- Updated `Makefile` to assemble both stages and produce `myos.img`
- Updated `scripts/create_image.sh`

## Chapter P1.4 — Verification

- QEMU boots from raw disk image
- QEMU `-d int` shows no unexpected exceptions during boot
- GDB breakpoint at `kmain`: hit after bootloader jumps

---

# PART IV — PHASE 2: Bare Kernel

## Chapter P2.1 — Concepts Specific to Phase 2

- The GDT from C: using a packed struct for 8-byte descriptors and a `lgdt_flush` assembly stub
- The IDT from C: same pattern; the trampoline table
- PIC remapping sequence (ICW1–ICW4)
- VGA text driver: the memory-mapped interface, cursor control via CRT registers
- `kprintf` implementation: parsing `%d`, `%x`, `%s`, `%c` format specifiers
- Integer-to-string conversion in the kernel (no `sprintf` from libc)
- The register dump struct: `struct registers` matching the stack layout after `PUSHAD`

## Chapter P2.2 — Design Decisions for Anton

- ISR naming convention: `isr0` through `isr31`, `irq0` through `irq15`
- The `registers_t` struct layout
- `kprintf` format string support scope for Phase 2

## Chapter P2.3 — Implementation

Complete, annotated source for:

- `kernel/arch/gdt.c`, `gdt.h`, `gdt_flush.asm`
- `kernel/arch/idt.c`, `idt.h`, `idt_flush.asm`
- `kernel/arch/isr.asm` (all 256 trampolines)
- `kernel/arch/isr.c` (C-level exception handler dispatcher)
- `kernel/drivers/vga.c`, `vga.h`
- `kernel/kprintf.c`, `kprintf.h`

## Chapter P2.4 — Verification

- Deliberate divide-by-zero: named exception prints with register dump, no QEMU reset
- `kprintf("0x%x = %d\n", 255, 255)` → `0xff = 255`
- Screen scrolling when text overflows

---

# PART V — PHASE 3: Memory Management

## Chapter P3.1 — Concepts Specific to Phase 3

- Parsing the E820 memory map from the bootloader: passing it to the kernel as a struct array
- The bitmap PMM: 1 bit per 4 KB frame; `pmm_alloc_frame()` finds the first 0 bit, sets it, returns the address
- Setting up initial page tables in assembly (before `kmain`) vs. in C
- The recursive page table mapping trick: mapping the page directory into itself for easy virtual access to all page tables
- Enabling paging from C: `write_cr3(pd_phys); write_cr0(read_cr0() | 0x80000000)`
- The kernel heap: implementing a free-list `kmalloc` with a block header of `{size, free, next}`
- Page fault handler: reading CR2, distinguishing a stack expansion fault from a true invalid access

## Chapter P3.2 — Design Decisions for Anton

- Kernel virtual layout: kernel text/data at `0xC0100000`, physical memory map at `0xC0000000`
- Page directory pre-allocated statically in the kernel's BSS
- Heap starts at `0xD0000000` virtual
- Minimum allocation unit: 16 bytes (alignment)

## Chapter P3.3 — Implementation

Complete, annotated source for:

- `kernel/arch/paging.c`, `paging.h`
- `kernel/mm/pmm.c`, `pmm.h`
- `kernel/mm/heap.c`, `heap.h`
- `kernel/arch/isr.c` additions (page fault handler)

## Chapter P3.4 — Verification

- `kmalloc(64)` + `kfree` + 200-iteration stress test: no corruption
- Page fault on NULL dereference prints faulting address; no triple-fault
- `pmm_free_frames()` returns the correct count after allocation

---

# PART VI — PHASE 4: Timers & Keyboard

## Chapter P4.1 — Concepts Specific to Phase 4

- PIT (Intel 8253/8254) programming: the three channels (channel 0 = IRQ0 timer, channel 2 = PC speaker)
- PIT mode 3 (square wave generator): the frequency formula `f = 1193182 / divisor`
- Setting up the PIT for 100 Hz: divisor = 11932
- The ring buffer: a circular FIFO with head and write pointers; used for the keyboard buffer
- PS/2 keyboard scancodes: Set 1 make codes (key-down) and break codes (key-up, make | 0x80)
- The scancode-to-ASCII translation table
- The shift state: tracking whether shift is held
- Special keys: backspace (scancode 0x0E), enter (0x1C), escape (0x01), arrow keys (multi-byte sequences starting with 0xE0)

## Chapter P4.2 — Design Decisions for Anton

- Timer tick frequency: 100 Hz (10 ms per tick)
- Global `uint32_t ticks` counter (used in Phase 5 for preemption)
- Keyboard buffer size: 256 bytes

## Chapter P4.3 — Implementation

Complete, annotated source for:

- `kernel/drivers/pit.c`, `pit.h`
- `kernel/drivers/keyboard.c`, `keyboard.h`
- `kernel/drivers/keyboard_map.c` (scancode table)

## Chapter P4.4 — Verification

- Tick counter visible on screen, incrementing at 1 Hz (100 ticks displayed per second, rolled up to "seconds: N")
- All keys echo correctly, including shift for uppercase and symbols
- `sleep(1000)` blocks for approximately 1 second

---

# PART VII — PHASE 5: Multitasking

## Chapter P5.1 — Concepts Specific to Phase 5

- The `process_t` structure in Anton
- The context switch stack layout at switch time: everything `PUSHAD` leaves, plus EIP (implicitly via `CALL`)
- Why `switch_context(process_t *old, process_t *new)` must be written in assembly
- The first process startup: a new process's kernel stack must be set up to look as if it was interrupted, so the context switcher can `IRET` into it
- Saving and restoring the page directory in `process_t`: switching CR3 on context switch
- The scheduler's run queue: a circular linked list of `READY` processes
- Invoking the scheduler from the timer ISR: the timer fires → ISR increments ticks → calls `schedule()` → `schedule()` picks next process → `switch_context()`
- Zombie processes: a process that has exited but whose `process_t` hasn't been freed yet (waiting for parent to call `wait()`)

## Chapter P5.2 — Design Decisions for Anton

- `process_t` fields: pid, state, esp (saved stack pointer), page_dir (CR3 value), kernel_stack (top address), next (linked list)
- Idle process: a special process that runs when the run queue is empty (just `HLT` in a loop)
- PID allocation: simple monotonic counter

## Chapter P5.3 — Implementation

Complete, annotated source for:

- `kernel/proc/process.c`, `process.h`
- `kernel/arch/context_switch.asm`
- `kernel/proc/scheduler.c`, `scheduler.h`

## Chapter P5.4 — Verification

- Two tasks printing their names to VGA in alternating ticks: interleaved output confirms multitasking
- Killing one task: the other continues unaffected
- A `ps` command (kernel debug function) lists PIDs and states

---

# PART VIII — PHASE 6: User Mode & Syscalls

## Chapter P6.1 — Concepts Specific to Phase 6

- The TSS (Task State Segment): a special GDT descriptor that tells the CPU where to find the kernel stack when transitioning from ring 3 to ring 0 on interrupt
  - TSS fields: SS0 (kernel stack segment = 0x10), ESP0 (kernel stack pointer for the current process), updated on every context switch
- Ring 3 page mapping: user-mode pages must have the User bit (bit 2) set in their page table entries
- Setting up a user-mode stack: allocating a physical page, mapping it at a fixed virtual address (e.g., `0xBFFFF000`), setting User bit
- Jumping to ring 3: using a fake IRET — push SS3, ESP3, EFLAGS, CS3, EIP onto the kernel stack, then `IRET`
- The `int 0x80` syscall interface: the IDT entry for vector 0x80 has DPL=3 (so user code can invoke it)
- The syscall dispatcher in C: switch on EAX (syscall number); extract arguments from EBX, ECX, EDX, ESI, EDI
- Implementing `sys_write`: write string to VGA (or eventually serial port)
- Implementing `sys_exit`: mark the process zombie, schedule next

## Chapter P6.2 — Design Decisions for Anton

- Syscall numbers for Phase 6: `SYS_WRITE=1`, `SYS_READ=2`, `SYS_EXIT=60`
- User stack virtual address: `0xBFFFF000`
- User code virtual address: `0x00400000` (matching standard ELF load address)
- The mini user-space program: hardcoded in the kernel image as a raw binary blob for Phase 6 (real ELF loading comes in Phase 8)

## Chapter P6.3 — Implementation

Complete, annotated source for:

- `kernel/arch/tss.c`, `tss.h`
- `kernel/proc/syscall.c`, `syscall.h`
- `kernel/arch/syscall_entry.asm` (IDT 0x80 trampoline)
- A test user-space program in `user/test_ring3.c` cross-compiled to flat binary

## Chapter P6.4 — Verification

- User program prints "Hello from ring 3!" via `write` syscall
- User program calls `exit(0)`: kernel cleans up gracefully, no crash
- Privileged instruction from ring 3 causes #GP, kernel kills the process, other processes continue

---

_(Chapters for Phases 7–13 follow the same P[N].1–P[N].4 structure, each with a brief concept supplement chapter, a design chapter, complete annotated implementation, and a verification chapter. The prerequisite foundations are fully laid in Part I — these phase chapters reference back by chapter number and build only on what has already been taught.)_

---

## Summary: What Each Phase Chapter Teaches vs. What Part I Already Taught

| Phase    | Concept Supplement in Phase Chapter                              | Foundation Already in Part I                                                                    |
| -------- | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Phase 0  | None — pure setup                                                | Cross-compilation (Ch 5.5), Make (Ch 5.6), GDB (Ch 16.2), QEMU (Ch 16.1)                        |
| Phase 1  | Memory layout after Stage 2, A20 specifics                       | Boot sequence (Ch 6), BIOS services (Ch 3.5), x86 assembly (Ch 3)                               |
| Phase 2  | GDT from C structs, ISR trampolines, kprintf internals           | GDT concept (Ch 6.5), IDT concept (Ch 2.7), PIC (Ch 8.2), x86 exceptions (Ch 2.7)               |
| Phase 3  | E820 parsing, recursive PD trick, heap free-list                 | Paging theory (Ch 7.3), PMM concept (Ch 7.1), heap concept (Ch 7.4)                             |
| Phase 4  | PIT frequency formula, keyboard scancodes                        | I/O ports (Ch 8.5), Interrupts (Ch 8.3), Ring buffer data structure (Ch 9.1 briefly)            |
| Phase 5  | PCB struct layout, switch stack setup, idle process              | Context switching theory (Ch 9.2), Scheduling theory (Ch 9.3), Concurrency (Ch 9.4)             |
| Phase 6  | TSS mechanics, IDT DPL=3 trick, fake IRET to ring 3              | Rings (Ch 2.6), Syscalls (intro in Ch 2.6), User/kernel separation (Ch 9.1)                     |
| Phase 7  | ATA PIO command sequence, ext2 inode lookup code                 | ATA/disk theory (Ch 10.1), ext2 on-disk layout (Ch 10.3), VFS (Ch 10.4)                         |
| Phase 8  | PT_LOAD mapping loop, `fork` COW pages, shell parsing            | ELF format (Ch 11), `fork`/`exec` semantics (Ch 9.1), Pipes as kernel objects                   |
| Phase 9  | VBE mode switching from Stage 2, window manager event loop       | VBE framebuffer (Ch 13.2), Bitmap fonts (Ch 13.3), WM concepts (Ch 13.4)                        |
| Phase 10 | e1000 register map, TCP state machine implementation             | Full networking stack theory (Ch 12), PCI enumeration (Ch 12.2)                                 |
| Phase 11 | Entering long mode sequence, PML4 setup, LSTAR MSR               | 64-bit architecture (Ch 14), Long mode (Ch 14.3), `syscall`/`sysret` (Ch 14.4)                  |
| Phase 12 | Terminal escape code parsing, editor data structure (gap buffer) | VBE/font rendering (Phase 9 taught), VFS `open`/`write` (Phase 7 taught)                        |
| Phase 13 | newlib syscall stubs, GCC configure flags, `sbrk` for heap       | libc/newlib theory (Ch 15), Self-hosting concept (Ch 5), `mmap`/`fork` (taught in prior phases) |

---

## The One Rule This Book Never Breaks

Every implementation chapter in Parts II–XV must be able to point to a chapter in Part I for every concept it uses. If a reader hits an unknown term in Phase 3's implementation chapter, they can look it up by name in Part I and find a complete explanation written before they ever saw the first line of code. This book is complete. You do not need the internet to finish building Anton. You need this book, a compiler, and a terminal.
