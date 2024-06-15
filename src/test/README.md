# `src/test/`: Files supporting basic cocotb automated tests

This is inspired by: https://github.com/algofoogle/tt05-vga-spi-rom/tree/main/src/test

I created this `test/` dir during [0197](https://github.com/algofoogle/journal/blob/master/0197-2024-04-02.md) to try working towards GL tests.

**To actually run the tests,** go to the parent directory (i.e. `src/`, where the `Makefile` is) and run `make`. I kept it in there because this seemed to be the convention for Tiny Tapeout projects (at least for TT05), and the original standard `test` GitHub Action (e.g. [this](https://github.com/algofoogle/tt05-vga-spi-rom/blob/main/.github/workflows/test.yaml)) tries to do just this.

## More information

Make sure you are in the root dir of this repo. Then...

1.  I made sure [I was set up for doing synthesis locally](https://github.com/algofoogle/journal/blob/master/0197-2024-04-02.md#instructions-for-doing-synth-locally). **A key step** is:
    ```bash
    source ~/tt@tt04/venv/bin/activate
    pip install -r tt/requirements.txt
    ```
2.  Then, with my venv loaded, I also did `pip install -r requirements.txt` from the root of my repo, which makes sure other parts of cocotb are installed (if not already; `pygpi` is an example). **NOTE:** This seems to install cocotb 1.8.1, **despite it reporting 1.7.2 below**.
3.  I checked my cocotb env:
    ```bash
    which cocotb # => NONE

    which cocotb-config 
    # => /home/zerotoasic/.local/bin/cocotb-config
    #NOTE: This is possibly specifically installed as part of the MPW8 VM, or
    # as part of oss-cad-suite

    cocotb-config --version
    # => 1.7.2
    ```
4.  I was then able to run my RTL tests as follows:
    ```bash
    cd src
    make clean
    make
    ```
    ...which includes producing the image `rbz_basic_frames.ppm`
5.  Display frames render: `xdg-open rbz_basic_frames.ppm`
6.  Show `tb.vcd`: `make show`

In short, here's what I was able to do on my MPW8 VM that is already set up with `~/tt@tt04`:

```bash
cd ~/anton/bringup-tt04-raybox-zero
git checkout 1.0-test
source ~/tt@tt04/venv/bin/activate
pip install -r tt/requirements.txt
pip install -r requirements.txt
cd src
make clean
make
xdg-open rbz_basic_frames.ppm
make show # Show VCD.
```

