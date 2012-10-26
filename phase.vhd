-- Generate the phase signals for cycle.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

library UNISIM;
use UNISIM.VComponents.all;

entity phase is
  port (phase_advance : out std_logic;
        load0 : out std_logic;
        load1 : out std_logic;
        load2 : out std_logic;
        load3 : out std_logic;
        clk : in std_logic);
end phase;

architecture behavioral of phase is
  signal pa : std_logic;
  signal ld0 : std_logic;
  signal ld1 : std_logic;
  signal ld2 : std_logic;
  signal ld3 : std_logic;
  signal count : natural range 0 to 19;
  signal phase : natural range 0 to 3;

  function b_to_l (b : boolean) return std_logic is
  begin -- god vhdl sucks.
    if b then return '1'; else return '0'; end if;
  end b_to_l;
begin
  --l0 : bufg port map (i=> ld0, o=> load0);
  --l1 : bufg port map (i=> ld1, o=> load1);
  --l2 : bufg port map (i=> ld2, o=> load2);
  --l3 : bufg port map (i=> ld3, o=> load3);

  --p_a : bufg port map (i=>pa, o=> phase_advance);
  load0 <= ld0;
  load1 <= ld1;
  load2 <= ld2;
  load3 <= ld3;
  phase_advance <= pa;

  process
  begin
    wait until rising_edge(clk);
    if count = 19 then
      count <= 0;
      phase <= (phase + 1) mod 4;
    else
      count <= count + 1;
    end if;

    pa <= b_to_l(count = 1);
    ld0 <= b_to_l(phase = 0 and count < 16);
    ld1 <= b_to_l(phase = 1 and count < 16);
    ld2 <= b_to_l(phase = 2 and count < 16);
    ld3 <= b_to_l(phase = 3 and count < 16);
  end process;
end behavioral;
