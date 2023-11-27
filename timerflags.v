//-----------------------------------------------------
// Design Name : timerflags
// File Name   : timerflags.v
// Function    : Toggle the LEDs in a determinstic fashion
// Coder       : SDM
// Created     : 11.19.23
//-----------------------------------------------------
// Generates timing pulse so this doesn't have to be done everywhere in the chip
//
// Updates:
// 11.18.23 - First implementation based on Example Flasher.v code
//
module timerflags
  #(
      parameter INPUT_CLK_FREQ = 12_000_000  // default input clock
  )
  (
      // inputs
      input   refclk,
      // outputs
      output  uS_Flag,
      output  mS_Flag,
      output  hundredmS_Flag
  );

  // This module generates single systick wide pulses at the specified time intervals 
  // to avoid upper stages having to do a lot of counting

   // YOSYS did not like the math in the following statements.
  //localparam SYSTICKS_PER_US = INPUT_CLK_FREQ / 1e6;
  localparam SYSTICKS_PER_US = 12;
  //localparam FBITS = $clog2(INPUT_CLK_FREQ/1e6);
  localparam FBITS = 4;

  reg               mstr_pulse;
  reg   [FBITS-1:0] mstrcnt = 0;
  reg               uS_Pulse;
  reg               mS_Pulse;
  reg   [9:0]       mSCount = 0;  
  reg               tenth_Pulse;
  reg   [6:0]       tenthCount = 0;  


  // assign the outputs
  assign uS_Flag = uS_Pulse;
  assign mS_Flag = mS_Pulse;
  assign hundredmS_Flag = tenth_Pulse;

  // master uS counter;
  always @(posedge refclk) begin
    if( mstrcnt == (SYSTICKS_PER_US-1)) begin
      mstr_pulse <= 1'b1;
      mstrcnt <= 0;
    end
    else begin
      mstr_pulse <= 1'b0;
      mstrcnt <= mstrcnt + 1'b1;
    end
  end

  // master mS counter;
  always @(posedge refclk) begin
    if(mstr_pulse)begin
      if( mSCount == 999) begin
        mS_Pulse <= 1'b1;
        mSCount <= 0;
      end
      else begin
        mS_Pulse <= 1'b0;
        mSCount <= mSCount + 1'b1;
      end
    end
    else begin
      mSCount <= mSCount;
      mS_Pulse <= 1'b0;
    end
  end

  // master tenth counter;
  always @(posedge refclk) begin
    if(mstr_pulse && (mSCount==999))begin
      if( tenthCount == 99) begin
        tenth_Pulse <= 1'b1;
        tenthCount <= 0;
      end
      else begin
        tenth_Pulse <= 1'b0;
        tenthCount <= tenthCount + 1'b1;
      end
    end
    else begin
      tenthCount <= tenthCount;
      tenth_Pulse <= 1'b0;
    end
  end
  
  // pipeline the uS pulse so everything lines up.
  always @(posedge refclk)  uS_Pulse <= mstr_pulse;

endmodule