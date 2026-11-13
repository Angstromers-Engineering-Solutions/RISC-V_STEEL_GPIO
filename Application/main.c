// SPDX-License-Identifier: MIT
// Copyright (c) 2020-2025 RVX Project Contributors
//
// GPIO check for the 8-pin Arty A7 wrapper (see arty_a7/gpio_arty_a7.v).
//
//   gpio[3:0] = LEDs LD4..LD7   (outputs)
//   gpio[7:4] = switches SW0..SW3 (inputs)
//
// Each LED follows its switch: SW0 -> LD4, SW1 -> LD5, SW2 -> LD6, SW3 -> LD7.
// If an LED does not follow its switch, that pin's input or output path is
// not working.

#include "libsteel.h"

#define DEFAULT_GPIO ((GpioController *)0x80020000)

#define LED_MASK  0x0000000FU   // gpio[3:0]
#define SW_SHIFT  4U            // gpio[7:4]

void main(void)
{
  gpio_set_output_group(DEFAULT_GPIO, LED_MASK);  // LEDs out, switches stay inputs

  while (1)
  {
    uint32_t switches = (gpio_read_all(DEFAULT_GPIO) >> SW_SHIFT) & LED_MASK;
    gpio_write_group(DEFAULT_GPIO, switches);
  }
}
