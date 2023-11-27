//-----------------------------------------------------
// Design Name : Flasher
// File Name   : Flasher.v
// Function    : Toggle the LEDs in a determinstic fashion
// Coder       : SDM
// Created     : 11.12.23
//-----------------------------------------------------
// Generates LED Flip values so that proper clock frequency and 
// implementation can be checked. Simple.
// Note that the input clock must be faster than the flash rate
// otherwise things break.
//
// Updates:
// 11.12.23- First implementation based on Emulsystem1 led_controller
//
module Flasher
  #(
    parameter CLOCK_FREQUENCY = 12_000_000,
    parameter FLASH_FREQUENCY = 5
    )
   (
    input      refclk,
    input      reset_l,
    output     o_led
   );

   localparam CLKTICKS_PER_FLASHTICK = CLOCK_FREQUENCY/(FLASH_FREQUENCY*2);
   localparam FBITS = $clog2(CLKTICKS_PER_FLASHTICK);

   /*
   initial
      begin
   	   $display("System Ticks per Flasher tick:\t%f",CLKTICKS_PER_FLASHTICK);
         $display("FLASH TIMER Frequency:\t%f",FLASH_FREQUENCY);
         $display("FLASH TIMER number of bits:\t%f",FBITS);
      end
   */
   
   reg ledbit = 1'b0;
   reg [FBITS-1:0] ftick_counter = 0;

   assign o_led = ledbit;

   // Flops.  next state figured elsewhere.  async reset done here.
   always @(posedge refclk) begin
      if (ftick_counter == CLKTICKS_PER_FLASHTICK) begin
         ftick_counter <= 0;
         ledbit <= ~ledbit;
      end
      else begin
         ftick_counter <= ftick_counter+ 1'b1;
         ledbit <= ledbit;
      end
   end


endmodule

