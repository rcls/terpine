library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity delay is
  generic (N : natural);
  port (D : in word_t;
        Q : out word_t;
        clk : in std_logic);
end entity;

architecture delay_behavioral of delay is
  signal count : natural range 0 to N - 3;
  signal buf_D : word_t;
  signal buf_Q : word_t;
  signal ram : dataset_t (0 to N - 2);
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
    Q <= buf_Q;
  end process;
end delay_behavioral;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity double_delay is
  generic (N1, N2 : natural);
  port (D1 : in word_t;
        Q1 : out word_t;
        D2 : in word_t;
        Q2 : out word_t;
        clk : in std_logic);
end entity;

architecture double_delay of double_delay is
  subtype word_t is word_t;
  type dataset_t is array (natural range <>) of word_t;
  signal count1 : natural range 0 to N1 - 3;
  signal count2 : natural range 0 to N2 - 3;
  signal buf_D1 : word_t;
  signal buf_D2 : word_t;
  signal buf_Q1 : word_t;
  signal buf_Q2 : word_t;
  signal ram : dataset_t (0 to 255);
  attribute keep_hierarchy of double_delay : architecture is "true";
begin
  process
  begin
    wait until rising_edge(clk);

    if count1 = N1 - 3 then
      count1 <= 0;
    else
      count1 <= count1 + 1;
    end if;
    buf_D1 <= D1;
    ram(count1) <= buf_D1;
    buf_Q1 <= ram(count1);
    Q1 <= buf_Q1;

    if count2 = N2 - 3 then
      count2 <= 0;
    else
      count2 <= count2 + 1;
    end if;
    buf_D2 <= D2;
    ram(count2 + 128) <= buf_D2;
    buf_Q2 <= ram(count2 + 128);
    Q2 <= buf_Q2;

  end process;
end double_delay;
