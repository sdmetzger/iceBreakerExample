`timescale 1ns/1ns
//-----------------------------------------------------
// Design Name : PLL_Block
// File Name   : PLL_Stub.v
// Function    : This Verilog block is to replace the techology-specific PLL block
//                that is usually specific to the FPGA vendor and tools.
//                This stub is for simulation and simply passes the input to the output.
//                Use for simulation and drive with the desired internal frequency
//                of the DUT.
//                Replace this file with the technology-specific one for synthesis.
//
// Coder       : SDM
// Created     : 12.15.23
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
