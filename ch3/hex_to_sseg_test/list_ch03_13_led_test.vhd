-- Listing 3.13
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hex_to_sseg_test is
   port(
      sw: in std_logic_vector(7 downto 0);
      HEX0: out std_logic_vector(7 downto 0);
      HEX1: out std_logic_vector(7 downto 0);
      HEX2: out std_logic_vector(7 downto 0);
      HEX3: out std_logic_vector(7 downto 0)
   );
end hex_to_sseg_test;

architecture arch of hex_to_sseg_test is
   signal inc: std_logic_vector(7 downto 0);
begin
   -- increment input
   inc <= std_logic_vector(unsigned(sw) + 1);

   -- instantiate four instances of hex decoders
   -- instance for 4 LSBs of input
   sseg_unit_0: entity work.hex_to_sseg
      port map(hex=>sw(3 downto 0), dp =>'0', sseg=>HEX0);
   -- instance for 4 MSBs of input
   sseg_unit_1: entity work.hex_to_sseg
      port map(hex=>sw(7 downto 4), dp =>'0', sseg=>HEX1);
   -- instance for 4 LSBs of incremented value
   sseg_unit_2: entity work.hex_to_sseg
      port map(hex=>inc(3 downto 0), dp =>'1', sseg=>HEX2);
   -- instance for 4 MSBs of incremented value
   sseg_unit_3: entity work.hex_to_sseg
      port map(hex=>inc(7 downto 4), dp =>'1', sseg=>HEX3);
end arch;