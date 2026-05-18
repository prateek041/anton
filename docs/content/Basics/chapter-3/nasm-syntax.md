---
title: "NASM Syntax"
order: 23
---

# NASM Syntax

There are two major x86 assemblers in the open-source world: **NASM** (Netwide
Assembler) and **GAS** (GNU Assembler). They both produce the same machine code,
but they use different syntax to get there, and the differences are jarring
enough that code written for one cannot be fed to the other without translation.

Anton uses NASM for the bootloader and all standalone assembly files. GAS
appears implicitly when you use inline assembly inside C code (GCC's inline
assembler uses AT&T/GAS syntax). So you will encounter both, but NASM is the one
you write by hand.

## NASM vs. GAS: Intel Syntax vs. AT&T Syntax

The most visible difference is the operand order and notation.

**NASM (Intel syntax):**

```text
mov eax, 5            ; destination first, then source
add eax, ebx          ; eax = eax + ebx
mov [0x1000], ecx     ; write ecx to memory address 0x1000
```

**GAS (AT&T syntax):**

```text
movl $5, %eax         /* source first, then destination */
addl %ebx, %eax       /* eax = eax + ebx */
movl %ecx, 0x1000     /* write ecx to memory address 0x1000 */
```

The differences:

- **Operand order** is reversed. Intel syntax is `destination, source`. AT&T is
  `source, destination`.
- **Register names** in AT&T are prefixed with `%`: `%eax`, `%ebx`.
- **Immediate values** in AT&T are prefixed with `$`: `$5`, `$0xFF`.
- **Memory references** differ in notation. Intel uses
  `[base + index*scale + disp]`. AT&T uses `disp(base, index, scale)`.
- **Instruction suffixes** in AT&T encode the operand size: `movl`
  (long/32-bit), `movw` (word/16-bit), `movb` (byte). NASM infers the size from
  the operands or uses explicit size keywords like `dword`, `word`, `byte`.

Anton uses Intel syntax (NASM) for standalone assembly because it matches the
Intel and AMD processor manuals. When you look up an instruction in the Intel
Software Developer's Manual, the syntax is `MOV EAX, imm32`, not
`movl $imm32, %eax`. Using the same syntax as the reference documentation
eliminates a layer of mental translation.

![Intel vs AT&T syntax comparison](../images/ch3/intel-vs-att.svg)

## Assembler Directives

Directives are instructions to the assembler, not to the CPU. They do not
produce machine code directly. Instead, they tell NASM how to interpret what
follows.

### `BITS` : Setting the Processor Mode

```text
BITS 16       ; assemble the following code as 16-bit instructions
BITS 32       ; assemble the following code as 32-bit instructions
```

This is critical for the bootloader. The CPU starts in 16-bit real mode, so the
first part of the bootloader is assembled with `BITS 16`. After we switch to
protected mode, we change to `BITS 32`. The same opcode byte can mean different
things in 16-bit and 32-bit mode, so getting this wrong produces instructions
that do something completely different from what you intended.

### `ORG` : Setting the Origin Address

```text
ORG 0x7C00
```

This tells NASM: "assume this code will be loaded at address `0x7C00` in
memory." It does not load the code there. It just makes all label addresses
relative to that starting point.

Why `0x7C00`? Because the BIOS loads the boot sector (the first 512 bytes of the
disk) to address `0x7C00` in memory. If your bootloader uses a label to
reference a string or a variable, NASM needs to know the base address so it can
compute the correct offset.

### `SECTION` : Organizing Code and Data

```text
SECTION .text     ; executable code goes here
SECTION .data     ; initialized data (strings, constants)
SECTION .bss      ; uninitialized data (reserved space)
```

Sections group your code and data for the linker. When you write a flat binary
(like the bootloader), sections are less important because everything ends up in
one contiguous blob. But when you write object files that link with C code,
sections tell the linker where to place code versus data versus zero-initialized
storage.

### `GLOBAL` and `EXTERN` : Linker Symbols

```text
GLOBAL _start       ; export this symbol so the linker can see it
EXTERN kernel_main  ; import this symbol from another object file
```

