# Project setup
PROJ      = ChipShell
PCFFILE	  = icebreaker.pcf
IBTFILE	  = icebreakertiming.pcf
DEVICE    = 5k

# Files
FILES = ChipShell.v	timerflags.v SegmentDisplayer.v

.PHONY: lint simulate build clean burn time

lint:
	# first compile with icarus (generates LINT and simulation executable)
	# files used in model are in systemfiles.vf
	iverilog -o sim.vvp -f systemfiles.vf

simulate:
	# first compile with icarus (generates LINT and simulation executable)
	# files used in model are in systemfiles.vf
	iverilog -o sim.vvp -f systemfiles.vf
	# Run the simulation executable
	vvp sim.vvp
	# View waveform results
	gtkwave ctest.vcd

build:
	# synthesize using Yosys
	yosys -p "synth_ice40 -top $(PROJ) -json $(PROJ).json" $(FILES)
	# Place and route using nextpnr
	nextpnr-ice40 -r -v -l pnrlog.log --up5k --json $(PROJ).json  \
	--placed-svg $(PROJ)-place.svg --routed-svg $(PROJ)-route.svg \
	--package sg48 --asc $(PROJ).asc --opt-timing --pcf $(PCFFILE)
	# Convert to bitstream using IcePack
	icepack $(PROJ).asc $(PROJ).bin

burn:
	# send it to the FPGA
	iceprog ./ChipShell.bin
	
time:
	# run some basic timing analysis
	icetime -d up5k -p $(IBTFILE) -P sg48 -t -v ChipShell.asc

clean:
	rm *.asc *.bin *.vcd *.vvp rm $(PROJ)-place.svg $(PROJ)-route.svg pnrlog.log $(PROJ).json
