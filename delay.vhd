-- Lets try packing delays two SRLs into one LUT.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

library UNISIM;
use UNISIM.VComponents.all;

entity delay is
  generic (len : natural);
  port (d : in word_t;
        q : out word_t;
        clk : in std_logic);
end delay;

architecture delay of delay is
  signal r : word_t;
  signal a : unsigned (3 downto 0) := to_unsigned (len - 2, 4);
  attribute hu_set : string;
  attribute rloc : string;
begin
  --a <= to_unsigned (len - 2, 4);
  l : for i in 0 to 31 generate
--    attribute hu_set of s : label is "sr" & integer'image(i / 8);
--    attribute rloc of s : label is "x0y0";
  begin
    s : srl16e port map (d=> d(i), ce=> '1', clk=> clk,
                         a0=> a(0), a1=> a(1), a2=> a(2), a3=> a(3),
                         q => r(i));
  end generate;
  process
  begin
    wait until rising_edge(clk);
    q <= r;
  end process;
end;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

library UNISIM;
use UNISIM.VComponents.all;

entity double_delay is generic (lenA, lenB : natural);
  port (dA : in word_t; dB : in word_t;
        qA : out word_t; qB : out word_t;
        clk : in std_logic);
end double_delay;

architecture double_delay of double_delay is
  signal rA : word_t;
  signal rB : word_t;
  signal aA : unsigned (3 downto 0) := to_unsigned (lenA - 2, 4);
  signal aB : unsigned (3 downto 0) := to_unsigned (lenB - 2, 4);
  attribute hu_set : string;
  attribute rloc : string;
begin
  --a <= to_unsigned (len - 2, 4);
  l : for i in 0 to 31 generate
--    attribute hu_set of sA : label is "sr" & integer'image(i / 4);
--    attribute hu_set of sB : label is "sr" & integer'image(i / 4);
--    attribute rloc of sA : label is "x0y0";
--    attribute rloc of sB : label is "x0y0";
  begin
    sA : srl16e port map (d=> dA(i), ce=> '1', clk=> clk,
                          a0=> aA(0), a1=> aA(1), a2=> aA(2), a3=> aA(3),
                          q=> rA(i));
    sB : srl16e port map (d=> dB(i), ce=> '1', clk=> clk,
                          a0=> aB(0), a1=> aB(1), a2=> aB(2), a3=> aB(3),
                          q=> rB(i));
  end generate;
  process
  begin
    wait until rising_edge(clk);
    qA <= rA;
    qB <= rB;
  end process;
end;
