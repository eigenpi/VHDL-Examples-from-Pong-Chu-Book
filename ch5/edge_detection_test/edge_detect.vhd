--Listing 5.4
library ieee;
use ieee.std_logic_1164.all;

entity edge_detect is
  port(
    clk, reset: in std_logic;
    level: in std_logic;
    tick: out std_logic
  );
end edge_detect;

architecture MEALY_ARCHITECTURE of edge_detect is

	type state_type is (S0, S1);
	signal state_current, state_next : state_type;
	
	begin
  
		-- state register; process #1
		process (clk , reset)
		begin
			if (reset = '1') then 
				state_current <= S0;
			elsif (clk' event and clk = '1') then 
				state_current <= state_next;
			end if;
	  end process;
    
		-- next state and output logic; process #2
		process (state_current, level)
		begin
			state_next <= state_current;
			tick <= '0';
			case state_current is 
				when S0 =>
					if level = '1' then
						state_next <= S1;
						tick <= '1';
					end if;
				when S1 =>
					if level = '0' then
						state_next <= S0;
					end if;
			end case;
		end process;
end MEALY_ARCHITECTURE;	
