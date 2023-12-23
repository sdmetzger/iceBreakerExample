#pragma once
#include "verilated.h"
#include "VModule_Top.h"
class Stimulus
{
public:
    Stimulus( VModule_Top*, VerilatedFstC* , vluint64_t, vluint64_t*  );
    bool stimFinished();
    void startStim( uint8_t );
    void simTick( int );
    vluint64_t* m_simtime;
    vluint64_t m_maxtime;
    uint64_t m_simticks;
    uint8_t m_incstate;
    uint8_t m_echodistance;

private:
    VModule_Top* m_top;
    VerilatedFstC* mm_trace;
};