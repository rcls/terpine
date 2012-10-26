library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity delay is
  generic (N : natural);
  port (D : in unsigned (31 downto 0);
        Q : out unsigned (31 downto 0);
        clk : in std_logic);
end entity;

architecture delay_behavioral of delay is
  subtype word_t is unsigned (31 downto 0);
  type dataset_t is array (natural range <>) of word_t;
  signal count : natural range 0 to N - 3;
  signal buf_D : word_t;
  signal buf_Q : word_t;
  signal buf_Q2 : word_t;
  signal ram : dataset_t (0 to N - 2);
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
    buf_Q2 <= buf_Q;
    Q <= buf_Q2;
  end process;
end delay_behavioral;
