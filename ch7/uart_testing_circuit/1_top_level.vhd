-- cristinel ababei
-- this is a simple design entity that uses a UART transceiver to 
-- to receive and loop-back (send-back) to host PC characters received 
-- via RS232 of the <<< DE1-SoC >>> board; received bytes are first incremented and
-- then sent back; in addition, this is controlled with the KEY1 push button;
-- KEY0 pushbutton is used as reset; also, we drive 8 LEDs too to show what
-- we received; on host PC we use a <<< Termite >>> terminal (could use Putty too);
-- tx_full and rx_empty signals are connected to the two horizontal bars of the 
-- left-most digit of the seven-segment display;
--
-- NOTES: 
--
-- this is basically the example from fig.7.6 of the following textbook:
-- P.P. Chu, FPGA Prototyping by VHDL Examples: Xilinx Spartan-3 Version, Wiley 2008.
--
-- IMPORTANT THINGS:
--
-- (1) Connections of the USB-2-UART converter to GPIO_0 pins:
-- Use 4 pins from GPIO_0 for: TX, RX and VCC, GND 
-- Look at the "schematic diagram" of DE1-SoC board to see exactly, which ones these are!
--                            ...
--                    VCC---|-o o-|---GND 
--                          | o o | 
--                          | o o | 
--                          | o o | 
--                          | o o |    
-- PIN_AG18 (GPIO_0 [34])---|-o o-|---PIN_AJ21 (GPIO_0 [35])
-- "rx" of top-level         -----    "tx" of top-level
-- connects to "TX" of                connects to "RX" of
-- USB-2-UART converter!              USB-2-UART converter!
--
-- (2) Baudrate
-- this VHDL code uses a hard coded baudrate of 19200;
-- so, make sure you set that iside your Termite terminal!
--
-- (3) Clock - my_altpll is used as a clock repeater only;
-- I use KEY0 push button as reset
-- I use KEY1 as send back 


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity uart_test_impl1 is
    port(
        clk_i: in std_logic; -- 50 MHz from off-chip oscillator;
        btn_reset: in std_logic;
        btn_send_back: in std_logic;
        rx: in std_logic;
        tx: out std_logic;
        LEDG: out std_logic_vector(7 downto 0);
        seven_seg: out std_logic_vector(7 downto 0)
    );
end uart_test_impl1;


architecture arch of uart_test_impl1 is

    -- DE1-SoC board;
    COMPONENT my_altpll 
    port (
        refclk   : in  std_logic := '0'; --  refclk.clk
        rst      : in  std_logic := '0'; --   reset.reset
        outclk_0 : out std_logic         -- outclk0.clk
    );
    end COMPONENT;

    signal tx_full, rx_empty: std_logic;
    signal rec_data: std_logic_vector(7 downto 0);
    -- data that we send back is received data, rec_data, that we simply increment;  
    signal send_back_data: std_logic_vector(7 downto 0);  
    signal clk_50: std_logic; 
    signal top_level_reset: std_logic;
    signal top_level_send_back, send_back_db: std_logic;
   
begin

    -- take the inverted push button because KEY# on board generates
    -- a signal 111000111; with 1 with not pressed and 0 when pressed/pushed;
    top_level_reset <= not btn_reset;
    top_level_send_back <= not btn_send_back;


    -- instantiate PLL, which takes 50 MHz from off chip oscillator and generates
    -- 50 MHz; does not change anything;
    inst_system_clock_pll: my_altpll PORT MAP(
        refclk => clk_i,
        rst => '0',
        outclk_0 => clk_50
    );

    -- instantiate UART;
    -- Note: clk_50 is very important here; read comments inside 2_uart.vhd
    -- to see why; we work here with baudrate of 19200; 
    uart_unit: entity work.uart(str_arch) port map(
        clk=>clk_50, 
        reset=>top_level_reset, 
        rd_uart=>send_back_db,
        wr_uart=>send_back_db, 
        rx=>rx,
        w_data=>send_back_data,
        tx_full=>tx_full, 
        rx_empty=>rx_empty,
        r_data=>rec_data, 
        tx=>tx
    );

    -- instantiate debounce circuit for the KEY1 pushbutton used
    -- to control sending back incremented received data;
    -- Note: this is not necessary because the pushbuttons on board are
    -- already debounced!?
    btn_send_back_db_unit: entity work.debounce(fsmd_arch) port map(
        clk=>clk_50, 
        sw=>top_level_send_back,
        db_level=>open, 
        db_tick=>send_back_db
    );

    -- incremented data, which we loop back;
    send_back_data <= std_logic_vector(unsigned(rec_data)+1);

    -- led display;
    LEDG <= rec_data;

    -- drive seven segment display;
    seven_seg <= '1' & (not tx_full) & "11" & (not rx_empty) & "111";

end arch;
