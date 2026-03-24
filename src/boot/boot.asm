; boot.asm — Entry point. Called by QEMU's -kernel flag (multiboot).
; Sets up a stack and jumps to kernel_main in C.

MBALIGN  equ 1 << 0
MEMINFO  equ 1 << 1
FLAGS    equ MBALIGN | MEMINFO
MAGIC    equ 0x1BADB002
CHECKSUM equ -(MAGIC + FLAGS)

section .multiboot
align 4
    dd MAGIC
    dd FLAGS
    dd CHECKSUM

section .bss
align 16
stack_bottom:
    resb 16384          ; 16 KB stack
stack_top:

section .text
global _start
extern kernel_main

_start:
    mov esp, stack_top  ; Point the stack pointer to our stack
    call kernel_main    ; Jump into C land
    cli                 ; If kernel_main returns, disable interrupts...
    hlt                 ; ...and halt the CPU forever
