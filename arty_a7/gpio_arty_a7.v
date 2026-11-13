// SPDX-License-Identifier: MIT
// Copyright (c) 2020-2025 RVX Project Contributors
//
//   gpio[1:0]  LD4, LD5  (LEDs)
//   gpio[3:2]  SW0, SW1  (slide switches)
//
// The direction of each pin is chosen by software (OE register).
// BTN0 is the SoC reset.

module gpio_arty_a7 #(

  parameter GPIO_WIDTH = 4

  )(

  input   wire clock,
  input   wire reset,
  input   wire uart_rx,
  output  wire uart_tx,
  inout   wire [GPIO_WIDTH-1:0] gpio

  );

  // GPIO signals
  wire [GPIO_WIDTH-1:0] gpio_input;
  wire [GPIO_WIDTH-1:0] gpio_oe;
  wire [GPIO_WIDTH-1:0] gpio_output;

  // Divides the 100MHz board clock by 2
  reg clock_50mhz;
  initial clock_50mhz = 1'b0;
  always @(posedge clock) clock_50mhz <= !clock_50mhz;

  // Reset synchronizer (2 flops). Asserted at power-up so the SoC always
  // starts from a known state. This synchronizes the button; it does not
  // debounce it.
  (* ASYNC_REG = "TRUE" *) reg [1:0] reset_sync = 2'b11;
  always @(posedge clock_50mhz) begin
    reset_sync <= {reset_sync[0], reset};
  end
  wire reset_synchronized = reset_sync[1];

  // Input synchronizer (2 flops per pin) for the asynchronous switch inputs
  (* ASYNC_REG = "TRUE" *) reg [GPIO_WIDTH-1:0] gpio_sync_ff1 = {GPIO_WIDTH{1'b0}};
  (* ASYNC_REG = "TRUE" *) reg [GPIO_WIDTH-1:0] gpio_sync_ff2 = {GPIO_WIDTH{1'b0}};
  always @(posedge clock_50mhz) begin
    gpio_sync_ff1 <= gpio;
    gpio_sync_ff2 <= gpio_sync_ff1;
  end

  // Tri-state pads. Pins driven by the SoC read back their output register;
  // pins used as inputs read the synchronized pad.
  genvar i;
  generate
    for (i = 0; i < GPIO_WIDTH; i = i + 1) begin : gpio_pad
      assign gpio_input[i] = gpio_oe[i] ? gpio_output[i] : gpio_sync_ff2[i];
      assign gpio[i]       = gpio_oe[i] ? gpio_output[i] : 1'bZ;
    end
  endgenerate

  rvx #(

    .CLOCK_FREQUENCY          (50000000               ),
    .UART_BAUD_RATE           (9600                   ),
    .MEMORY_SIZE              (8192                   ),
    .MEMORY_INIT_FILE         ("gpio_demo.hex"        ),
    .BOOT_ADDRESS             (32'h00000000           ),
    .GPIO_WIDTH               (GPIO_WIDTH             )

  ) rvx_instance (

    .clock                    (clock_50mhz            ),
    .reset                    (reset_synchronized     ),
    .halt                     (1'b0                   ),
    .uart_rx                  (uart_rx                ),
    .uart_tx                  (uart_tx                ),
    .gpio_input               (gpio_input             ),
    .gpio_oe                  (gpio_oe                ),
    .gpio_output              (gpio_output            ),
    .sclk                     (), // unused
    .pico                     (), // unused
    .poci                     (1'b0                   ),
    .cs                       ()  // unused

  );

endmodule
