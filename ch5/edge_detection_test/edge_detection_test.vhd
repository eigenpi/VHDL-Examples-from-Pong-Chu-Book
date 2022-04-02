-- cristinel.ababei
-- this is an edge detection circuit that detects rising edge of an
-- input signal; it generates a short pulse that is used to drive
-- and LED on DE1-SoC board;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;


entity edge_detection_test is
	port(
    clk_50 : in std_logic; -- connected to 50 MHz clock pin of FPGA;
    btn_reset : in std_logic;
    btn_level : in std_logic;
    tick : out std_logic -- drive LEDR0 on board;
  );
end edge_detection_test;


architecture my_structural of edge_detection_test is

component edge_detect is
  port (
    clk, reset: in std_logic;
    level: in std_logic;
    tick: out std_logic
  );
end component;

component clk_divider is
  port ( 
    CLK_IN : in STD_LOGIC;
    CLK_OUT : out STD_LOGIC
  );
end component;

signal clk : std_logic; -- internal clock of about 1-3 seconds;
signal level : std_logic; -- push button KEY1
signal reset : std_logic; -- push button KEY0

begin

reset <= not btn_reset;
level <= not btn_level;

clock_divider_inst : clk_divider port map (clk_50, clk);
edge_detect_inst : edge_detect port map (clk, reset, level, tick);

end my_structural;
