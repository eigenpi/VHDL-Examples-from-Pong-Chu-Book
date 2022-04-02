-- cristinel ababei; 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- NOTE: largest Fibonacci number that can be displayed on 6x 7-segment diplay
-- is F(i=30) = 832040; therefore, the user can only input through the slide switches 
-- a request to generate and display up to i_max=30 Fibonacci numbers; to input
-- up to 30, we only need 5 slide switches;
entity top is
  Port ( 
    clk_50MHz : in std_logic; -- clock on DE1-SoC board
    btn_reset: in std_logic; -- KEY0 is reset
    btn_go : in std_logic; -- KEY1 is go
    LED_ready : out std_logic; -- LEDR0
    LED_done_fib : out std_logic; -- LEDR1
    LED_done_bin2bcd : out std_logic; -- LEDR2
    fib_i_numbers : in std_logic_vector(4 downto 0); -- generate first "i" Fibonacci numbers
    fib5 : out std_logic_vector(6 downto 0); -- we can display numbers up to 999999
    fib4 : out std_logic_vector(6 downto 0);
    fib3 : out std_logic_vector(6 downto 0);
    fib2 : out std_logic_vector(6 downto 0);
    fib1 : out std_logic_vector(6 downto 0);
    fib0 : out std_logic_vector(6 downto 0)
  );
end top;


architecture my_structural of top is

  component fib
    port(
      clk, reset: in std_logic;
      start: in std_logic;
      i: in std_logic_vector(4 downto 0);
      ready, done_tick: out std_logic;
      f: out std_logic_vector(19 downto 0);
      f_new: out std_logic
    );
  end component;

  COMPONENT bin2bcd 
    PORT (
      clk: in std_logic;
      reset: in std_logic;
      start: in std_logic;
      bin: in std_logic_vector(19 downto 0);
      ready, done_tick: out std_logic;
      bcd5,bcd4,bcd3,bcd2,bcd1,bcd0: out std_logic_vector(3 downto 0)
    );
  END COMPONENT;
  
  COMPONENT hex_to_sseg
    PORT (
      hex: in std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(6 downto 0)
     );
  END COMPONENT;

  -- Intel ALtera PLL IP
  COMPONENT my_altpll 
	port (
		refclk   : in  std_logic := '0'; 
		rst      : in  std_logic := '0';
		outclk_0 : out std_logic 
	);
  end COMPONENT;

  signal clk_2MHz : std_logic;  
  signal reset : std_logic;
  signal go : std_logic;
  signal fib_ready, fib_done : std_logic;
  signal fib_bin : std_logic_vector(19 downto 0);
  signal fib_bcd5, fib_bcd4, fib_bcd3, fib_bcd2, fib_bcd1, fib_bcd0 : std_logic_vector(3 downto 0); 
  signal bin2bcd_ready, bin2bcd_done, bin2bcd_start : std_logic;

  -- counter for "measuring" 1 second; needed with at least 21 bits
  -- so, it can count up to a maximum number that is larger than 2,000,000 ticks 
  -- of 2MHz clock signal; counting 2,000,000 ticks is the equivalent of
  -- waiting 1 second; we want a new Fibonacci number to be generated and displayed
  -- every 1 second or so; in this way we can see them easily;
  signal n_reg, n_next: unsigned(20 downto 0); 
  constant ONE_SECOND: integer := 2000000;
  signal tick_1sec : std_logic;
  
begin 

  -- (1) clock generation
  Inst_1_clock_pll: my_altpll port map(
    refclk   => clk_50MHz,
		rst      => '0',
		outclk_0 => clk_2MHz
  ); 
  
  -- implement a simple counter to use as an additional 
  -- clock divider; we take the 2 MHz clock and generate a new one
  -- that changes every 2,000,000 ticks - i.e., the equivalent of 1 second;
  process (reset, clk_2MHz) -- state reg;
  begin
    if (reset = '1') then
      n_reg <= (others=>'0');       
    elsif (clk_2MHz'event and clk_2MHz = '1') then
      n_reg <= n_next;
    end if;
  end process;  
  
  process (n_reg) -- next-state logic;
  begin
    tick_1sec <= '0';
    n_next <= n_reg + 1;
    if (n_reg > ONE_SECOND-1) then -- 1 second passed, reset counter n;
      tick_1sec <= '1';
      n_next <= (others=>'0');
    end if;     
  end process; 

  -- (2) push-buttons;
  reset <= not btn_reset; 
  go <= not btn_go;   
  
  -- (3) Fibonacci numbers generator of all "i" Fibonacci numbers 
  Inst_fib_generator: fib port map(
    clk => tick_1sec, 
    reset => reset,
    start => go,
    i => fib_i_numbers,
    ready => LED_ready, 
    done_tick => LED_done_fib,
    f => fib_bin,
    f_new => bin2bcd_start
  );

  -- (4) convert Fibonacci binary value to BCD format on 6 digits
  Inst_bin2bcd: bin2bcd port map(
    clk => clk_2MHz,
    reset => reset,
    start => bin2bcd_start,
    bin => fib_bin, -- input binary value to be converted;
    ready => bin2bcd_ready, -- ready for new conversion; left disconnected;
    done_tick => LED_done_bin2bcd, -- conversion done;
    bcd5 => fib_bcd5,
    bcd4 => fib_bcd4,
    bcd3 => fib_bcd3,
    bcd2 => fib_bcd2,
    bcd1 => fib_bcd1,
    bcd0 => fib_bcd0
  );
  
  -- (5) decode six BCD digits into signals needed to drive 7-segment 
  -- LED displays of DE1-SoC board
  Inst_hex_to_sseg_5: hex_to_sseg port map(
    hex => fib_bcd5,
    sseg => fib5
  );
  Inst_hex_to_sseg_4: hex_to_sseg port map(
    hex => fib_bcd4,
    sseg => fib4
  );
  Inst_hex_to_sseg_3: hex_to_sseg port map(
    hex => fib_bcd3,
    sseg => fib3
  );
  Inst_hex_to_sseg_2: hex_to_sseg port map(
    hex => fib_bcd2,
    sseg => fib2
  );
  Inst_hex_to_sseg_1: hex_to_sseg port map(
    hex => fib_bcd1,
    sseg => fib1
  );
  Inst_hex_to_sseg_0: hex_to_sseg port map(
    hex => fib_bcd0,
    sseg => fib0
  );
 
end my_structural;