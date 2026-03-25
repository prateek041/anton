# myos — Master Build Plan

## Project Identity

**Name:** `myos` (replace with your chosen name everywhere)
**Tagline:** A from-scratch, self-hosting operating system built in C and x86 assembly.

***

## The OS Spec

| Attribute | Decision |
|---|---|
| Language | C + inline x86 assembly |
| Architecture | x86 32-bit → 64-bit transition (Phase 11) |
| Boot | Custom BIOS 2-stage bootloader (no GRUB) |
| Kernel design | Monolithic with clean module boundaries |
| Memory | Physical memory manager, paging, kernel heap |
| Multitasking | Preemptive, round-robin → priority-based |
| User/Kernel separation | Ring 0 (kernel) + Ring 3 (user), syscall interface |
| Filesystem | ext2 (read + write) |
| Shell | Full-featured: pipes, redirection, history, tab-completion, job control, ANSI color |
| Networking | e1000 → ARP → IPv4 → UDP → TCP → DHCP → DNS → HTTP |
| Graphics | VBE framebuffer, bitmap fonts, PS/2 mouse, basic window manager |
| Input | PS/2 keyboard + PS/2 mouse |
| Dev environment | Linux (primary) + macOS Apple Silicon (travel) — same toolchain, same repo |

***

## Development Setup (Both Machines)

**Linux (Omarchy) — Primary:**
- Build `i686-elf-gcc` cross-compiler from source
- QEMU runs with KVM acceleration (fast)
- NASM, GDB, `mtools`, `xorriso` via package manager

**macOS (M3 Max) — Travel:**
- `brew install i686-elf-gcc nasm qemu gdb` — same toolchain name, works on Apple Silicon
- QEMU emulates x86 (no KVM on macOS/ARM) — slower than Linux, but negligible for a tiny hobby kernel
- Same Git repo, same Makefile, same commands: `make run`, `make debug`

**Workflow:** Git + GitHub. Commit and push on one machine, pull on the other. Never sync binaries — only source. The build always produces the output from scratch.

***

## Phases at a Glance

| # | Phase Name | What Gets Built | Proof It Works |
|---|---|---|---|
| 0 | Dev Environment | Toolchain, editor, QEMU, GDB | "Hello, myos!" on screen inside QEMU |
| 1 | Bootloader | 2-stage custom BIOS bootloader | Bootloader loads and jumps to kernel from a raw disk image |
| 2 | Bare Kernel | GDT, IDT, exception handling, VGA text driver | CPU exceptions print to screen cleanly; no triple-fault resets |
| 3 | Memory Management | Physical allocator, paging, kernel heap | `kmalloc`/`kfree` work; deliberate page fault prints fault address |
| 4 | Timers & Keyboard | PIT timer, PS/2 keyboard driver | Timer ticks per second visible; every keypress echoes to screen |
| 5 | Multitasking | Processes, context switching, preemptive scheduler | Two independent tasks run concurrently without corrupting each other |
| 6 | User Mode & Syscalls | Ring 3 separation, syscall table, mini libc | A user-space program runs and prints via `write()` syscall |
| 7 | Storage | ATA driver, VFS layer, ext2 filesystem | `ls /` reads a real ext2 disk image; `cat file.txt` prints content |
| 8 | ELF Loader & Shell | ELF executable loader, `fork`/`exec`, full shell | Shell runs programs, pipes work, redirects work, history works |
| 9 | Graphics & WM | VBE framebuffer, font rendering, mouse, window manager | Graphical desktop with a terminal window you can drag with a mouse |
| 10 | Networking | PCI, e1000 NIC, full TCP/IP stack, HTTP client | `ping` replies; OS fetches a webpage from the internet |
| 11 | 64-bit Transition | x86_64 long mode, 4-level paging, new syscall ABI | Entire OS rebuilt and running in 64-bit mode |
| 12 | Text Editor | Built-in editor written from scratch | Open a file, edit it, save it — entirely inside the OS |
| 13 | Self-Hosting Compiler | Ported newlib + GCC running natively inside the OS | Write C code in the editor, compile it, run the binary — all inside myos |

***

## Phase 0 — Dev Environment

