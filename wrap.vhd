library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity wrap is
  port (R_io : out word_t;
        Din_io : in word_t;
        clk : in std_logic);
end wrap;

architecture behaviour of wrap is
  signal R : word_t;
  signal Din : word_t;
  signal load0 : std_logic;
  signal load1 : std_logic;
  signal load2 : std_logic;
  signal load3 : std_logic;
  signal phase_advance : std_logic;
begin
  p : entity work.phase port map (
    phase_advance, load0, load1, load2, load3, clk);
  q : entity work.quad port map (
    R, Din, phase_advance, load0, load1, load2, load3, clk);
  Din <= Din_io;
  R_io <= R;
end behaviour;
