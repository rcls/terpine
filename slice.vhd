library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

library UNISIM;
use UNISIM.VComponents.all;

entity bit5op2 is
  generic (f1, f2 : bv32);
  port (o1, o2 : out std_logic;
        i0, i1, i2, i3, i4, clk : in std_logic);
end bit5op2;
architecture bit5op2 of bit5op2 is
  signal b1, b2 : std_logic;
  constant ff : bit_vector(63 downto 0) := f1 & f2;
  attribute rloc of lut, fd1, fd2 : label is "X0Y0";
  attribute hlutnm : string;
  attribute hlutnm of lut : label is "lut6";
begin
  lut : lut6_2 generic map (init=> f2 & f1)
    port map (o5=>b1, o6=>b2, i0=>i0, i1=>i1, i2=>i2, i3=>i3, i4=>i4, i5=>'1');
  fd1 : fd port map(q=>o1, c=>clk, d=>b1);
  fd2 : fd port map(q=>o2, c=>clk, d=>b2);
end bit5op2;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity word5op2 is
  generic (f1, f2 : bv32; u1, u2, l0, l1, l2, l3, l4 : integer);
  port (o1, o2 : out word_t;
        i0, i1, i2, i3, i4 : in word_t;
        clk : in std_logic);
end word5op2;

architecture word5op2 of word5op2 is
  signal d0, d1, d2, d3, d4 : word_t;
  signal q1, q2 : word_t;
begin
  o1 <= q1 rol u1;
  o2 <= q2 rol u2;
  d0 <= i0 rol l0; d1 <= i1 rol l1; d2 <= i2 rol l2; d3 <= i3 rol l3;
  d4 <= i4 rol l4;
  bits : for I in 0 to 31 generate
    attribute rloc of bit : label is loc(0,I/4);
  begin
    bit : entity work.bit5op2 generic map (f1, f2)
      port map (q1(I), q2(I), d0(I), d1(I), d2(I), d3(I), d4(I), clk);
  end generate;
end word5op2;
