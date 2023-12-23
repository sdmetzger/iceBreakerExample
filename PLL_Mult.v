`timescale 1ns/1ns
//-----------------------------------------------------
// Design Name : PLL_Block
// File Name   : PLL_Mult.v
// Function    : This Verilog block is the technology-specific PLL block to be used for synthesis.
//                Usually it contains the specific PLL to be used for synthesis and implementation.
//                In this case it is a passthru since we are using the external clock without
//                multiplication
//
// Coder       : SDM
// Created     : 12.18.23
// 
//-----------------------------------------------------
//
// Updates:
//  11.18.23 - First working instance implemented.   Standard Reference.
//
//

module PLL_block(
        output  clkout,
        output  locked, 
        input   clkin
    );

  assign locked = 1'b1;
  assign clkout = clkin;
    
endmodule
