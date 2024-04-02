# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info
# This Makefile is specifically for running cocotb tests.
# If you run just 'make', it is expected to run src/test/test.py.
# You should also be able to do GL test:
#   cp ../runs/wokwi/results/final/verilog/gl/tt_um_algofoogle_raybox_zero.v test/gate_level_netlist.v
#   make -B GATES=yes

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += \
	$(PWD)/test/tb.v \
	$(PWD)/raybox-zero/src/rtl/fixed_point_params.v	\
	$(PWD)/raybox-zero/src/rtl/helpers.v			\
	$(PWD)/raybox-zero/src/rtl/debug_overlay.v		\
	$(PWD)/raybox-zero/src/rtl/lzc.v				\
	$(PWD)/raybox-zero/src/rtl/map_overlay.v		\
	$(PWD)/raybox-zero/src/rtl/map_rom.v			\
	$(PWD)/raybox-zero/src/rtl/pov.v				\
	$(PWD)/raybox-zero/src/rtl/reciprocal.v			\
	$(PWD)/raybox-zero/src/rtl/row_render.v			\
	$(PWD)/raybox-zero/src/rtl/spi_registers.v		\
	$(PWD)/raybox-zero/src/rtl/vga_mux.v			\
	$(PWD)/raybox-zero/src/rtl/vga_sync.v			\
	$(PWD)/raybox-zero/src/rtl/wall_tracer.v		\
	$(PWD)/raybox-zero/src/rtl/rbzero.v				\
	$(PWD)/top.v

COMPILE_ARGS += -I $(PWD)/raybox-zero/src/rtl

VERILOG_INCLUDE_DIRS += \
	$(PWD)/raybox-zero/src/rtl

# TOPLEVEL is the name of the toplevel (testbench) module in your Verilog (typically test/tb.v file):
TOPLEVEL = tb

# See: https://github.com/cocotb/cocotb/discussions/2928
# Allows us to find .py test files in the src/test/ directory:
export PYTHONPATH := ./test

# MODULE is the basename of the Python test file (i.e. typically from test/test.py):
MODULE = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

anton:
	echo $(VERILOG_INCLUDE_DIRS)

show:
	gtkwave tb.vcd utils/tb.gtkw utils/gtkwave.ini
