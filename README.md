# iceBreakerExample
Files and info collected to demonstrate open-source tool flow for FPGA design work.<br/>

<ul>
<li>TEST APPLICATION:&nbsp;&nbsp;&nbsp;&nbsp;Sonar distance measurement device.</li>
<li>TEST HARDWARE:   &nbsp;&nbsp;&nbsp;&nbsp;ICEBreaker module holding Lattice ICE40 (5K) part + HCSR04 sonar module.</li>
</ul>
See the photo on the repo called TestSetup.png<br/>
<br/>

| __TOOL__ | __Description__ |
| :--- | :--- |
| VERILATOR | Verilog cycle simulator and LINTing tool |
| ICARUS | Verilog event driven simulator |
| GTKWAVE | Waveform viewer |
| YOSYS | Verilog logic synthesis tool |
| NEXTPNR | Place and Route tool for targeting specific FPGA |
| ICESTORM | Set of tools for create and pumping stream to end device |

<br/>
Refer to the Makefile. It is well commented and shows how each of the tools are invoked.<br/>
<br/>
Either Verilator or Icarus could be skipped, but not both.   You should really use a simulator, though as attempting to go straight from Verilog to synthesis and the target is a fool's errand and would waste a lot of time.   Do some basic simulation at a miniumum.<br/>
<br/>
<em>The Verilator example is very simplistic. Verilator can be fast, but complex testbenches are hard to write in C++. I use Verilator mainly for LINTing.<em/>
