# SDM MAKE file for creating various FPGA functions ICE40 based ICEBREAKER module is the target
# Initial Major Update: 120223
# Updated 12/18/2023 to add "standardized C++ driver for extensive Verilator sims.
# 			Removed any traces of cocotb experiment.  COCOTB was very cool, but just too slow
#			to be useful for long sims
#
# Usage:
#
# make lint		Runs Verilator's lint against model - not the non-synthesizable testbench, though
# make vsim		Runs Verilator using main_sim.cpp as the driving shell testbench
# make isim		Runs Icarus as the simulator using system_tb.v as the driving testbanch
# make build	Synthesizes PROJ using YOSYS, place and rout with nextpnr, makes bitstream w/icepack
# make burn		Sends binary file to target system using iceprog
# make time		Runs timing analysis using icetime - no more serious info than from nextpnr
# make waves	Invokes GTKWAVE on active wave file
# make clean	Removes any/all generated files so next make is virgin
#
# COCOTB was a failed experiment; too slow.  Long sims require verilator.  If Icarus is used, a separate testbench must be 
# maintained (system_tb.v)
#

# Project setup
CHIPTOP		= ChipShell
MODTOP		= Module_Top
ISIMTOP		= system_tb
PCFFILE		= icebreaker.pcf
IBTFILE		= icebreakertiming.pcf
DEVICE  	= 5k
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(FILES)

# File Groupings
CHIPFILES 	= ChipShell.v timerflags.v SegmentDisplayer.v
MODULEFILES	= Module_Top.v $(CHIPFILES) PLL_Stub.v segconverter.v
STIMFILES	= main_sim.cpp Stimulus.cpp
ISIMFILES	= system_tb.v $(MODULEFILES)
# for synthesis, replace dummy PLL with real one
SYNTHFILES	= $(CHIPFILES) PLL_Mult.v

# Warnings in Verilator I do not care about
IWARNS = -Wno-UNUSEDPARAM -Wno-DECLFILENAME -Wno-PINMISSING

.PHONY: lint isim vsim build clean burn time

lint: $(MODULEFILES)
	# Use verilator for linting since it is much more thorough.  Only chip is checked.  Not testbench.
	verilator -Wall --lint-only $(IWARNS) --top $(MODTOP) $(MODULEFILES)

vsim: $(MODULEFILES) $(STIMFILES)
	# verilator simulation
	verilator -Wall --trace-fst -cc $(IWARNS) --top $(MODTOP) $(MODULEFILES) --exe $(STIMFILES)
	make -C obj_dir -j -f V$(MODTOP).mk V$(MODTOP)
	obj_dir/V$(MODTOP)

isim: $(ISIMFILES)
	# first compile with icarus (generates LINT and simulation executable)
	iverilog -o sim.vvp -s $(ISIMTOP) $(ISIMFILES)
	# Run the simulation executable
	vvp sim.vvp -fst

waves: waveforms.fst
	# Display waveforms
	gtkwave -o waveforms.fst

build: $(SYNTHFILES) $(PCFFILE)
	# synthesize using Yosys
	yosys -p "synth_ice40 -top $(CHIPTOP) -json $(CHIPTOP).json" $(SYNTHFILES)
	# Place and route using nextpnr
	nextpnr-ice40 -r -v -l pnrlog.log --up5k --json $(CHIPTOP).json  \
	--placed-svg $(CHIPTOP)-place.svg --routed-svg $(CHIPTOP)-route.svg \
	--package sg48 --asc $(CHIPTOP).asc --opt-timing --pcf $(PCFFILE)
	# Convert to bitstream using IcePack
	icepack $(CHIPTOP).asc $(CHIPTOP).bin

burn:
	# send it to the FPGA
	iceprog ./$(CHIPTOP).bin
	
time:
	# run some basic timing analysis
	icetime -d up5k -p $(IBTFILE) -P sg48 -t -v $(CHIPTOP).asc

clean:
	rm -f *.asc *.bin *.vcd *.vvp $(CHIPTOP)-place.svg $(CHIPTOP)-route.svg pnrlog.log $(CHIPTOP).json
	rm -rf obj_dir *.fst

