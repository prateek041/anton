---
title: "Electricity, Logic Gates, and Binary"
order: 7
---

# Electricity, Logic Gates, and Binary

In the previous section we said a computer is a machine that reads instructions
from memory and executes them. But how does a machine made of metal and silicon
actually "execute" anything? How do you get from physical material to something
that can add numbers, compare values, and make decisions?

It starts with a tiny electronic switch called a **transistor**.

## Transistors: The Smallest Switch

You do not need a physics degree to understand a transistor. You just need one
mental model: a transistor is a switch with three connections. There is an
input, an output, and a control signal. When the control signal is "on" (a high
voltage), electricity flows from input to output. When the control signal is
"off" (a low voltage), no electricity flows.

That is it. On or off. Flow or no flow. 1 or 0.

A modern CPU has billions of these switches etched into a chip the size of your
thumbnail. They are unimaginably small, but each one still does the same
fundamental thing: it is either on or it is off.

![A transistor as a switch: ON (current flows) vs OFF (no
current)](../images/ch1/transistor-switch.svg)

Now here is the question that matters: how do you get from billions of tiny
on/off switches to a machine that can run an operating system? The answer is
that you combine switches in clever arrangements to build something called
**logic gates**, and then you combine logic gates to build everything else.

## Logic Gates

A **logic gate** takes one or two binary inputs (each either 0 or 1) and
produces a single binary output based on a fixed rule. There are a handful of
fundamental gates, and every digital circuit ever built is made from
combinations of them.

Let's walk through each one.

### NOT Gate (Inverter)

The simplest gate. It takes one input and flips it. If the input is 1, the
output is 0. If the input is 0, the output is 1.

Think of it like a light switch wired backwards: when you push the switch "on,"
the light turns off. When you push it "off," the light turns on.

| Input | Output |
| ----- | ------ |
| 0     | 1      |
| 1     | 0      |

A NOT gate is built from a single transistor. When the control signal is high
(1), the transistor connects the output to ground (0). When the control signal
is low (0), the output is pulled high (1). One transistor, one inversion.

### AND Gate

An AND gate takes two inputs and outputs 1 only when **both** inputs are 1. If
either input is 0, the output is 0.

Picture two light switches wired in series, one after the other. Current can
only flow through to the light bulb if **both** switches are on. If either one
is off, the circuit is broken.

| Input A | Input B | Output |
| ------- | ------- | ------ |
| 0       | 0       | 0      |
| 0       | 1       | 0      |
| 1       | 0       | 0      |
| 1       | 1       | 1      |

### OR Gate

An OR gate takes two inputs and outputs 1 when **at least one** input is 1. The
output is 0 only when both inputs are 0.

Now picture two light switches wired in parallel, side by side. Current can flow
through to the light bulb if **either** switch is on. The only way the light
stays off is if both switches are off.

| Input A | Input B | Output |
| ------- | ------- | ------ |
| 0       | 0       | 0      |
| 0       | 1       | 1      |
| 1       | 0       | 1      |
| 1       | 1       | 1      |

### XOR Gate (Exclusive OR)

XOR outputs 1 when the inputs are **different** and 0 when they are the
**same**. It is like OR, but it excludes the case where both inputs are 1.

| Input A | Input B | Output |
| ------- | ------- | ------ |
| 0       | 0       | 0      |
| 0       | 1       | 1      |
| 1       | 0       | 1      |
| 1       | 1       | 0      |

![The four fundamental logic gates: NOT, AND, OR, XOR with truth
tables](../images/ch1/logic-gates.svg)

XOR might seem like a strange rule, but it turns out to be incredibly useful. It
is the heart of binary addition (as we will see shortly), and it shows up
constantly in encryption, checksums, and bit manipulation. You will use XOR
operations in the kernel more often than you might expect.

## From Gates to Circuits That Do Math

So we have switches that can be combined into gates, and gates that output 0 or
1 based on simple logical rules. How do we get from here to a machine that can
actually add numbers?

Let's build up to it.

### The Half-Adder

Adding two single-bit numbers (each either 0 or 1) can produce two results: a
**sum** bit and a **carry** bit.

Think about it with regular decimal arithmetic first. If you add 7 + 5, you
get 12. The 2 is the sum digit and the 1 is the carry. Binary addition works the
same way, but with only two digits (0 and 1) instead of ten.

Here are all the possible cases for adding two single bits:

| A   | B   | Sum | Carry |
| --- | --- | --- | ----- |
| 0   | 0   | 0   | 0     |
| 0   | 1   | 1   | 0     |
| 1   | 0   | 1   | 0     |
| 1   | 1   | 0   | 1     |

Look at the Sum column. It is exactly XOR. Look at the Carry column. It is
exactly AND. So a half-adder is just two gates: one XOR gate for the sum and one
AND gate for the carry. Two logic gates, and you have a circuit that can add.

