#include <iostream>
#include <stdlib.h>
#include <time.h>
#include "verilated_fst_c.h"

#include "VModule_Top.h"
#include "verilated.h"

#include "Stimulus.h"
#include "main_sim.h"

//------------------------------------------------------------------------------
// IMPORTANT NOTE: ALL TIMES ARE IN nS throughout.   No fractional nS!!
// For cycle based simulation, the modeled time has little meaning to the logic model.
// Time is used in this case to allow the test routines to properly space operations,
// and so that the waveform files are more readable.
//------------------------------------------------------------------------------


// Max time just to limit things in case the tests themselves get stuck.
constexpr long long int MAX_TIME=200000000;    // .2 seconds of simulated time.

// Globals are not good, but it's a whole lot easier than passing around the global system time.
// If there ever was a reason for globals, global sim time is it.
vluint64_t sim_time = 0;

vluint64_t CheckPoint;
vluint64_t CheckInterval = 10000000;
vluint64_t sim_inc = 42;
int time_bumper = 0;


// --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- 
// Simulation Specific.   Clock is 12 MHz.  Half period is 41.66667nS
// To make this work on integer time boundaries, go 42nS,42nS,41nS, ... repeat
// Every 3 half ticks things will line up with reality.   In between things will be off by 1nS.
// --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- --!-- 
void bumpTime( void ){
        sim_time = sim_time + sim_inc;
        if (time_bumper++ == 2){
                sim_time = sim_time - 1;
                time_bumper = 0;
        }
        if(sim_time > CheckPoint){
        std::cout << "Simulation CheckPoint.  Time:\t" << sim_time << "\n";
        CheckPoint = CheckPoint + CheckInterval;
}

}

/*
void tickSim(int ticks, VModule_Top* top, VerilatedFstC* m_trace, Stimulus* stim){
        while(ticks--){
                top->clock = 0;
                // Evaluate the Verilated model at this negative edge.
                // Nothing should happen on this edge
                top->eval();
                // Apply stimulus at negedge.  If for some reason negative edge triggered logic is 
                // employed, may want to switch order of eval and stimulus evaluation
                stim->tickStimulus();
                m_trace->dump(sim_time);
                m_trace->flush();
                bumpTime();
                if(sim_time>CheckPoint){
                        std::cout << "Simulation CheckPoint.  Time:\t" << sim_time << "\n";
                        CheckPoint = CheckPoint + CheckInterval;
                }
                top->clock = 1;
                // Now evaluate the Verilated model on positive edge.
                // This is where the action occurs.
                top->eval();
                m_trace->dump(sim_time);
                m_trace->flush();
                bumpTime();
        }
}
*/

int main(int argc, char **argv, char **env)
{
        time_t start_seconds;
        start_seconds = time(NULL);
        const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
        Verilated::commandArgs(argc, argv);
        VModule_Top *top = new VModule_Top;
        Verilated::traceEverOn(true);
        VerilatedFstC* m_trace = new VerilatedFstC;
        top->trace(m_trace, 99);
        m_trace->open("waveforms.fst");

        CheckPoint = CheckInterval;

        // Declare new stimulus object
        Stimulus Stim1( top, m_trace, MAX_TIME, &sim_time );

        // --------------------------------------------------------------
        // Set initial clock state, all important pin states
        // Perform first half tick with clock low to allow inputs to settle
	top->clock = 0;
        top->sonarecho = 0;
        top->RX = 1;
        top->button = 1;

        // ----------------
        top->eval();
        // Initial dump with starting conditions applied
        m_trace->dump(sim_time);
        m_trace->flush();
        bumpTime();             // give it time to propagate (to time 1)


        // Give it a low half of the first clock cycle
        top->clock = 0;
        top->eval();

        // ----------------------------------------
        // Start main simulation sequence
        // ----------------------------------------

        // Number of ticks with increment set to one
        Stim1.startStim( 24 );

        std::cout << "Stimulus operation completed.  Time:" << sim_time << "\n";

        // Gicve it a couple of ticks to clean up.
        Stim1.simTick(5);

        // ----------------------------------------
        // End main simulation sequence
        // ----------------------------------------

        // Capture last wave point
        m_trace->dump(sim_time);
        m_trace->flush();

	std::cout << "Finished. Simulation Time (nS):\t" << sim_time << "\n";
	std::cout << "Wall time required for Sim (S):\t" << (time(NULL) - start_seconds) << "\n";
	
        // cleanly close trace file
        m_trace->close();
        delete m_trace;
        delete top;
        exit(EXIT_SUCCESS);
}

