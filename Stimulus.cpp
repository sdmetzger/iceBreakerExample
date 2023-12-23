#include <iostream>
#include "Stimulus.h" 
#include "VModule_Top.h"
#include "verilated_fst_c.h"
#include "verilated.h"
#include "main_sim.h" 


// The stimulus object is where we define operations to be performed on the DUT
// sim_time holds the real simulation time

Stimulus::Stimulus(VModule_Top* top, VerilatedFstC* m_trace, vluint64_t maxtime, vluint64_t* simtime ){
    m_simticks = 0;         // There are no ticks to run when class is constructed
    m_top = top;
    mm_trace = m_trace;
    m_maxtime = maxtime;
    m_simtime = simtime;
    std::cout << "Stimulus Object Constructed." << "\n";
}

bool Stimulus::stimFinished(){
    if(m_simticks > 0)  return false;
    else                return true;
}

void Stimulus::startStim( uint8_t echodistance ){
    m_echodistance = echodistance;
    std::cout << "Stimulus Cycle Started. Echo Distance = " << m_echodistance  << "\n";

    // This is not a viable test bench since there are not escapes for locked conditions.
    // Simply for illustrative purposes.

    // Wait for sonartrigger
    while((m_top->sonartrigger == 0)&&(*m_simtime < m_maxtime)){
        simTick(1);
    }
    if (m_top->sonartrigger==1){
        std::cout << "Saw sonar trigger!"  << "\n";
    }

    simTick(5);

    // Wait for sonartrigger to go away
    while((m_top->sonartrigger == 1)&&(*m_simtime < m_maxtime)){
        simTick(1);
    }
    if (m_top->sonartrigger==0){
        std::cout << "Saw sonar trigger go away!"  << "\n";
    }

    // We know a clock is 83.33 nS.   We want to wait 5uS
    simTick(60);

    //Now assert Sonarecho and wait the appropriate amount of time representing the specified length of echo.
    
    std::cout << "Sending Echo Pulse ACTIVE."  << "\n";
    m_top->sonarecho = 1;

    // it's 58.772 uS per CM of flight time
    simTick( int( float(m_echodistance)*2*58.772*1000/83.3333 ));

    // deassert echo signal
    std::cout << "Deactivating ECHO."  << "\n";
    m_top->sonarecho = 0;

    // now wait a couple of milliseconds
    std::cout << "Propagation wait."  << "\n";
    simTick(int(2000000/83.3333));

}

void Stimulus::simTick( int ticks ){
    while(ticks--){
        // Apply stimulus at negedge.  If for some reason negative edge triggered logic is 
        // employed, may want to switch order of eval and stimulus evaluation
        mm_trace->dump(*m_simtime);
        mm_trace->flush();
        bumpTime();
        m_top->clock = 1;
        // Now evaluate the Verilated model on positive edge.
        // This is where the action occurs.
        m_top->eval();
        mm_trace->dump(*m_simtime);
        mm_trace->flush();
        bumpTime();
        m_top->clock = 0;
        // Evaluate the Verilated model at this negative edge. Nothing should happen
        m_top->eval();
        
    }
}
