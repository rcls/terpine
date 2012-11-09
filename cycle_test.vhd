library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity cycle_test is
end cycle_test;

architecture cycle_test of cycle_test is
  constant init : dataset_t(0 to 4) := (
    iE rol 2, iD rol 2, iC rol 2, iB, iA);
  constant data : dataset_t(0 to 15) := (
    x"54686973", x"20697320", x"61207465", x"73742e0a",
    x"80000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000080");
  signal R, Din : word_t := (others => 'U');
  signal load : std_logic := '0';
  signal phase_advance : std_logic := '0';
  signal clk : std_logic;

  function b_to_l (x : boolean) return std_logic is
  begin
    if x then return '1'; else return '0'; end if;
  end b_to_l;
begin
  c : entity work.cycle port map (R, Din, load, phase_advance, open, clk);
  process
  begin
    wait for 5ns;
    clk <= '0';
    wait for 5ns;
    clk <= '1';
  end process;

  process
  begin
    wait until rising_edge(clk);
    load <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    for i in 0 to 4 loop
      phase_advance <= b_to_l (i = 3);
      Din <= init(i);
      wait until rising_edge(clk);
    end loop;
    phase_advance <= '0';
    for i in 0 to 15 loop
      Din <= data(i);
      load <= b_to_l (i < 14);
      wait until rising_edge(clk);
    end loop;
    Din <= (others => 'U');
    for i in 0 to 79 loop
      phase_advance <= b_to_l (i mod 20 = 2);
      wait until rising_edge(clk);
    end loop;
  end process;
end cycle_test;
