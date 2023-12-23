`timescale 1ns/1ns

// Simple module to demultiplex Seven-segement display values to static hex values
// for simple downstream checking.   If the value is unknown, then the error signal is raised.

module segconverter(
  input         clk,
  input         segsel,
  input   [6:0] segval,
  output  [3:0] HiSegVal,
  output  [3:0] LoSegVal,
  output        error
);

  // assign outputs to internal state as needed
  assign error    = pipeerror;
  assign HiSegVal = hiVal;
  assign LoSegVal = loVal;

  // define regs for interrnal state as needed
  reg [3:0]   hiVal;
  reg [3:0]   loVal;
  reg [3:0]   segcvt;
  reg         pipeerror;
  reg         detecterror;

  // Convert 7-Segment codes to hex values.   If code is unknown/undefined, throw an error
  // Negative logic presented
  always @* begin
    segcvt = 4'h0;
    detecterror = 0;
    case (segval)
      7'b1000000: segcvt = 4'h0;  // 8'h40
      7'b1111001: segcvt = 4'h1;  // 8'h79
      7'b0100100: segcvt = 4'h2;  // 8'h24
      7'b0110000: segcvt = 4'h3;  // 8'h30
      7'b0011001: segcvt = 4'h4;  // 8'h19
      7'b0010010: segcvt = 4'h5;  // 8'h12
      7'b0000010: segcvt = 4'h6;  // 8'h02
      7'b1111000: segcvt = 4'h7;  // 8'h78
      7'b0000000: segcvt = 4'h8;  // 8'h00
      7'b0010000: segcvt = 4'h9;  // 8'h10
      7'b0001000: segcvt = 4'hA;  // 8'h08
      7'b0000011: segcvt = 4'hB;  // 8'h03
      7'b1000110: segcvt = 4'hC;  // 8'h46
      7'b0100001: segcvt = 4'hD;  // 8'h21
      7'b0000110: segcvt = 4'hE;  // 8'h06
      7'b0001110: segcvt = 4'hF;  // 8'h0E
      default:    detecterror = 1;
    endcase
  end

  always @(posedge clk) begin
    hiVal <= ( segsel) ? segcvt : hiVal;
    loVal <= (~segsel) ? segcvt : loVal;
    pipeerror <= detecterror;
  end

endmodule
