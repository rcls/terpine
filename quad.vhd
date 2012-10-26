-- Drive 4 instances of cycle.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity quad is
  port (R : out word_t;
        Din : in word_t;
        phase_advance : in std_logic;
        load0 : in std_logic;
        load1 : in std_logic;
        load2 : in std_logic;
        load3 : in std_logic;
        clk : in std_logic);
end quad;

architecture quad of quad is
  attribute keep_hierarchy : string;
  attribute keep_hierarchy of quad : architecture is "soft";
  signal phase : natural range 0 to 3;
  signal r0 : word_t;
  signal r1 : word_t;
  signal r2 : word_t;
  signal r3 : word_t;
  signal pa : std_logic;
  signal ld0 : std_logic;
  signal ld1 : std_logic;
  signal ld2 : std_logic;
  signal ld3 : std_logic;
begin
  c0 : entity work.cycle generic map (3) port map (r0, Din, ld0, pa, clk);
  c1 : entity work.cycle generic map (2) port map (r1, Din, ld1, pa, clk);
  c2 : entity work.cycle generic map (1) port map (r2, Din, ld2, pa, clk);
  c3 : entity work.cycle generic map (0) port map (r3, Din, ld3, pa, clk);

  process
  begin
    wait until rising_edge(clk);
    pa <= phase_advance;
    ld0 <= load0;
    ld1 <= load1;
    ld2 <= load2;
    ld3 <= load3;

    if pa = '1' then
      if ld0 = '1' or phase = 3 then
        phase <= 0;
      else
        phase <= phase + 1;
      end if;
    end if;
    case phase is
      when 0 => R <= r0;
      when 1 => R <= r1;
      when 2 => R <= r2;
      when 3 => R <= r3;
    end case;
  end process;
end quad;
