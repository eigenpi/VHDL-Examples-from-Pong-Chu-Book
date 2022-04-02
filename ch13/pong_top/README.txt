cristinel.ababei

This is the Pong Game described in Chapters 12 & 13 of the  textbook:
[1] Pong P. Chu, FPGA Prototyping by VHDL Examples, Wiley, 2008.
adapted to be run on the DE1-SoC board.


To set-up the game:
--Compile the project with Quartus Prime (it is already done)
--Attach a VGA monitor (640x480) to the DE1-SoC board
--Program the DE1-SoC board
--Play!


Controls:
--Reset: SW(9)
--Control paddle up and down: KEY0, KEY1
--Color map selection: SW(3:0) 
--Color map inversion: SW(4)


NOTES:
The VHDL code is almost entirely the same as in the textbook. A few adaptations include:
--The top level entity was changed to add a few more output ports,
including vga_blank, vga_sync (needed for DE1-SoC)
--A new out port red_led was added to drive LEDR(9) on the board
with a signal of about 1 Hz derived from the clock signal of 50 MHz
with the help of a new component, a clock divider
--An Altera PLL IP was included as a new component to serve as a buffer/repeater
for the 50 MHz clock signal we get from the on-board crystal quartz oscillator
--The color mapper component was added to be able to set different colors


ASSIGNMENT:
Change the game to make it a two player game! 