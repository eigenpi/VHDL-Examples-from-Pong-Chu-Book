-- cristinel.ababei
-- this is the main clock-counter that implements the clock
-- functionality; it simply counts seconds, minutes, and hours;
-- it also has a "setup mode" when the user can set seconds, minutes, 
-- and hour;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity clock_counter is
  port(
    -- 2MHz main clock; ideally would have been 1MHz, but, the ALTPLL can generate exactly 2MHz 
    -- only from the 50MHz clock signal from the DE1-SoC board's clock
    clk: in std_logic; 
    reset: in std_logic;
    setup_mode: in std_logic;
    set_hour: in std_logic;
    set_minutes: in std_logic;
    set_seconds: in std_logic;
    hour, minutes, seconds: out std_logic_vector(5 downto 0);
    hour_change, minutes_change, seconds_change: out std_logic
  );
end clock_counter;


architecture arch of clock_counter is

  COMPONENT edge_detect
    PORT(
      clk, reset: in std_logic;
      level: in std_logic;
      tick: out std_logic
    );
  END COMPONENT;

  -- states of the finite state machine;
  type state_type is (NORMAL_OPERATION, SET_TIME_MODE); 
  signal state_next, state_reg: state_type;
  signal hour_next, minutes_next, seconds_next: unsigned(5 downto 0);
  signal hour_reg, minutes_reg, seconds_reg: unsigned(5 downto 0);
  signal set_hour_tick, set_minutes_tick, set_seconds_tick : std_logic;
  signal hour_ch_next, minutes_ch_next, seconds_ch_next: std_logic;
  signal hour_ch_reg, minutes_ch_reg, seconds_ch_reg: std_logic;
  -- counter for "measuring" one second; needed with at least 21 bits
  -- so, it can count up to a maximum number that is larger than 200000 ticks 
  -- of 2MHz clock signal;
  signal n_reg, n_next: unsigned(20 downto 0); 
  constant ONE_SECOND: integer := 2000000;
  
begin
  -- edge detection circuit instances, which detect rising edges on
  -- setting push buttons; 
  Inst_edge_detect_set_seconds: edge_detect PORT MAP(
    clk => clk,
    reset => reset, 
    level => set_seconds,
    tick => set_seconds_tick
  );  
  Inst_edge_detect_set_minutes: edge_detect PORT MAP(
    clk => clk,
    reset => reset, 
    level => set_minutes,
    tick => set_minutes_tick
  ); 
  Inst_edge_detect_set_hour: edge_detect PORT MAP(
    clk => clk,
    reset => reset, 
    level => set_hour,
    tick => set_hour_tick
  ); 
  
  -- state registers;
  process (reset, clk)
  begin
    if (reset = '1') then
      n_reg <= (others=>'0'); 
      hour_reg <= (others=>'0');
      minutes_reg <= (others=>'0');
      seconds_reg <= (others=>'0');
      hour_ch_reg <= '0';
      minutes_ch_reg <= '0';
      seconds_ch_reg <= '0';
      if (setup_mode = '1') then
        state_reg <= SET_TIME_MODE;
      else 
        state_reg <= NORMAL_OPERATION;
      end if;      
    elsif (clk'event and clk = '1') then
      n_reg <= n_next;
      state_reg <= state_next;
      hour_reg <= hour_next;
      minutes_reg <= minutes_next;
      seconds_reg <= seconds_next;
      hour_ch_reg <= hour_ch_next;
      minutes_ch_reg <= minutes_ch_next;
      seconds_ch_reg <= seconds_ch_next;
    end if;
  end process;
  
  
  -- next-state logic and data path operations;
  process (setup_mode, n_reg, state_reg, hour_reg, minutes_reg, seconds_reg, set_seconds_tick, set_minutes_tick, set_hour_tick)
  begin
    state_next <= state_reg;
    hour_next <= hour_reg;
    minutes_next <= minutes_reg;
    seconds_next <= seconds_reg;
    
    seconds_ch_next <= '0';
    minutes_ch_next <= '0';
    hour_ch_next <= '0';
    
    case state_reg is         
      when NORMAL_OPERATION =>     
        if (setup_mode = '1') then
          state_next <= SET_TIME_MODE;
        else 
          state_next <= NORMAL_OPERATION;
          
          if (n_reg < ONE_SECOND) then
            n_next <= n_reg + 1;
          else
            n_next <= (others=>'0');
            seconds_ch_next <= '1';
            -- check if we have counted 60 seconds;
            if (seconds_reg < 59) then 
              seconds_next <= seconds_reg + 1;
            else 
              seconds_next <= (others=>'0'); 
              minutes_ch_next <= '1';
              -- check if we have counted 60 minutes; 
              if (minutes_reg < 59) then 
                minutes_next <= minutes_reg + 1;
              else
                minutes_next <= (others=>'0'); 
                hour_ch_next <= '1'; 
                -- check if we have counted 12 hours; 
                if (hour_reg < 11) then
                  hour_next <= hour_reg + 1;  
                else
                  hour_next <= "000001";
                end if;
              end if;
            end if;
          end if;
        end if;
        
      when SET_TIME_MODE => 
        if (setup_mode = '1') then
          state_next <= SET_TIME_MODE;
          if (set_seconds_tick = '1') then 
            seconds_ch_next <= '1';
            if (seconds_reg < 59) then 
              seconds_next <= seconds_reg + 1;
            else
              seconds_next <= (others=>'0');
            end if;
          end if;
          if (set_minutes_tick = '1') then 
            minutes_ch_next <= '1';
            if (minutes_reg < 59) then 
              minutes_next <= minutes_reg + 1;
            else
              minutes_next <= (others=>'0');
            end if;
          end if;
          if (set_hour_tick = '1') then 
            hour_ch_next <= '1'; 
            if (hour_reg < 12) then 
              hour_next <= hour_reg + 1;
            else
              hour_next <= "000001";
            end if;            
          end if;
        else 
          state_next <= NORMAL_OPERATION;
        end if;     
    end case;
  end process;

  -- drive outputs of this entity using the register signals;
  hour <= std_logic_vector(hour_reg);
  minutes <= std_logic_vector(minutes_reg);
  seconds <= std_logic_vector(seconds_reg);

  hour_change <= hour_ch_reg;
  minutes_change <= minutes_ch_reg;
  seconds_change <= seconds_ch_reg;   
end arch;
