-- Lets try packing delays two SRLs into one LUT.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

library UNISIM;
use UNISIM.VComponents.all;

entity delayp is
  generic (len : natural);
  port (d : in unsigned (7 downto 0);
        q : out unsigned (7 downto 0);
        clk : in std_logic);
end delayp;

architecture delayp of delayp is
  signal r : unsigned (7 downto 0);
  signal a : unsigned (3 downto 0);
  attribute h_set : string;
  attribute rloc : string;
  attribute h_set of s0 : label is "sr";
  attribute h_set of s1 : label is "sr";
  attribute h_set of s2 : label is "sr";
  attribute h_set of s3 : label is "sr";
  attribute h_set of s4 : label is "sr";
  attribute h_set of s5 : label is "sr";
  attribute h_set of s6 : label is "sr";
  attribute h_set of s7 : label is "sr";
  attribute rloc of s0 : label is "X0Y0";
  attribute rloc of s1 : label is "X0Y0";
  attribute rloc of s2 : label is "X0Y0";
  attribute rloc of s3 : label is "X0Y0";
  attribute rloc of s4 : label is "X0Y0";
  attribute rloc of s5 : label is "X0Y0";
  attribute rloc of s6 : label is "X0Y0";
  attribute rloc of s7 : label is "X0Y0";
begin
  a <= to_unsigned (len - 2, 4);
  s0 : srl16e port map (d=> d(0), ce=> '1', clk=> clk,
                        a0=> a(0), a1=> a(1), a2=> a(2), a3=> a(3),
                        q => r(0));
  s1 : srl16e port map (d=> d(1), ce=> '1', clk=> clk,
                        a0=> a(0), a1=> a(1), a2=> a(2), a3=> a(3),
                        q => r(1));
  s2 : srl16e port map (d=> d(2), ce=> '1', clk=> clk,
                        a0=> a(0), a1=> a(1), a2=> a(2), a3=> a(3),
                        q => r(2));
  s3 : srl16e port map (d=> d(3), ce=> '1', clk=> clk,
                        a0=> a(0), a1=> a(1), a2=> a(2), a3=> a(3),
                        q => r(3));
  s4 : srl16e port map (d=> d(4), ce=> '1', clk=> clk,
                        a0=> a(0), a1=> a(1), a2=> a(2), a3=> a(3),
                        q => r(4));
  s5 : srl16e port map (d=> d(5), ce=> '1', clk=> clk,
                        a0=> a(0), a1=> a(1), a2=> a(2), a3=> a(3),
                        q => r(5));
  s6 : srl16e port map (d=> d(6), ce=> '1', clk=> clk,
                        a0=> a(0), a1=> a(1), a2=> a(2), a3=> a(3),
                        q => r(6));
  s7 : srl16e port map (d=> d(7), ce=> '1', clk=> clk,
                        a0=> a(0), a1=> a(1), a2=> a(2), a3=> a(3),
                        q => r(7));
  process
  begin
    wait until rising_edge(clk);
    q <= r;
  end process;
end delayp;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity delay is
  generic (len : natural);
  port (i : in word_t;
        o : out word_t;
        clk : in std_logic);
end delay;

architecture delay of delay is
begin
  l: for n in 0 to 3 generate
    d: entity work.delayp generic map (len) port map (
      i(8*n + 7 downto 8*n), o(8*n + 7 downto 8*n), clk);
  end generate;
end;