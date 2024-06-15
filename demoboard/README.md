# Testing the t04-raybox-zero ASIC with the TT04 Demo Board

Here you will find information and MicroPython scripts that can be used to test the raybox-zero (TT04 edition) ASIC using the TT04 Demo board, e.g. via the [Tiny Tapeout Commander].

![Demo board connected to VGA display, running raybox-zero on the TT04 ASIC](../doc/raybox-zero-tt04-board.jpg)

This is a WIP (Work In Progress).

You can go to https://tinytapeout.com/start/tt04 for high-level instructions on getting started with the TT04 Demo Board.

## Here's my own quick-start guide...

First, wire up a VGA DAC, such as the Digilent PmodVGA:

![PmodVGA wiring for raybox-zero TT04](../doc/vga-wiring.png)

Then...

1.  Plug in the TT04 Demo Board via USB.
2.  Go to the [Tiny Tapeout Commander]
3.  Click 'CONNECT TO BOARD'
4.  Select your board from the window that pops up and click 'Connect'
5.  On the 'CONFIG' tab, go to the 'Index' field and type in 33 and/or select 'Project' `raybox-zero (33)`
6.  Click 'SELECT'
7.  Set the clock speed preset to (say) 25.179 MHz and click 'SET'
8.  Go to the 'INTERACT' tab, tick 'ui_in' and make sure '3' is clicked on
9.  If necessary, click 'RESET'


## Example test programs

I'm going to work on more MicroPython code for the RP2040 on the Demo Board, but for now I've got this one script as an example:

[`tt04-raybox-zero-api.py`](./tt04-raybox-zero-api.py)

You can run this example by:

1.  Going to the 'REPL' tab in the Commander (continuing from above).
2.  Pressing CTRL+E to go into "paste" mode.
3.  Copy-pasting the contents of the file above into the REPL -- make sure you use Ctrl+**Shift**+V to paste.
4.  Pressing CTRL+D to then commit/execute the code.

This will show one of 4 views, changing very 1 second.


[Tiny Tapeout Commander]: https://commander.tinytapeout.com/