`GLOBAL` makes a label visible outside the current file. Without it, the label
is local to the assembly file and the linker cannot find it. If your C code
calls `asm_add()`, then the assembly file defining `asm_add` must have
`GLOBAL asm_add`.

`EXTERN` declares a symbol that is defined elsewhere. When the assembly code
calls `kernel_main`, it tells NASM "this symbol exists, but it is defined in a C
file (or another assembly file). The linker will fill in the address."

## Data Definitions

NASM provides pseudo-instructions for embedding raw data into the output.

### Defining Initialized Data

```text
db 0x55               ; define a single byte with value 0x55
db 'H', 'e', 'l'     ; define three bytes (ASCII characters)
db "Hello", 0         ; define a null-terminated string (6 bytes)
dw 0x1234             ; define a 16-bit word
dd 0xDEADBEEF         ; define a 32-bit doubleword
dq 0x123456789ABCDEF0 ; define a 64-bit quadword
```

The `d` stands for "define." `db` is define byte, `dw` is define word (2 bytes),
`dd` is define doubleword (4 bytes), `dq` is define quadword (8 bytes).

You can combine these with labels to create named data:

```text
boot_msg: db "Loading kernel...", 0
magic:    dd 0x1BADB002
```

### Repeating Data

```text
times 510-($-$$) db 0   ; fill with zeros until we reach byte 510
```

The `times` directive repeats the following data definition a computed number of
times. This example is the classic bootloader padding: fill the remaining space
in the 512-byte boot sector with zeros, leaving room for the two-byte boot
signature at the end.

### Reserving Uninitialized Space

```text
SECTION .bss
buffer: resb 4096     ; reserve 4096 bytes (uninitialized)
count:  resd 1         ; reserve 1 doubleword (4 bytes)
```

`resb` reserves bytes, `resw` reserves words, `resd` reserves doublewords. These
do not emit any bytes into the output. They just tell the linker to allocate the
specified amount of space in the BSS segment, which the OS (or our startup code)
will zero-fill at load time.

## Labels

Labels are names that represent memory addresses. When you write a label, NASM
records the current output position and associates it with that name. Later
references to the label are replaced with the address.

### Global Labels

```text
_start:
    mov eax, 5
    jmp _start        ; jumps back to the mov instruction
```

A global label is any name followed by a colon. It is visible throughout the
file (and to the linker, if you also use `GLOBAL`).

### Local Labels

```text
print_string:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret
```

A local label starts with a dot (`.loop`, `.done`). It is scoped to the most
recent global label. This means you can reuse `.loop` and `.done` in different
functions without conflict. Inside `print_string`, `.loop` refers to
`print_string.loop`. Inside a different function, `.loop` would be a different
address.

Local labels are essential for keeping assembly code organized. Without them,
you would need globally unique names for every branch target, which gets
unwieldy fast.

### Label Arithmetic

Labels are just numbers (addresses), so you can do math with them:

```text
msg: db "Hello, world!", 0
msg_len: equ $ - msg
```

The `$` symbol means "the current assembly position." So `$ - msg` computes the
number of bytes between the current position and the start of `msg`, which is
the length of the string (including the null terminator). The `equ` directive
assigns this value to the name `msg_len` as a compile-time constant.

## Constants and Expressions

### `equ` : Named Constants

```text
KERNEL_OFFSET equ 0x1000
PAGE_SIZE     equ 4096
VGA_BUFFER    equ 0xB8000
```

`equ` defines a compile-time constant. It does not allocate any memory. Wherever
`KERNEL_OFFSET` appears in the code, NASM substitutes the value `0x1000`. Think
of it like `#define` in C, but evaluated by the assembler.

### Special Symbols: `$` and `$$`

- `$` is the address of the current line being assembled.
- `$$` is the address of the beginning of the current section.
- `$ - $$` gives you how many bytes have been emitted in the current section so
  far.

The most common use is the boot sector padding:

```text
times 510-($-$$) db 0    ; pad to 510 bytes
dw 0xAA55                ; boot signature at bytes 510-511
```

