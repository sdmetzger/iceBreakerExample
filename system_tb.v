// Test fixture for: Tool Chain Validation
`timescale 1ns/10ps

module system_tb
  #(
      /* Called Parameters */
      parameter INPUT_CLK_FREQ      = 12_000_000
    )
   (
      /* External Pins (none for simulation bench) */
   );

   localparam  FLASHER_FREQ        = 5;
   localparam  CLK_PERIOD        = 1e9/INPUT_CLK_FREQ;
   localparam  HALF_CLK_PERIOD   = CLK_PERIOD/2;

   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire  		led_r;	   // RED LED indicator
   wire        led_g;      // GREEN LED indicator

   // Simulation Registers
   reg         sysclk;
   reg [1:0]   btn;
   reg         uart_rx = 1;
   reg         MasterErrorFlag;
   reg         sonarecho = 0;
   real        opStartTime, opCurTime;
   localparam  OPTIMEOUT = 110000000;

   task SendDistance;
      input integer Distance;    // distance in mm
      integer k;
      begin
         //Wait for a trigger
         opStartTime = $realtime;
         while(~sonartrigger && (($realtime - opStartTime)<OPTIMEOUT)) begin
         @(posedge sysclk); // wait a tick
         end

         if(~sonartrigger) begin
            $display("\nNever saw a trigger!!");
            MasterErrorFlag = 1'b1;
         end
         else begin
            //Wait for trigger to end
            opStartTime = $realtime;
            while(sonartrigger && (($realtime - opStartTime)<OPTIMEOUT)) begin
            @(posedge sysclk); // wait a tick
            end

            if(sonartrigger) begin
               $display("\nNever saw trigger go away!!");
               MasterErrorFlag = 1'b1;
            end

            //trigger has gone away, wait a few microseconds
            #450000
            sonarecho = 1'b1;    // set the echo response
            k = ((Distance*6))*1000;
            $display("%t\tSending Echo response: %d mm\t Time to wait (uS): %d", $time, Distance, k/1000);
            #(k); // wait computed amount of time.
            sonarecho = 1'b0;    // set the echo response inactive
         end
      end
   endtask

   // Instantiate free-running elements
   always begin : Reference_Clock
      #HALF_CLK_PERIOD sysclk = ~sysclk;
   end

   // Simulation monitors and notifiers
   initial
      begin
      	$display("TB Clock Frequency:\t%f",INPUT_CLK_FREQ);
	      $display("TB Clock Period:\t%f",CLK_PERIOD);
	      $display("TB Half Clock Periods\t%f",HALF_CLK_PERIOD);
      end
   
   // =================================================================
   // Main Simulation event Sequence
   initial begin : Initial_TestBench_State
      $dumpfile("ctest.vcd");
      $dumpvars(0,system_tb);
      MasterErrorFlag = 1'b0;

      // Initial Pin State
      btn          = 2'b00;
      sysclk       = 1'b0;

      // Time Marches from this point forward
      // --------------------------------------------------------------
      // Clock mulitplier PLL can take a really long time to start up.  
      // DO NOT REMOVE.
      // Do not do anything except drive clock prior to this.
      // --------------------------------------------------------------

      #8000;   // PLL Stabilization time.

      // Reset test sequence
      #200 btn     = 2'b01;   // Either button press causes a reset.
      #200 btn     = 2'b10;
      #200 btn     = 2'b11;
      #200 btn     = 2'b00;

      #1000;

      // Generate some sonar returns to be captured and displayed.
      $display("\n\nTest Sonar Responses");
      #90000; // give it 90uSbefore  starting

      SendDistance(100);
      SendDistance(760);
      SendDistance(860);
      SendDistance(1200);
      SendDistance(1500);
      SendDistance(940);

      #200000000; // let another couple of intervals pass just for good measure.

      if(MasterErrorFlag) begin
	      $display("\n!!!! There were errors during simulation !!!!!  Check Logs closely.\n");
      end
      else begin
	      $display("\nSimulation successfully completed with no error flag.\n");
      end
      $finish;
   end

   // Instantiate the full ICE40 chip

   ChipShell
     #(
         /*Parameters*/
         .INPUT_CLK_FREQ	   (INPUT_CLK_FREQ)
      )
      DUT
      (
         // Outputs
         .LEDR_N		(led_r),
         .LEDG_N		(led_g),
         .TX         (uart_tx),
         .P1B1       (sonartrigger),
         // Inputs
         .P1B7       (sonarecho),
         .BTN_N		(btn[0]),
         .RX         (uart_rx),
         .CLK			(sysclk)
      );
         
endmodule

