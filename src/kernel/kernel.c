/* kernel.c — The kernel entry point. Prints to VGA text buffer. */

#include <stdint.h>

#define VGA_ADDRESS 0xB8000
#define VGA_WIDTH 80
#define VGA_WHITE 0x0F

void kernel_main(void) {
  // volatile here means "don't optimise this away, i am really writing to
  // hardware"
  // uint16_t because each character is 2 bytes (16 bits), defining the ASCII
  // code for the character and the color.
  volatile uint16_t *vga = (volatile uint16_t *)VGA_ADDRESS;
  const char *msg = "Hello, anton!";

  /* Clear the screen */
  for (int i = 0; i < VGA_WIDTH * 25; i++) {
    vga[i] = (VGA_WHITE << 8) | ' ';
  }

  /* Print the message */
  for (int i = 0; msg[i] != '\0'; i++) {
    vga[i] = (VGA_WHITE << 8) | msg[i];
  }
}