This ensures the boot sector is exactly 512 bytes, with the magic number
`0xAA55` at the end. The BIOS checks for this signature to determine whether a
disk is bootable.

![Boot sector 512-byte layout](../images/ch3/boot-sector-layout.svg)

## Macros

### Simple Text Substitution

```text
%define SCREEN_WIDTH 80
%define SCREEN_HEIGHT 25
```

`%define` works like C's `#define`. It performs text substitution before
assembly. Every occurrence of `SCREEN_WIDTH` is replaced with `80`.

### Multi-Line Macros

```text
%macro ISR_NOERRCODE 1
    global isr%1
    isr%1:
        push dword 0      ; push a dummy error code
        push dword %1      ; push the interrupt number
        jmp isr_common
%endmacro
```

This defines a macro called `ISR_NOERRCODE` that takes one parameter (`%1`).
When you write `ISR_NOERRCODE 0`, it expands to an interrupt service routine
stub for vector 0. The `%1` is replaced with the argument.

We will use macros like this extensively when building the IDT in Phase 4.
Instead of writing 32 nearly identical interrupt stubs by hand, we define two
macros (one for exceptions with error codes, one without) and invoke them 32
times.

### Including Files

```text
%include "gdt.inc"
%include "constants.inc"
```

`%include` inserts the contents of another file at the current position, just
like `#include` in C. We will use this to share constant definitions and macro
definitions across multiple assembly files.

## Comments

NASM uses the semicolon for comments:

```text
mov eax, 0x1000   ; load the kernel load address into eax
```

Everything after the semicolon on that line is ignored by the assembler. Use
comments generously in assembly. Assembly code is inherently less readable than
C, and a comment explaining the intent saves time when you revisit the code
later.

## Memory Operands and Size Specifiers

When the assembler cannot infer the operand size from context, you must specify
it explicitly:

```text
mov byte [0x1000], 0xFF     ; write a single byte
mov word [0x1000], 0xFFFF   ; write two bytes
mov dword [0x1000], 0xFFFF  ; write four bytes
```

Without the size keyword, NASM does not know whether `mov [0x1000], 0xFF` should
write one byte, two bytes, or four bytes. When one operand is a register, the
size is obvious (`mov [0x1000], eax` is clearly 32-bit). But when both operands
could be ambiguous, you need the `byte`, `word`, or `dword` prefix.

## Putting It All Together

Here is a complete, annotated NASM source file that demonstrates every concept
from this section. This is not a runnable program yet (we will cover the
toolchain in Chapter 5), but it is syntactically correct NASM:

```text
BITS 16                        ; 16-bit real mode
ORG 0x7C00                     ; BIOS loads us here

SECTION .text

start:
    xor ax, ax                 ; zero out AX
    mov ds, ax                 ; set data segment to 0
    mov es, ax                 ; set extra segment to 0
    mov ss, ax                 ; set stack segment to 0
    mov sp, 0x7C00             ; stack grows downward from 0x7C00

    mov si, welcome_msg        ; point SI to our string
    call print_string          ; call the print function

    cli                        ; disable interrupts
    hlt                        ; halt the CPU

print_string:
    mov ah, 0x0E               ; BIOS teletype function
.loop:
    lodsb                      ; load byte at [SI] into AL, increment SI
    test al, al                ; is it zero (null terminator)?
    jz .done                   ; if yes, we are done
    int 0x10                   ; call BIOS video service
    jmp .loop                  ; next character
.done:
    ret                        ; return to caller

SECTION .data

welcome_msg: db "Hello from the bootloader!", 0

BOOT_DRIVE: db 0               ; saved boot drive number

SECTION .text

times 510-($-$$) db 0          ; pad to 510 bytes
dw 0xAA55                      ; boot signature
```

Every element from this section is present: `BITS`, `ORG`, `SECTION`, labels
(global and local), data definitions (`db`), `times` padding, `equ`-style
arithmetic (`$-$$`), a function with local labels, and comments. This is the
skeleton that every NASM bootloader is built from.

In the next section, we will write several complete assembly programs that put
these syntax elements to work, practicing the patterns from Chapter 2 with real
code.
