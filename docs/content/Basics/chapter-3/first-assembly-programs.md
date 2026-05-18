---
title: "Writing Your First Assembly Programs"
order: 24
---

# Writing Your First Assembly Programs

You have the vocabulary (Chapter 2's instruction set) and the grammar (section
3.2's NASM syntax). Now it is time to write complete programs. Each example in
this section is a fully correct NASM source file with a line-by-line
explanation. We are not running these yet. The toolchain (assembler, linker,
emulator) comes in Chapter 5. Right now, the goal is to practice reading and
writing assembly, building the muscle memory for the patterns that will appear
throughout Anton.

## Hello World: Printing a String in Real Mode

This is the bare-metal equivalent of "Hello World." The CPU is in 16-bit real
mode, and we use the BIOS teletype service (`INT 0x10`, function `0x0E`) to
print characters one at a time.

```text
BITS 16
ORG 0x7C00

start:
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7C00

    mov si, hello_msg
    call print_string

    cli
    hlt

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

hello_msg: db "Hello, world!", 0

times 510-($-$$) db 0
dw 0xAA55
```

Let's walk through it.

`BITS 16` tells NASM to generate 16-bit machine code. `ORG 0x7C00` sets the base
address so labels resolve correctly (the BIOS loads the boot sector at
`0x7C00`).

The first four instructions set up the environment. `xor ax, ax` zeros `AX` (it
is shorter and faster than `mov ax, 0`). We then copy that zero into `DS` (data
segment) and `SS` (stack segment) so that memory and stack accesses use segment
base 0. `mov sp, 0x7C00` places the stack pointer just below our code, growing
downward.

`mov si, hello_msg` loads the address of the string into `SI`. Then
`call print_string` pushes the return address and jumps to the function.

Inside `print_string`, `mov ah, 0x0E` sets up the BIOS function number (teletype
output). `LODSB` loads the byte at `[DS:SI]` into `AL` and increments `SI`.
`test al, al` checks if the byte is zero (the null terminator). If it is,
`jz .done` jumps past the loop. Otherwise, `int 0x10` calls the BIOS to print
the character in `AL`, and `jmp .loop` repeats.

After the string is printed, `cli` disables interrupts and `hlt` halts the CPU.
The program is done.

The last two lines pad the boot sector to exactly 512 bytes and place the boot
signature `0xAA55` at offset 510. Without this signature, the BIOS will not
recognize the disk as bootable.

This is the simplest possible bare-metal program, and it contains nearly every
pattern you will see in the Anton bootloader: environment setup, a function
call, a BIOS interrupt, and the boot sector structure.

## A Loop: Counting Down

Loops in assembly follow a simple pattern: initialize a counter, do work,
decrement the counter, and branch back if it is not zero. Here is a 32-bit
example that sums the numbers from 1 to 10:

```text
BITS 32

sum_1_to_10:
    xor eax, eax          ; eax = 0 (accumulator for the sum)
    mov ecx, 10           ; ecx = 10 (loop counter)
.loop:
    add eax, ecx          ; sum += counter
    dec ecx               ; counter--
    jnz .loop             ; if counter != 0, loop again
    ret                   ; eax now holds 55
```

This is equivalent to the C code:

```c
int sum = 0;
for (int i = 10; i > 0; i--) {
    sum += i;
}
```

Notice we count down instead of up. The `DEC` instruction sets the zero flag
(`ZF`) when the result reaches zero, and `JNZ` (jump if not zero) checks that
flag. Counting down means we do not need a separate `CMP` instruction. The
decrement and the branch condition are combined naturally.

You might wonder about the `LOOP` instruction, which was designed exactly for
this pattern. `LOOP` decrements `ECX` and jumps if it is not zero, all in one
instruction. The problem is that `LOOP` is slow on modern CPUs. It is microcoded
rather than directly executed, and it can be several times slower than the
manual `DEC`/`JNZ` pair. Every real-world assembler tutorial will tell you the
same thing: do not use `LOOP`. Use `DEC` and `JNZ`.

## A Function Call: Adding Two Numbers

This example demonstrates the complete function call protocol from Chapter 2:
the caller pushes arguments, the callee sets up its stack frame, does work,
tears it down, and returns.

```text
BITS 32

caller:
    push dword 7          ; second argument (pushed first: right-to-left)
    push dword 3          ; first argument (pushed second)
    call add_numbers      ; call the function
    add esp, 8            ; clean up 2 arguments (2 * 4 bytes)
    ret                   ; eax now holds 10

add_numbers:
    push ebp              ; save caller's frame pointer
    mov ebp, esp          ; set up our frame pointer
    ; no SUB ESP needed (no local variables)

    mov eax, [ebp+8]      ; first argument (3)
    add eax, [ebp+12]     ; add second argument (7)

    mov esp, ebp          ; tear down frame (a no-op here, but good habit)
    pop ebp               ; restore caller's frame pointer
    ret                   ; return; result is in eax
```

Let's trace the stack. Before the call, suppose `ESP` is at `0x1000`:

1. `push dword 7`: `ESP` becomes `0x0FFC`, value `7` is at `[0x0FFC]`.
2. `push dword 3`: `ESP` becomes `0x0FF8`, value `3` is at `[0x0FF8]`.
3. `call add_numbers`: `ESP` becomes `0x0FF4`, the return address is at
   `[0x0FF4]`.

Inside `add_numbers`:

1. `push ebp`: `ESP` becomes `0x0FF0`, the old `EBP` is at `[0x0FF0]`.
2. `mov ebp, esp`: `EBP` is now `0x0FF0`.

So `[EBP+4]` is the return address, `[EBP+8]` is the first argument (3), and
`[EBP+12]` is the second argument (7). This matches the stack frame layout from
Chapter 2 exactly.

After the function returns, the caller executes `add esp, 8` to remove the two
arguments from the stack. This is the cdecl convention: the caller cleans up.

![Stack during add_numbers(3, 7) step by
step](../images/ch3/function-call-stack-trace.svg)

The equivalent C code is simply:

```c
int add_numbers(int a, int b) {
    return a + b;
}

int result = add_numbers(3, 7);
```

The compiler generates essentially the same sequence. Writing it by hand makes
the calling convention concrete.

## Calling Between C and Assembly

In Anton, C code calls assembly functions and assembly code calls C functions.
The bridge between them is the calling convention (cdecl) and the linker.

### An Assembly Function Called from C

Here is an assembly file that defines a function `asm_add` callable from C:

```text
; file: asm_add.asm
BITS 32
SECTION .text

GLOBAL asm_add              ; export the symbol

asm_add:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]        ; first argument
    add eax, [ebp+12]       ; second argument
    pop ebp
    ret
```

And the C code that calls it:

```c
// file: main.c
extern int asm_add(int a, int b);

int main(void) {
    int result = asm_add(10, 20);
    return result;
}
```

The `GLOBAL asm_add` directive makes the symbol visible to the linker. The
`extern` declaration in C tells the compiler "this function exists somewhere
else, and the linker will find it." The calling convention is identical whether
the callee is written in C or assembly. The caller pushes arguments
right-to-left, the callee saves `EBP`, does its work, and returns the result in
`EAX`.

### Calling a C Function from Assembly

Going the other direction, here is assembly code that calls a C function:

```text
; file: caller.asm
BITS 32
SECTION .text

EXTERN c_helper             ; declare the C function

GLOBAL asm_entry

asm_entry:
    push dword 42           ; argument to c_helper
    call c_helper            ; call the C function
    add esp, 4              ; clean up one argument
    ret
```

And the C function:

```c
// file: helper.c
void c_helper(int value) {
    // do something with value
}
```

The `EXTERN c_helper` directive tells NASM that `c_helper` is defined elsewhere.
The linker resolves the address when combining the object files. The assembly
code follows cdecl: push the argument, call, clean up.

This pattern appears constantly in Anton. The bootloader calls `kernel_main` (a
C function) after setting up protected mode. Interrupt stubs (written in
assembly) call C handler functions. The context switch routine (assembly) may
call scheduler functions (C).

![C and Assembly interop via GLOBAL/EXTERN](../images/ch3/c-asm-interop.svg)

## Memory Access Patterns

Assembly gives you direct control over memory reads and writes. Here are the
patterns you will use most:

### Direct Address Access

```text
mov eax, [0xB8000]        ; read 4 bytes from the VGA text buffer
mov byte [0xB8000], 'A'   ; write the character 'A' to the first cell
mov byte [0xB8001], 0x07  ; write the attribute byte (white on black)
```

This is how the bootloader and early kernel write text to the screen. The VGA
text buffer starts at physical address `0xB8000`. Each character cell is two
bytes: the ASCII character and an attribute byte.

### Register as Pointer

```text
mov edi, 0xB8000          ; EDI points to VGA buffer
mov byte [edi], 'H'       ; write 'H'
mov byte [edi+1], 0x07    ; white on black
mov byte [edi+2], 'i'     ; write 'i'
mov byte [edi+3], 0x07    ; white on black
```

Instead of hardcoding addresses, you load the base address into a register and
use offsets. This is equivalent to pointer arithmetic in C:
`char *vga = (char *)0xB8000; vga[0] = 'H'; vga[1] = 0x07;`

### Array Indexing

```text
mov ebx, array_base       ; EBX = base address of an int array
mov ecx, 5                ; ECX = index
mov eax, [ebx + ecx*4]   ; EAX = array[5] (each int is 4 bytes)
```

The `*4` scale factor accounts for the element size. This is the
`base + index * scale` addressing mode from Chapter 2. It maps directly to C's
`array[index]` syntax.

### Block Copy with String Instructions

```text
mov esi, source           ; source address
mov edi, dest             ; destination address
mov ecx, 256              ; number of doublewords to copy (1024 bytes)
cld                       ; clear direction flag (increment pointers)
rep movsd                 ; copy ECX doublewords from [ESI] to [EDI]
```

`REP MOVSD` copies `ECX` doublewords (4 bytes each) from the address in `ESI` to
the address in `EDI`, incrementing both pointers after each copy. This is the
assembly equivalent of `memcpy(dest, source, 1024)`. The `CLD` instruction
clears the direction flag so that `ESI` and `EDI` increment (move forward). If
the direction flag were set, they would decrement.

## Conditional Logic: If-Else in Assembly

Every `if` statement in C compiles down to a compare-and-branch sequence. Here
is a function that classifies a number as positive, negative, or zero:

```text
BITS 32

classify:
    push ebp
    mov ebp, esp

    mov eax, [ebp+8]       ; load the argument

    test eax, eax           ; compare eax with zero
    jz .is_zero             ; if zero, jump
    js .is_negative         ; if sign flag set (negative), jump

.is_positive:
    mov eax, 1              ; return 1 for positive
    jmp .done

.is_negative:
    mov eax, -1             ; return -1 for negative
    jmp .done

.is_zero:
    xor eax, eax            ; return 0 for zero

.done:
    pop ebp
    ret
```

This corresponds to:

```c
int classify(int n) {
    if (n == 0) return 0;
    if (n < 0) return -1;
    return 1;
}
```

`TEST EAX, EAX` ANDs `EAX` with itself (which does not change `EAX`) and sets
the flags. If the value is zero, `ZF` is set and `JZ` takes the branch. If the
value is negative (sign bit set), `SF` is set and `JS` takes the branch.
Otherwise, execution falls through to the positive case.

Notice the `jmp .done` after each case. Without it, execution would fall through
to the next case. Assembly has no block structure. There is no closing brace
that ends an `if` body. You must explicitly jump past the other cases.
Forgetting a `jmp` is a common assembly bug.

![C conditionals mapped to assembly
instructions](../images/ch3/c-asm-conditional-mapping.svg)

## Patterns You Will See Everywhere

A few idioms show up so frequently in x86 assembly that they are worth
memorizing:

**Zeroing a register:** `xor eax, eax` instead of `mov eax, 0`. Shorter
encoding, same effect, and modern CPUs recognize it as a dependency-breaking
idiom.

**Testing for zero:** `test eax, eax` followed by `jz label`. Faster than
`cmp eax, 0` because `TEST` is shorter.

**Saving and restoring registers:** Functions that use `EBX`, `ESI`, `EDI`, or
`EBP` must save them at the start and restore them at the end (callee-saved in
cdecl). The pattern is always `push` at the top, `pop` at the bottom, in reverse
order:

```text
my_function:
    push ebx
    push esi
    push edi
    ; ... use ebx, esi, edi freely ...
    pop edi
    pop esi
    pop ebx
    ret
```

**The infinite loop:** `jmp $` jumps to the current address, creating a tight
infinite loop. Used when you want to halt without `HLT` (because `HLT` can be
woken by interrupts).

**No-op sled:** `nop` does nothing but advance `EIP` by one byte. Sometimes used
for alignment or as placeholders.

These patterns will appear throughout the bootloader, the interrupt stubs, and
the kernel's assembly helpers. Recognizing them on sight saves you from having
to decode them from first principles every time.

In the next section, we will look at how C and assembly coexist in the same
project through GCC's inline assembly facility.