![A half-adder: XOR gate produces Sum, AND gate produces
Carry](../images/ch1/half-adder.svg)

### The Full-Adder

A half-adder only handles two inputs. But when you are adding multi-bit numbers
(like adding two 32-bit integers), each column needs to account for a carry
coming in from the previous column. A **full-adder** takes three inputs: A, B,
and Carry-In. It produces a Sum and a Carry-Out.

You can build a full-adder from two half-adders and an OR gate. Chain 32
full-adders together, feeding each one's carry-out into the next one's carry-in,
and you have a **32-bit adder**. That is the circuit inside the CPU that adds
two 32-bit numbers. It is just a chain of logic gates.

![A 4-bit adder built from chained
full-adders](../images/ch1/full-adder-chain.svg)

### Multiplexers

A **multiplexer** (or mux) is another fundamental building block. It has
multiple data inputs, one or more selection inputs, and one output. The
selection inputs choose which data input gets passed through to the output.

Think of it like a train track switch. Multiple tracks converge, and the switch
operator decides which track connects to the main line. In digital circuits, the
CPU uses multiplexers constantly to route data from one place to another based
on the current instruction.

### Flip-Flops: Remembering a Bit

All the gates we have seen so far are **combinational**: the output depends only
on the current inputs. But a computer also needs to **remember** things. It
needs storage.

A **flip-flop** is a circuit built from gates that can store exactly one bit. It
has a data input and a clock input. When the clock signal ticks, the flip-flop
captures whatever value is on the data input and holds it, even after the input
changes. It "remembers" the last value it was told to store.

Group 8 flip-flops together and you can store a byte. Group 32 together and you
have a 32-bit register. The CPU's registers, which we will explore in detail
when we get to the x86 architecture, are built from flip-flops.

So the progression is: transistors make gates, gates make adders and
multiplexers and flip-flops, and those building blocks make the CPU. Billions of
transistors, organized through layers of abstraction, become a machine that can
compute.

## Why Binary?

At this point, you might be wondering: why does everything have to be 0 and 1?
Why not use ten voltage levels and work in decimal? Or three levels for a
ternary system?

The answer is reliability. A transistor can reliably distinguish between two
states: high voltage and low voltage, on and off. If you tried to use ten
different voltage levels to represent the digits 0 through 9, the circuit would
need to distinguish between very small differences in voltage. Electrical noise,
temperature changes, and manufacturing variations would cause constant errors.
Two states is robust. Ten states is fragile.

Binary is not some arbitrary choice. It is a direct consequence of building
computers from transistors that work as switches. Two states. On or off. 1 or 0.
Everything else is built on top of that.

## Bits, Nibbles, Bytes, Words

Since we are working in binary, we need a vocabulary for talking about groups of
bits.

- A **bit** is a single binary digit. 0 or 1. This is the fundamental unit of
  information in a computer.

- A **nibble** is 4 bits. It can represent values from 0 to 15 (that is, `0000`
  to `1111` in binary). A nibble maps perfectly to a single hexadecimal digit,
  which is why we care about it.

- A **byte** is 8 bits. It can represent values from 0 to 255 (that is,
  `00000000` to `11111111`). The byte is the standard unit of memory. When
  people say a file is 4 kilobytes, they mean it is 4,096 bytes, or 32,768 bits.

- A **word** is a unit of data that matches the natural processing width of the
  CPU. On a 16-bit CPU, a word is 16 bits (2 bytes). On a 32-bit CPU, a word is
  32 bits (4 bytes). On a 64-bit CPU, a word is 64 bits (8 bytes).

- A **doubleword** (or dword) is 32 bits (4 bytes). In x86 terminology, this is
  the natural size for a 32-bit processor. When we start writing Anton in 32-bit
  mode, most of our registers and addresses will be 32 bits wide.

- A **quadword** (or qword) is 64 bits (8 bytes). This becomes the natural size
  when we transition Anton to 64-bit mode in Phase 11.

![Data size units from bit to quadword](../images/ch1/data-sizes.svg)

Why these specific sizes? They are all powers of 2, and they correspond to the
physical widths of the buses and registers inside the CPU. A 32-bit CPU has a
32-bit-wide data path, so it processes data 32 bits at a time. The sizes are not
arbitrary. They are dictated by the hardware.

You will see these terms constantly throughout this book, especially "byte" and
"word." Every memory address, every register value, every piece of data the CPU
touches is measured in these units. This vocabulary is the foundation for
everything that follows.

In the next section, we will take these binary numbers and learn how to actually
work with them: how to count in binary and hexadecimal, how to do arithmetic,
and how to manipulate individual bits. These are the operations that kernel code
uses on nearly every line.
