`timescale 1ns/1ns
//-----------------------------------------------------
// Design Name : Module_top
// File Name   : Module_top.v
// Function    : Top Level Simulation. Include Chip model plus any support modules
//                such as RAM, external components, etc...
//                Instantiated elements should be written in a synthesizabvel fashion
//                so as to keep Verilator happy.   However, other than ChipShell,
//                none of the other elements will be synthesized.
//
// Coder       : SDM
// Created     : 12.15.23
// 
//  Since this is relatively slow, compared to the speed capability of the device,
//  use native 12MHz clock.   Empty PLL block is instantiated as reference for derived 
//  designs using PLL multiplication functionality.
//
//-----------------------------------------------------
//
// Updates:
//  11.18.23 - First working instance implemented.   Standard Reference
//  12.19.23 - Modified from test article to working example
//
// Top level chip pins exposed to the world
//

module Module_Top(
        input           clock,
        input           sonarecho,
        output          sonartrigger,
        output  [3:0]   segvalHi,
        output  [3:0]   segvalLo,
        output          TX,
        input           RX,
        input           button,
        output          LED_R,
        output          LED_G,
        output          converterror
        );

  // Assign Inputs and outputs

  // Declare wiring and items needed for module hookups
  wire  [6:0]   segmentl;
  wire          segsel;

  // static flags and control

  // Instantiate CHIP under development. Only connect used pins.
  // NOTE: Remember to disable "unconnected" warning in LINT
  ChipShell
    #(
      /* Passed parameters */
      .INPUT_CLK_FREQ (12_000_000)
    )
    cx
    (
      .CLK      (clock),
      .BTN_N    (button), 
      .RX       (RX),
      .TX       (TX),
      .LEDR_N   (LED_R),
      .LEDG_N   (LED_G),
      .P1A1     (segmentl[0]),
      .P1A2     (segmentl[1]),
      .P1A3     (segmentl[2]),
      .P1A4     (segmentl[3]),
      .P1A7     (segmentl[4]),
      .P1A8     (segmentl[5]),
      .P1A9     (segmentl[6]),
      .P1A10    (segsel),
      .P1B1     (sonartrigger),
      .P1B7     (sonarecho)
    );

  // Instantiate Support models for simulation.  Synthesizable Verilog (though not synthesized)

  // Segment converter simply takes seven segment data and does the inverse conversion to hex
  // and holds the value static (gets rid of the flipping)
  // (assumes that we are synchronous to the master clock)
  segconverter osc ( clock, segsel, segmentl, segvalHi, segvalLo, converterror );

endmodule
