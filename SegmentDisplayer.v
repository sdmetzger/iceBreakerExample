//-----------------------------------------------------
// Design Name : segdisplay
// File Name   : SegmentDisplayer.v
// Function    : Display value on 7 segments PMOD module.
// Created     : 11.20.23
//-----------------------------------------------------
// Can hook this up to any PMOD port at the upper level.
// Every millisecond the display flips back and forth between the low
// and high values.   There is no storage on the PMOD module itself,
// so the process is active.   It does not seem to flicker on changes.
//
// Updates:
// 11.20.23 - First implementation based on experimentation
//

module segdisplay
  (
      // inputs
      input         refclk,
      input         mSFlag,
      input  [3:0]  loValue,
      input  [3:0]  hiValue,
      // outputs
      output [6:0]  segPins,
      output        digit_Sel
  );

  // This module generates the seven segment coding and output register
  reg           flipper = 1'b0;
  wire   [3:0]  outVal;
  wire   [6:0]  segvalues;

  assign segPins = segvalues;
  assign digit_Sel = flipper;

  // update on millisecond boundaries, else hold value
  always @(posedge refclk) flipper <= (mSFlag) ? ~flipper : flipper;
  
  // The rest of this is combinatorial.   Change if there is flickering.
  // flipper (digit_sel) HIGH display low value (rightmost segment) coming in.
  assign outVal = (flipper) ? loValue : hiValue;

  digits_to_segments dseg1 ( outVal, segvalues);

endmodule

module digits_to_segments
  ( 
    // inputs
    input  [3:0]  cValue,
    output [6:0]  segCode
  );

    reg [6:0]  segments;

    assign segCode = segments;
    // Convert 4-bit hex code to 7-segment values for PMOD display module.
    // Negative logic presented
    always @*
      case (cValue)
        4'h0: segments = 7'b1000000;  // 8'h40
        4'h1: segments = 7'b1111001;  // 8'h79
        4'h2: segments = 7'b0100100;  // 8'h24
        4'h3: segments = 7'b0110000;  // 8'h30
        4'h4: segments = 7'b0011001;  // 8'h19
        4'h5: segments = 7'b0010010;  // 8'h12
        4'h6: segments = 7'b0000010;  // 8'h02
        4'h7: segments = 7'b1111000;  // 8'h78
        4'h8: segments = 7'b0000000;  // 8'h00
        4'h9: segments = 7'b0010000;  // 8'h10
        4'hA: segments = 7'b0001000;  // 8'h08
        4'hB: segments = 7'b0000011;  // 8'h03
        4'hC: segments = 7'b1000110;  // 8'h46
        4'hD: segments = 7'b0100001;  // 8'h21
        4'hE: segments = 7'b0000110;  // 8'h06
        4'hF: segments = 7'b0001110;  // 8'h0E
      endcase

endmodule

