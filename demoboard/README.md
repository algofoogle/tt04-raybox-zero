# Testing the t04-raybox-zero ASIC with the TT04 Demo Board

Here you will find information and MicroPython scripts that can be used to test the raybox-zero (TT04 edition) ASIC using the TT04 Demo board, e.g. via the [Tiny Tapeout Commander], and use it for a primitive game demo driven by your computer as the host.

![Demo board connected to VGA display, running raybox-zero on the TT04 ASIC](../doc/raybox-zero-tt04-board.jpg)

> [!NOTE]
> The TT04 version of raybox-zero suffered a synthesis bug, as you can see in the image above. I've [documented this below](#tt04-synthesis-bug).

This is a WIP (Work In Progress).

You can go to https://tinytapeout.com/start/tt04 for high-level instructions on getting started with the TT04 Demo Board.

## Here's my own quick-start guide...

First, wire up a VGA DAC, ideally one that provides at least RGB222 (raybox-zero uses exactly this much). The Digilent PmodVGA is what I have, so I wire it as follows (including )

![PmodVGA wiring for raybox-zero TT04](../doc/vga-wiring.png)

The Tiny VGA PMOD would work just as well. **That too would need to be wired up correctly** because the TT04 version of raybox-zero didn't yet match the Tiny VGA PMOD's direct pinout.

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
10. Optionally turn on ui_in 4 and 5 to see the 'player sliding' animation

## Example test programs

### raybox_game.py

This is a very simple example of a game environment rendered on the raybox-zero TT04 ASIC, but driven by a host PC responding to keyboard/mouse inputs.

NOTE: So far I've only tested this on Windows.

NOTE: This is intended to be used with your monitor in "portrait mode" (i.e. rotated on its side):
*   It is best if you rotate it anti-clockwise, and ensure that `FLIPPED = False` in `raybox_game.py`
*   It also works if you rotate it clockwise, and ensure that `FLIPPED = True` in `raybox_game.py`

To set up and run the game demo:

1.  Requires probably Python 3.10 or above. I've been testing on 3.12.0.
2.  From within the `demoboard` dir, install Python packages: `pip install -r requirements.txt`
3.  Plug in your TT04 demo board via USB (unplug it first if necessary, to reset it).
4.  Run: `python3 ./raybox_game.py`

This will assume your TT04 board's RP2040 USB serial interface is the *last* device listed and attempt to connect to that. Assuming it succeeds, it will then:
*   Talk to MicroPython running on the RP2040 and try to bring it to a known state in "raw mode".
*   Select the `tt_um_algofoogle_raybox_zero` design, clock it at 25MHz, and reset it.
*   Send the contents of `raybox_peripheral.py` for MicroPython to load a basic interface we can send control signals to.
*   Present a UI on the host computer that shows the game map, while the raybox-zero VGA display should show your 3D view.

The 3D view responds live to mouse left/right movements and the WASD keyboard keys for motion.

Other keys:

```
Numpad:
    9: sky_color++
    7: sky_color--
    3: floor_color++
    1: floor_color--

Mousewheel:
    Modifiers (can use any combo):
        - CTRL: x2 
        - SHIFT: x4
        - ALT: x8
    Must hold any of the following on main number row to apply the mousewheel action:
        - 7: leak

Other:
    ESC: Quit
    M or F12: Toggle mouse capture
    R: Reset game state
    `: Toggle vectors debug overlay
    Enter: Reset map preview zoom
```


### tt04-raybox-zero-example.py

[`tt04-raybox-zero-example.py`](./tt04-raybox-zero-example.py) is a slightly older script I was working on that can be run directly in MicroPython to provide more of an API, if you want to muck about with the chip directly.

You can run this example by:

1.  Going to the 'REPL' tab in the Commander (continuing from above).
2.  Pressing CTRL+E to go into "paste" mode.
3.  Copy-pasting the contents of the file above into the REPL -- make sure you use Ctrl+**Shift**+V to paste.
4.  Pressing CTRL+D to then commit/execute the code.

This will show a demo/test loop that:
*   Shows one of 4 pre-defined views, changing very 1 second
*   Do a full revolution
*   Do a slow fine-grained "jiggle" back and forth, for analysis of the [synthesis bug](#tt04-synthesis-bug).

If you like, you can press CTRL+C to interrupt the code, then issue your own updates via the `reg` and `pov` objects, for example:

*   Put the player at a point on map and with a 45-degree rotation:
    ```py
    pov.angular_pov(
        7.0, 9.5,               # Position
        45.0 * math.pi / 180.0  # Rotation in radians
    )
    ```
*   Set the floor colour to dark red by doing: `reg.floor(0b_00_00_01)` (bit pairs are Bb_Gg_Rr).
*   Set the sky colour to 'buff' by doing: `reg.sky(0b_01_10_11)`
*   Set the 'leak' value (floor displacement) by doing: `reg.floor(17)` (range is 0..63)


## TT04 synthesis bug

The TT04 version of raybox-zero suffered a synthesis bug, which was evidently caused by a flawed optimisation step inside the version of OpenLane used by Tiny Tapeout 4 at the time.

*   This leads to calculation errors that I think stem from a big multipler chain inside my reciprocal module approximator.
*   Since that module is used for lots of things (wall distance tracing, wall height calculation, texture scaling), the display has lots of glitches, but it's still possible to work out what the view is meant to be.
*   The reasons we're confident this is a synthesis bug are:
    *   RTL simulation and running on an FPGA don't show the issue, but gate-level simulation seems to recreate the bug perfectly.
    *   Whether running the silicon at 3MHz, 24MHz, or 31.5MHz, the visual artefacts appear to be exactly the same (so not affected by timing).
*   The problem seems to have gone away in some future version of OpenLane (i.e. I don't see the same problem in 3 more recent gate-level simulations I've done), but to be honest I've not checked *exactly* the same raybox-zero code version in those newer OpenLane versions, so I need to check that more carefully at some point.


[Tiny Tapeout Commander]: https://commander.tinytapeout.com/

