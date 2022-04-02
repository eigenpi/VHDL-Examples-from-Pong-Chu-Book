--Listing 4.19 
-- Modified:
-- Removed disp_hex_mux because the DE1_SoC board has 7-segment LED displays
-- wired individually to separte pins of the FPGA chip
-- Added additional output ports to top-level design entity to accont for all
-- 7-segment displays

library ieee;
use ieee.std_logic_1164.all;

entity stop_watch_test is
   port(
      clk: in std_logic;                      -- 50MHz from on-board crystal osc.
      btn: in std_logic_vector(1 downto 0);   -- KEY0 for clr, KEY1 for go
      HEX0: out std_logic_vector(7 downto 0); -- drives 1st, right-hand side, 7-segment LED display 
      HEX1: out std_logic_vector(7 downto 0); -- drives 2nd sseg display
      HEX2: out std_logic_vector(7 downto 0)  -- drives 3rd sseg display
   );
end stop_watch_test;

architecture arch of stop_watch_test is
   signal d2, d1, d0: std_logic_vector(3 downto 0);
   
begin
  -- instantiate stop-watch design entity;
  watch_unit: entity work.stop_watch(cascade_arch)
     port map(
        clk => clk, 
        go  => not btn(1), 
        clr => not btn(0),
        d2  => d2, 
        d1  => d1, 
        d0  => d0 );
        
  -- instantiate four instances of hex decoders (from Listing 3.12)
  -- NOTE: dp is not active/connected on DE1-SoC
  sseg_unit_0: entity work.hex_to_sseg
    port map(hex=>d0, dp =>'0', sseg=>HEX0);

  sseg_unit_1: entity work.hex_to_sseg
    port map(hex=>d1, dp =>'0', sseg=>HEX1);

  sseg_unit_2: entity work.hex_to_sseg
    port map(hex=>d2, dp =>'0', sseg=>HEX2);
end arch;