### What Gets Built
A complete, reproducible development environment — the foundation every other phase depends on. This includes the cross-compiler (a GCC that targets bare-metal x86, not your host Linux), assembler, emulator, debugger, build system, and a skeleton project directory.

### Why This Phase Exists
You cannot use your system's native GCC to compile kernel code — it silently links against Linux headers and startup files, producing a binary that will crash in mysterious, untraceable ways. A proper cross-compiler eliminates an entire category of hard-to-debug problems before they happen. The emulator (QEMU) and debugger (GDB) are your eyes inside the machine — you will use them in every single subsequent phase.

### What "Done" Looks Like
- Running `make run` from an empty project opens QEMU and displays **"Hello, myos!"** in white text on a black screen
- Running `make debug` opens QEMU paused, GDB connects to it, and you can step through your kernel code line by line
- Your directory structure is in place and your Makefile builds cleanly with zero warnings

***

## Phase 1 — Two-Stage Bootloader

### What Gets Built
A custom bootloader written entirely in x86 assembly, split into two stages. Stage 1 fits inside the 512-byte Master Boot Record. Stage 2 handles the transition from 16-bit real mode to 32-bit protected mode and loads the kernel into memory.

### Why This Phase Exists
Writing your own bootloader teaches you the most primal moment in a computer's lifecycle — the first 512 bytes the CPU executes after power-on. You learn what real mode is, why protected mode exists, what the GDT does before the kernel even starts, and how the BIOS hands control over to software. Most OS courses skip this and give you GRUB. You are not skipping it. Every concept here — segmentation, memory addressing, CPU modes — will resurface in later phases.

### What "Done" Looks Like
- QEMU boots from a **raw disk image** (not a kernel ELF directly): `qemu-system-i386 -drive file=myos.img,format=raw`
- Stage 1 loads Stage 2 from disk successfully
- Stage 2 performs the real mode → protected mode switch and jumps to the kernel entry point
- The kernel's "Hello, myos!" appears — same output as Phase 0, but now via your own bootloader

***

## Phase 2 — Bare Kernel: GDT, IDT, VGA Driver

### What Gets Built
The foundational kernel infrastructure: a proper Global Descriptor Table (GDT) set up from C, an Interrupt Descriptor Table (IDT) wiring up all 256 interrupt vectors, Interrupt Service Routines (ISRs) for all CPU exceptions, PIC remapping, and a VGA text-mode driver with formatted output (`kprintf`).

### Why This Phase Exists
The GDT and IDT are not optional — they are the CPU's contract with your kernel about how memory is organized and what happens when something goes wrong. Without them, a divide-by-zero or null pointer dereference causes a silent triple-fault that reboots the machine, leaving you with no debugging information. After this phase, exceptions become visible events with names, error codes, and register dumps. `kprintf` becomes your console for the rest of the project.

### What "Done" Looks Like
- Triggering a **divide-by-zero** in kernel code prints `[EXCEPTION] Divide by Zero` with a register dump and halts gracefully — no QEMU reset
- All other CPU exceptions each print their own named error
- `kprintf("Value: %d, Hex: %x\n", 42, 0xDEAD)` works correctly
- Screen scrolls when output fills it

***

## Phase 3 — Memory Management

### What Gets Built
Three stacked components: a **Physical Memory Manager (PMM)** that tracks which 4KB frames of RAM are free, a **paging subsystem** that enables the x86 MMU and gives the kernel a virtual address space, and a **kernel heap** exposing `kmalloc`/`kfree` to all kernel code.

### Why This Phase Exists
Everything interesting an OS does — loading processes, managing files, allocating buffers — requires dynamic memory. Right now the kernel has no memory management at all; all data lives in static arrays. This phase ends that. Paging is also the prerequisite for process isolation (Phase 5) and user mode (Phase 6) — you cannot have separate address spaces without it. Implementing it yourself transforms "I know what a page table is" into "I understand what a page table *is*."

### What "Done" Looks Like
- `void *a = kmalloc(64)` and `kfree(a)` work correctly and do not leak memory
- Paging is enabled; the kernel continues to run without crashing
- Accessing an unmapped address triggers a **page fault handler** that prints the faulting address — not a silent triple-fault
- A stress test allocating and freeing hundreds of blocks shows no corruption

