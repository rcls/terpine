library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.all;
use work.defs.all;

entity wrap is
  port (D : in std_logic;
        Q : out std_logic;
        strobe : in std_logic;
        clk : in std_logic);
end wrap;

architecture behavioral of wrap is
  signal input : words_16_t;
  signal output : words_5_t;
  signal result : words_5_t;
begin
  core : entity work.core port map (input, result, clk);
  process
  begin
    wait until rising_edge(clk);
    for i in 1 to 15 loop
      input(i) <= input(i)(30 downto 0) & input(i-1)(31);
    end loop;
    input(0) <= input(0)(30 downto 0) & D;
    for i in 1 to 4 loop
      output(i) <= output(i)(30 downto 0) & output(i-1)(31);
    end loop;
    output(0) <= output(0)(30 downto 0) & output(4)(31);
    if strobe = '1' then
      output <= result;
    end if;
    Q <= output(4)(31);
  end process;
end behavioral;
