//`timescale 1ns/1ns
//-----------------------------------------------------
// Design Name : ChipShell
// File Name   : Chipshell.v
// Function    : Simple Ultrasonic sensor driver.   Stimulates an HC-SR04 ultrasonic module 
//                and measures time to receive a response.   That time is converted to centimeters 
//                and displayed on the seven segment display as "XX", representing the number of
//                centimeters in decimal format
//
// Coder       : SDM
// Created     : 11.18.23
// 
//  System Description:
//  Speed of sound at sea level is 340.3m/sec or 340300 mm/sec
//  That's 2.9386 microseconds per mm.
//  0.3403 mm per uSecond
//  58.772 uS per cm round trip
//  Prescale the return counter by 6 just for simplicity sake
//
//  Pulse train takes 200uS to send.
//
//  increment the return counter every 59 ticks just for a rough approximation
//
//  If we set the effective range at 1 meters, that would be a 2 meter round trip, or 2000mm
//  That translates to 5.8772 milliseconds for a round trip.
//  We will take a reading every 100 mS, which will give the previous pulse ample time to die down
//  before launching another.
//
//  Sequence-
//    At 100mS boundary, 
//    Check if there was an echo.   If so, log the time and display it.
//    Send trigger pulse for 10uS
//    Start waiting for echo indication
//    At next 100 mS indication, see if there was a captured echo.
//    If so, display it.
//
//  Since this is relatively slow, compared to the speed capability of the device,
//  use native 12MHz clock.   No need for speedier PLL based clocking.
//
//-----------------------------------------------------
//
// Updates:
//  11.18.23 - First working instance implemented. Starting with flashing the Seven Segment Displays
//
//  12.02.23 - Functionality locked (and verified on physical HW) for demo purposes.  Do any 
//              extensions/enhancements elsewhere so as to not pollute the simplicity of this model 
//              since it is for demonstration purposes only.
//
module ChipShell
  #(
    parameter INPUT_CLK_FREQ      = 12_000_000
  )
  (
    input 	      CLK,
    input         BTN_N, 
    input         RX,
    output        TX,
    output 	      LEDR_N,
    output 	      LEDG_N,
            
    output        P1A1,
    output        P1A2,
    output        P1A3,
    output        P1A4,
    output        P1A7,
    output        P1A8,
    output        P1A9,
    output        P1A10,

    output        P1B1,
    output        P1B2,
    output        P1B3,
    output        P1B4,
    input         P1B7,
    output        P1B8,
    output        P1B9,
    output        P1B10

  );
 
  // There's no PLL in this one, so internal = input
  localparam INTERNAL_CLK_FREQ = INPUT_CLK_FREQ;

  wire  locked;
  wire  sysclk;
  wire  reset_l;

  wire  uSPulse;
  wire  mSPulse;
  wire  tenthPulse;

  wire  sonarecho;
  wire  sonartrigger;

  wire [3:0]  LoSeg;
  wire [3:0]  HiSeg;
  wire [6:0]  seg_pins_n;
  wire        digit_sel;
  wire        noreturn_l;
  wire        pegged_l;

  // IO pin wiring
  assign    {P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1} = seg_pins_n;
  assign    P1A10 = digit_sel;

  assign    P1B1 = sonartrigger;
  assign    sonarecho = P1B7;

  // currently defined, but unassigned pins,   Define as outputs and drive to zero.
  assign    {P1B2, P1B3, P1B4, P1B8, P1B9, P1B10}  = 0;

  // for this project we are using the native clock.
  // no global reset needed
  assign reset_l = locked & BTN_N;  // Only one when button is one, and locked, else reset.

  assign LEDR_N = noreturn_l & reset_l;     // If sonar did not return an echo or resetting
  assign LEDG_N = pegged_l;        // If return was > 1M away
  assign TX = RX;        // simply loop back.

  // Instantiate PLL Block.   For this design it is just a passthru since we are not multiplying the clock.
  PLL_block
    plx
      (
        .clkin  (CLK),
        .clkout (sysclk),
        .locked (locked)
      );

  // Instantiate master timer block to generate reference pulses
  timerflags
    #(
       // Parameters
       .INPUT_CLK_FREQ    (INTERNAL_CLK_FREQ)
    )
    tf1
      (
        // Outputs
        .uS_Flag          (uSPulse),
        .mS_Flag          (mSPulse),
        .hundredmS_Flag   (tenthPulse),
        // Inputs
        .refclk           (sysclk)
      );

  // Instantiate segment conversion for display and flip back and forth
  segdisplay
    sd1
      (
        // Outputs
        .segPins        (seg_pins_n),
        .digit_Sel      (digit_sel),
        // Inputs
        .loValue        (LoSeg),
        .hiValue        (HiSeg),
        .mSFlag         (mSPulse),
        .refclk         (sysclk)
      );


  sonarcontroller
    ctl1
      (
        //inputs
        .refclk         (sysclk),
        .uSPulse        (uSPulse),
        .tenthPulse     (tenthPulse),
        .sonarecho_raw  (sonarecho),
        //outputs
        .noreturn_l     (noreturn_l),
        .pegged_l       (pegged_l),
        .loDigit        (LoSeg),
        .hiDigit        (HiSeg),
        .sonartrigger   (sonartrigger)
      );

endmodule

//-------------------------------------------------------------------

