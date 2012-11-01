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
begin
  l : for i in 0 to 31 generate
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
