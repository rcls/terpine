library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity quad_test is
end quad_test;

architecture behavioral of quad_test is
  signal clk : std_logic;

  signal phase_advance : std_logic;
  signal loadA : std_logic;
  signal loadB : std_logic;
  signal loadC : std_logic;
  signal loadD : std_logic;

  signal Din : word_t;
  signal R : word_t;

  constant data : dataset_t(0 to 15) := (
    x"54686973", x"20697320", x"61207465", x"73742e0a",
    x"80000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000080");

begin
  p : entity work.phase port map (
    phase_advance, loadA, loadB, loadC, loadD, clk);
  q : entity work.quad port map (
    R, Din, phase_advance, loadA, loadB, loadC, loadD, clk);
  process
  begin
    wait for 5ns;
    clk <= '0';
    wait for 5ns;
    clk <= '1';
  end process;
  process
  begin
    Din <= (others => 'U');
    wait until loadB = '1';
    wait until falling_edge(clk);
    for i in 0 to 15 loop
      wait until falling_edge(clk);
      Din <= data(i);
    end loop;
    wait until falling_edge(clk);
    Din <= (others => 'U');
    wait for 1 us;
  end process;
end behavioral;