module sonarcontroller
  (
    //inputs
    input     refclk,
    input     uSPulse,
    input     tenthPulse,
    input     sonarecho_raw,
    //outputs
    output        noreturn_l,   // if no return was seen after a trigger, set low
    output        pegged_l,     // if return pegged at max, set low
    output  [3:0] loDigit,
    output  [3:0] hiDigit,
    output        sonartrigger
  );


  // sonar controller sends a 12uS pulse every 100mS and counts the time to receive a response
  // the width of the echo return line determines the distance.

  // Function Counters;
  reg [3:0] trigCount = 0 ;
  reg [2:0] prescaler = 0 ;
  wire[3:0] mmVal;
  wire[3:0] loVal;
  wire[3:0] hiVal;
  reg [3:0] loReg = 0;      // capture registers to hold value steady between samples
  reg [3:0] hiReg = 0;      // capture registers to hold value steady between samples

  reg       countupdateflag = 0;
  reg       countcapflag = 0;
  wire      inc_mm;
  wire      inc_ones;
  wire      inc_tens;

  // placeholders for now.   Don't forget genrate these error conditions.   Reset to low by ice40.
  // Invert before sending out.
  reg       noreturn = 1'b0;
  reg       pegged = 1'b0;

  // IO Pins
  assign  sonartrigger = state[TRIGGERING];
  assign  loDigit = loReg;
  assign  hiDigit = hiReg;
  assign  noreturn_l = ~noreturn;
  assign  pegged_l = ~pegged;

  // Enumerating the states
  localparam
      TRIGGERING    = 0,
      WAITING       = 1,
      COUNTING      = 2,
      WAITFORNXT    = 3,
      LAST          = WAITFORNXT ;

  // State machine variables
  reg [LAST:0]  state = 0;
  reg [LAST:0]  next_state;

  // sonar echo comes in unsynchronized and unaligned
  reg [1:0] echopipe;
  reg       sonarecho;   // sample sonar echo on microsecond boundaries

  // dual rank synchronizer for sonar return to refclk domain.
  always @(posedge refclk)  echopipe <= {echopipe[0], sonarecho_raw};

  // only sample synchronized echo signal on uS boundaries
  always @(posedge refclk)  sonarecho <= (uSPulse) ? echopipe[1] : sonarecho;
  
  // Only bump state on uSecond boundaries
  always @(posedge refclk) state <= (uSPulse) ? next_state : state;

  always @* begin : Sonar_State_Machine_Combinatorial
    next_state = 'b0;
    case(1'b1)
      state[TRIGGERING] :
        if(trigCount == 11)
          next_state[WAITING] = 1'b1;
        else
          next_state[TRIGGERING] = 1'b1;
      state[WAITING] :
        if(tenthPulse)
          next_state[TRIGGERING] = 1'b1;
        else if(sonarecho)
          next_state[COUNTING] = 1'b1;
        else
          next_state[WAITING] = 1'b1;
      state[COUNTING] :
        if (tenthPulse)
          next_state[TRIGGERING] = 1'b1;
        else if(~sonarecho)
          next_state[WAITFORNXT] = 1'b1;
        else
          next_state[COUNTING] = 1'b1;
      state[WAITFORNXT] :
        if(tenthPulse)
          next_state[TRIGGERING] = 1'b1;
        else
          next_state[WAITFORNXT] = 1'b1;
      default :
        next_state[WAITFORNXT] = 1'b1;
    endcase // case (1'b1)
  end // end combinatorial next state determination

  // Trigger pulse width counter for 12uS wide pulse
  always @(posedge refclk) begin: triggercounter
    if( uSPulse ) begin
      if( state[TRIGGERING] ) trigCount <= trigCount + 1'b1;
      else                    trigCount <= 0;
    end
    else 
      trigCount <= trigCount;
  end

  // Prescaler for distance count.  Roughly 6uS per mm of transit, so divide uS by 6.
  always @(posedge refclk) begin: prescalecounter
    if( uSPulse ) begin
      if( state[COUNTING] ) begin 
        if(prescaler==5)  prescaler <= 0;
        else              prescaler <= prescaler + 1'b1;
      end
      else begin
        prescaler <= 0;
      end
    end
    else 
      prescaler <= prescaler;
  end

  // Flag to allow distance count update
  always @(posedge refclk) begin: countflag
    if( state[COUNTING] & (prescaler==5) & (~tenthPulse) & uSPulse )
      countupdateflag <= 1'b1;
    else
      countupdateflag <= 1'b0;
  end

  // Flag to allow counter capture and clear
  always @(posedge refclk) begin: capflag
    if( state[COUNTING] & (~sonarecho | tenthPulse) & uSPulse )
      countcapflag <= 1'b1;
    else
      countcapflag <= 1'b0;
  end

  // don't increment mm if we already pegged at 99
  assign inc_mm =   countupdateflag & ~((loVal==4'h9) & (hiVal == 4'h9));
  assign inc_ones = countupdateflag &  (mmVal == 4'h9);
  assign inc_tens = countupdateflag &  (mmVal == 4'h9) & (loVal == 4'h9);

  bcddigit bcd0 ( refclk, ~state[COUNTING], inc_mm,   mmVal );
  bcddigit bcd1 ( refclk, ~state[COUNTING], inc_ones, loVal );
  bcddigit bcd2 ( refclk, ~state[COUNTING], inc_tens, hiVal );

  // Register the output values when capture flag is set
  always @(posedge refclk) loReg <= (countcapflag) ? loVal : loReg;
  always @(posedge refclk) hiReg <= (countcapflag) ? hiVal : hiReg;

endmodule

module bcddigit
  (
      // inputs
      input   refclk,
      input   clr,
      input   increment,
      // outputs
      output  [3:0] bcdDigit
  );

  // This module generates counts to be displayed
  reg   [3:0]   counter = 4'h0;

  // assign the outputs
  assign bcdDigit = counter;

  // BCDDigit
  always @(posedge refclk) begin
    if( clr )             counter <= 0;
    else if( increment )  counter <= (counter == 4'h9) ? 4'h0: (counter + 1'b1);
    else                  counter <= counter;
  end

endmodule
