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
  signal loadA : std_logic;
  signal loadB : std_logic;
  signal loadC : std_logic;
  signal loadD : std_logic;
  signal phase_advance : std_logic;

  attribute rloc of phase_advance : signal is "X0Y0";
  attribute rloc of q : label is "X0Y0";
  attribute rloc of R_io : signal is col32(-4,2);
  attribute rloc of Din : signal is col32(-8,2);
begin
  p : entity work.phase port map (
    phase_advance, loadA, loadB, loadC, loadD, clk);
  q : entity work.quad port map (
    R, Din, phase_advance, loadA, loadB, loadC, loadD, clk);
  process
  begin
    wait until rising_edge(clk);
    Din <= Din_io;
    R_io <= R;
  end process;
end behaviour;
