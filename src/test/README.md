# `src/test/`: Files supporting basic cocotb automated tests

This is inspired by: https://github.com/algofoogle/tt05-vga-spi-rom/tree/main/src/test

I created this `test/` dir during [0197](https://github.com/algofoogle/journal/blob/master/0197-2024-04-02.md) to try working towards GL tests.

**To actually run the tests,** go to the parent directory (i.e. `src/`, where the `Makefile` is) and run `make`. I kept it in there because this seemed to be the convention for Tiny Tapeout projects (at least for TT05), and the original standard `test` GitHub Action (e.g. [this](https://github.com/algofoogle/tt05-vga-spi-rom/blob/main/.github/workflows/test.yaml)) tries to do just this.

## More information

```bash
which cocotb # => NONE

which cocotb-config 
# => /home/zerotoasic/.local/bin/cocotb-config
# Possibly specifically installed as part of the MPW8 VM, or
# as part of oss-cad-suite



```
