library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.all;
use work.defs.all;

entity core_test is
end core_test;

architecture behavioral of core_test is
  signal input : words_16_t;
  signal output : words_5_t;
  signal clk : std_logic;
begin
  core: entity work.core port map (input, output, clk);
  process
  begin
    input <= (others => "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
    for i in 0 to 9 loop
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
      clk <= '0';
    end loop;
    input <= (x"54686973", x"20697320", x"61207465", x"73742e0a",
              x"80000000", x"00000000", x"00000000", x"00000000",
              x"00000000", x"00000000", x"00000000", x"00000000",
              x"00000000", x"00000000", x"00000000", x"00000080");
    wait for 5 ns;
    clk <= '1';
    wait for 5ns;
    clk <= '0';
    input <= (others => "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
    for i in 0 to 90 loop
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
      clk <= '0';
    end loop;
  end process;
end behavioral;
