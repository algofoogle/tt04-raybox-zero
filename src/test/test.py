import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles

CLOCK_PERIOD = 40.0 # ns
HIGH_RES = None #10.0 # If not None, scale H res by this, and step by CLOCK_PERIOD/HIGH_RES instead of unit clock cycles.


# Make sure all bidir pins are configured as outputs
# (as they should always be, for this design):
def check_uio_out(dut):
    assert dut.uio_oe.value == 0b00000011

# This can represent hard-wired stuff:
def set_default_start_state(dut):
    dut.ena.value = 1
    # POV SPI interface inactive:
    dut.pov_sclk.value = 1
    dut.pov_mosi.value = 1
    dut.pov_ss_n.value = 1
    # REG SPI interface also inactive:
    dut.reg_sclk.value = 1
    dut.reg_mosi.value = 1
    dut.reg_ss_n.value = 1
    # Enable debug display on-screen:
    dut.debug.value = 1
    # Enable demo mode (player position auto-increment):
    dut.inc_px.value = 1
    dut.inc_py.value = 1
    # Present UNregistered outputs:
    dut.registered_outputs.value = 0

@cocotb.test()
async def test_basic_waveform_dump(dut):
    """
    Just start a clock, apply reset, and let the design free-run for 500,000 cycles;
    enough to generate at least 1 full VGA frame and dump to VCD
    """

    dut._log.info("Starting test_basic_waveform_dump...")

    set_default_start_state(dut)
    # Start with reset released:
    dut.rst_n.value = 1

    # 40ns clock (25MHz):
    clock = Clock(dut.clk, CLOCK_PERIOD, units='ns').start()
    cocotb.start_soon(clock)

    # Wait 3 clocks...
    await ClockCycles(dut.clk, 3)
    check_uio_out(dut)
    dut._log.info("Assert reset...")
    # ...then assert reset:
    dut.rst_n.value = 0
    # ...and wait another 3 clocks...
    await ClockCycles(dut.clk, 3)
    check_uio_out(dut)
    dut._log.info("Release reset...")
    # ...then release reset:
    dut.rst_n.value = 1

    # Run the design for 1 line...
    dut._log.info("Line #0...")
    await ClockCycles(dut.clk, 800)
    check_uio_out(dut)

    # ...and another 10 lines...
    dut._log.info("Lines #1..10...")
    await ClockCycles(dut.clk, 10*800)
    check_uio_out(dut)

    # ...then the rest of the frame (525-11 lines)...
    dut._log.info("Lines #11..524...")
    await ClockCycles(dut.clk, 514*800)
    check_uio_out(dut)

    # ...and then a few more of the next frame, to total 500,000 cycles since we came out of reset:
    dut._log.info("100 more lines...")
    await ClockCycles(dut.clk, 100*800)
    check_uio_out(dut)
    dut._log.info("Test finished")

@cocotb.test()
async def test_frames(dut):
    """
    Generate first video frame and write it to rbz_basic_frames.ppm
    """

    dut._log.info("Starting test_frames...")

    frame_count = 4 # No. of frames to render in the one output image.
    hrange = 800
    vrange = 525*frame_count #NOTE: Can multiply this by number of frames desired.
    hres = HIGH_RES or 1

    print("Rendering first full frame...")

    set_default_start_state(dut)
    # Start with reset released:
    dut.rst_n.value = 1

    clk = Clock(dut.clk, CLOCK_PERIOD, units="ns")
    cocotb.start_soon(clk.start())

    # Wait 3 clocks...
    await ClockCycles(dut.clk, 3)
    check_uio_out(dut)
    dut._log.info("Assert reset...")
    # ...then assert reset:
    dut.rst_n.value = 0
    # ...and wait another 3 clocks...
    await ClockCycles(dut.clk, 3)
    check_uio_out(dut)
    dut._log.info("Release reset...")
    # ...then release reset:
    dut.rst_n.value = 1

    # Create PPM file to visualise the frame, and write its header:
    img = open("rbz_basic_frames.ppm", "w")
    img.write("P3\n")
    img.write(f"{int(hrange*hres)} {vrange:d}\n")
    img.write("255\n")

    for n in range(vrange): # 525 lines * however many frames in frame_count
        print(f"Rendering line {n} of {vrange}")
        for n in range(int(hrange*hres)): # 800 pixel clocks per line.
            if n % 100 == 0:
                print('.', end='')
            if 'x' in dut.rgb.value.binstr:
                # Output is unknown; make it green:
                r = 0
                g = 255
                b = 0
            else:
                rr = dut.rr.value
                gg = dut.gg.value
                bb = dut.bb.value
                hsyncb = 255 if dut.hsync_n.value.binstr=='x' else (0==dut.hsync_n.value)*0b110000
                vsyncb = 128 if dut.vsync_n.value.binstr=='x' else (0==dut.vsync_n.value)*0b110000
                r = (rr << 6) | hsyncb
                g = (gg << 6) | vsyncb
                b = (bb << 6)
            img.write(f"{r} {g} {b}\n")
            if HIGH_RES is None:
                await ClockCycles(dut.clk, 1) 
            else:
                await Timer(CLOCK_PERIOD/hres, units='ns')
    print("Waiting 1 more clock, for start of next line...")
    await ClockCycles(dut.clk, 1)
    img.close()
    print("DONE")