***

## Phase 4 — Timers & Keyboard

### What Gets Built
A **PIT (Programmable Interval Timer) driver** configured to fire at 100 Hz, maintaining a global tick counter and enabling a `sleep(ms)` function. A **PS/2 keyboard driver** that translates hardware scancodes to ASCII characters and buffers them in a ring buffer.

### Why This Phase Exists
Time and input are the two axes through which any interactive system lives. Without a timer you cannot implement preemptive scheduling, `sleep()`, timeouts, or network retransmissions. Without a keyboard driver you cannot have a shell. This phase also deepens your understanding of hardware interrupts — the keyboard and timer both arrive as IRQs, and handling them correctly is a discipline applied to every driver you write afterward.

### What "Done" Looks Like
- A counter on screen increments once per second, driven purely by timer interrupts
- Every key typed in QEMU appears on screen immediately
- `sleep(1000)` blocks for exactly one second
- Shift key works (uppercase letters print correctly)

***

## Phase 5 — Processes & Preemptive Multitasking

### What Gets Built
A **Process Control Block (PCB)** structure holding all per-process state, a **context switching** routine in assembly that saves and restores CPU registers, a **kernel stack** per process, a **round-robin scheduler** invoked on every timer tick, and the `create_process()`/`destroy_process()` lifecycle.

### Why This Phase Exists
This is the heart of an operating system. The illusion that multiple programs run simultaneously — when in fact a single CPU rapidly switches between them — is the central trick that makes modern computing possible. Implementing it at the assembly level demystifies concurrency, race conditions, and all the kernel synchronization primitives you will read about for the rest of your career. It also directly connects to your eBPF experience — the kernel scheduler is the very thing eBPF's `sched_*` probes hook into.

### What "Done" Looks Like
- Two kernel tasks print their names to the screen on alternating timer ticks — interleaved output proves they are actually both running
- Killing one task does not affect the other
- A `ps` kernel command lists all running processes with their PIDs and states

***

## Phase 6 — User Mode & System Calls

### What Gets Built
**Ring 3 (user mode) process execution**, where user code runs with restricted CPU privileges. A **syscall dispatcher** wired to `int 0x80` that routes calls to kernel functions via a syscall table. A **minimal libc** (`write`, `read`, `exit`, `getpid`, `sleep`, `fork`, `exec`, `wait`, `open`, `close`) that user-space programs use to talk to the kernel. The **TSS** (Task State Segment) to handle ring transitions correctly.

### Why This Phase Exists
Ring separation is the security and stability foundation of every modern OS. Without it, a buggy user program can corrupt the kernel and take down the whole system. Understanding the ring transition — how the CPU automatically switches stacks, why the syscall ABI is what it is, what `fork` actually does to memory — gives you deep insight into why Linux behaves the way it does. Every `strace` output you have ever read is a log of exactly what you are building here.

### What "Done" Looks Like
- A hardcoded user-space program (embedded in the kernel image for now) executes in ring 3
- It calls `write(1, "Hello from user space!\n", 23)` via `int 0x80` and the text appears on screen
- It calls `exit(0)` and the kernel cleans up gracefully
- Attempting a privileged instruction from user mode triggers a **General Protection Fault** — the kernel kills the process without crashing

***

## Phase 7 — Storage: ATA Driver, VFS & ext2

### What Gets Built
An **ATA PIO disk driver** that reads and writes 512-byte sectors from a virtual disk. A **Virtual File System (VFS) abstraction layer** presenting a uniform `open`/`read`/`write`/`readdir` interface regardless of underlying filesystem. A complete **ext2 filesystem driver** implementing inode lookup, block group traversal, file data reading, directory listing, and file creation and writing.

### Why This Phase Exists
Persistence is what separates a toy kernel from something real. Every concept from the theoretical study of filesystems — inodes, block allocation, indirect blocks, directory entries — becomes concrete when you implement it from the raw on-disk byte layout. The VFS layer also teaches you one of the most important software design patterns in systems programming: the interface/implementation split that lets Linux support ext4, XFS, NTFS, and FUSE simultaneously with a single API.

