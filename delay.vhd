library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity delay is
  generic (N : integer);
  port (D : in word_t;
        Q : out word_t;
        clk : in std_logic);
end entity;

architecture behavioral of delay is
  signal count : integer range 0 to N - 3;
  signal buf_count : integer range 0 to N - 3;
  signal buf_D : word_t;
  signal buf_Q : word_t;
  signal ram : dataset_t (0 to N - 3);
begin
  process
  begin
    wait until rising_edge(clk);
    buf_count <= count;
    if count = N - 3 then
      count <= 0;
    else
      count <= count + 1;
    end if;
    buf_D <= D;
    buf_Q <= ram(buf_count);
    ram(buf_count) <= buf_D;
    Q <= buf_Q;
  end process;
end behavioral;
