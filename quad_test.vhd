library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity quad_test is
end quad_test;

architecture behavioral of quad_test is
  signal clk : std_logic;

  signal paA, paB, paC, paD : std_logic := '0';
  signal ldA, ldB, ldC, ldD : std_logic := '0';

  signal Din : word_t;
  signal R : word_t;

  constant init : dataset_t(0 to 4) := (
    iE rol 2, iD rol 2, iC rol 2, iB, iA);
  constant data : dataset_t(0 to 15) := (
    x"54686973", x"20697320", x"61207465", x"73742e0a",
    x"80000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000080");

begin
  p : entity work.phase port map (
    paA, paB, paC, paD, ldA, ldB, ldC, ldD, clk);
  q : entity work.quad port map (
    R, Din, paA, paB, paC, paD, ldA, ldB, ldC, ldD, clk);
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
    wait until ldB = '1';
   --wait until rising_edge(clk);
    for i in 0 to 4 loop
      wait until rising_edge(clk);
      Din <= init(i);
    end loop;
    for i in 0 to 15 loop
      wait until rising_edge(clk);
      Din <= data(i);
    end loop;
    wait until rising_edge(clk);
    Din <= (others => 'U');
    wait for 1 us;
  end process;
end behavioral;