### What "Done" Looks Like
- QEMU boots with a second disk image formatted as ext2
- `ls /` inside the OS prints the contents of the ext2 root directory
- `cat /hello.txt` prints the contents of a file written from your Linux host using standard tools
- Creating a new file from within the OS persists after reboot (write support confirmed)

***

## Phase 8 — ELF Loader & Full-Featured Shell

### What Gets Built
An **ELF binary loader** that reads an executable from the filesystem, maps its segments into a new process's virtual address space, and launches it in user mode. A complete implementation of `fork()` and `exec()`. A **full-featured shell** (`/bin/sh`) as a user-space program, with a suite of Unix utilities (`ls`, `cat`, `cp`, `mv`, `rm`, `mkdir`, `ps`, `grep`, `echo`, `hexdump`, and more).

### Why This Phase Exists
This phase is the moment the OS becomes real. Until now, user-space programs have been hardcoded into the kernel image. After this phase, programs live on the filesystem and the shell finds, loads, and runs them dynamically — exactly how every Linux system works. The ELF loader teaches you the binary format underlying every native Linux executable. `fork`/`exec` teaches you the Unix process model that every shell, server, and daemon relies on. The shell is your first serious user-space application and the interface through which you use the OS for every remaining phase.

### What "Done" Looks Like
- `myos$ ls /bin` lists all available commands
- `myos$ cat /etc/motd` prints a welcome message from the filesystem
- `myos$ echo "hello" > /tmp/test.txt && cat /tmp/test.txt` works end-to-end
- `myos$ ls -la | grep txt` — pipe between two processes works
- Up/down arrows scroll through command history
- Tab completes command and filename arguments
- The prompt is colorized with ANSI codes

***

## Phase 9 — Graphics: Framebuffer, Fonts & Window Manager

### What Gets Built
A **VBE (VESA BIOS Extensions) framebuffer** configured in the bootloader, giving the OS a pixel-addressable screen at 1024×768 32bpp. A **bitmap font renderer** for drawing text anywhere on screen. A **PS/2 mouse driver**. A **basic compositing window manager** with moveable, overlapping windows. A **graphical terminal emulator** window that runs the shell.

### Why This Phase Exists
This is the "wow" phase — it turns the project from a cool technical achievement into something genuinely impressive to show people. Beyond the visual impact, this phase teaches you how graphics work at the hardware level (before OpenGL, before X11, before Wayland — just a flat memory buffer and pixel math), how compositing window managers work, and how input events flow from hardware to application. It is also where the OS starts to look like *your* OS — you design the colors, the font, the window chrome, the desktop aesthetic.

### What "Done" Looks Like
- The OS boots into a graphical screen (no more text VGA mode)
- A desktop with a background color and a taskbar is visible
- A terminal window renders the shell prompt in your chosen font and color scheme
- Commands typed in the terminal execute and output appears in the window
- The mouse cursor renders as a custom sprite and moves smoothly
- Dragging a window's title bar moves it across the screen

***

## Phase 10 — Networking: Full TCP/IP Stack

### What Gets Built
**PCI bus enumeration** to find the network card. An **Intel e1000 NIC driver** using QEMU's built-in emulated hardware. The complete network stack from the ground up: **Ethernet → ARP → IPv4 → ICMP → UDP → TCP → DHCP → DNS → HTTP client**.

### Why This Phase Exists
Networking is where OS development intersects with one of the most intellectually rich bodies of engineering knowledge in existence. The TCP/IP stack is a masterclass in protocol design, state machines, reliability engineering, and layered abstraction. Implementing TCP from scratch — the 3-way handshake, sequence numbers, retransmission, the sliding window — gives you an intuition for networking that no amount of reading can match. The HTTP client at the end is the demo that sells the project: your OS, which you built from nothing, reaching out to the internet.

### What "Done" Looks Like
- `myos$ ping 10.0.2.2` receives ICMP echo replies from the QEMU gateway
- `myos$ dhcp` acquires an IP address automatically
- `myos$ http get example.com` prints the HTML of the page to the terminal
- The shell's `ps` output shows a background networking daemon handling packets

***

## Phase 11 — 64-bit Transition (x86_64 Long Mode)

