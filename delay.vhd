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

architecture delay_behavioral of delay is
  signal count : integer range 0 to N - 3;
  signal buf_D : word_t;
  signal buf_Q : word_t;
  signal ram : dataset_t (0 to N - 3);
  attribute keep_hierarchy : string;
  attribute keep_hierarchy of delay_behavioral : architecture is "true";
begin
  process
  begin
    wait until rising_edge(clk);
    if count = N - 3 then
      count <= 0;
    else
      count <= count + 1;
    end if;
    buf_D <= D;
    ram(count) <= buf_D;
    buf_Q <= ram(count);
    Q <= buf_q;
  end process;
end delay_behavioral;