### What Gets Built
A rebuilt OS targeting **x86_64**: a new cross-compiler (`x86_64-elf-gcc`), a bootloader that transitions through real → protected → **long mode**, 4-level page tables (PML4), updated register sizes and calling convention, and the `syscall`/`sysret` instruction pair replacing `int 0x80`.

### Why This Phase Exists
This is where you consolidate everything. The 32→64 bit transition forces you to revisit every subsystem — the bootloader, paging, context switching, the syscall ABI — and understand what changes and why. It teaches you the architectural abstraction layer concept (what belongs in `arch/x86_64/` vs. what is architecture-agnostic), which is exactly how the Linux kernel is structured. After this phase, the mental gap between "my hobby OS" and "how Linux actually works" is narrow enough to see across.

### What "Done" Looks Like
- `uname -m` inside the OS reports `x86_64`
- All Phase 0–10 functionality works identically in 64-bit mode
- The kernel can address more than 4 GB of RAM in principle
- Bootloader, page tables, and syscall mechanism are fully rebuilt for 64-bit

***

## Phase 12 — Built-in Text Editor

### What Gets Built
A **text editor written from scratch** as a user-space application — not a port of an existing editor. Features: open and save files from the ext2 filesystem, insert and delete text, cursor movement, line numbers, syntax highlighting for C, and a status bar showing filename and cursor position.

### Why This Phase Exists
Vim and nano both require a massive POSIX-compatible C library (termios, mmap, signals, and hundreds of other syscalls) to port. Building your own editor is more honest to the spirit of the project — and more impressive, because you wrote the editor itself, the terminal it renders inside, the filesystem it reads from, the OS it runs on. It is also the prerequisite for Phase 13: you need a way to write code inside the OS before you can compile it.

### What "Done" Looks Like
- `myos$ edit hello.c` opens the editor in a terminal window
- You can type, delete, move the cursor, and save the file with a keyboard shortcut
- C keywords are highlighted in a different color
- `myos$ cat hello.c` after saving shows the correct file contents

***

## Phase 13 — Self-Hosting Compiler (The Final Demo)

### What Gets Built
A port of **newlib** (a lightweight C standard library designed for bare-metal OS targets) providing the full POSIX API your OS's C programs need. Then a cross-compiled **GCC toolchain** that runs natively inside your OS and targets your OS — so you can compile C programs from within `myos` itself.

### Why This Phase Exists
Self-hosting is the gold standard for hobby OS legitimacy. When you can write code inside your OS, compile it, and run the resulting binary — all without leaving the OS — you have built a self-contained computing environment from first principles. This is the demo that puts the project in the same league as ToaruOS and SerenityOS. It is also deeply technical: porting newlib requires implementing dozens of additional syscalls, a proper `mmap`, signal handling, and a fully-correct `fork`/`exec`. Every hour of work in Phases 0–11 was building toward this.

### What "Done" Looks Like
- `myos$ edit hello.c` — write a C hello world program in the built-in editor
- `myos$ gcc hello.c -o hello` — compile it using GCC running natively inside the OS
- `myos$ ./hello` — run it; `Hello, World!` prints to the terminal
- The entire workflow — writing, compiling, running — never leaves the OS

***

## The Final Demo (What You Show the Internet)

A screen recording showing, in sequence:

1. **Cold boot** — BIOS → your bootloader message → graphical desktop appears
2. **Open a terminal** — window appears, shell prompt ready, mouse working
3. **Browse the filesystem** — `ls`, `cat`, pipes, redirection
4. **Fetch a webpage** — `http get example.com` prints real HTML
5. **Open the editor** — write a 10-line C program
6. **Compile and run it** — `gcc hello.c -o hello && ./hello` → output appears

That sequence — from raw boot to self-hosted compilation — is the complete story of what you built. No other explanation needed.

***

## How We Work Through This

Each phase happens in its own dedicated conversation. The pattern for every phase:

1. **Conceptual deep-dive** — understand the *why* before touching code
2. **Design decisions** — agree on the specific approach for this phase in the context of *your* OS
3. **Implementation** — write the code together, file by file
4. **Testing** — verify against the "Done" criteria above; debug everything that fails
5. **Commit and move on**

When ready, say **"Let's begin Phase 0"** and we start.