library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

library UNISIM;
use UNISIM.VComponents.all;

entity bit5op2 is
  generic (f1, f2 : bv32; index : integer);
  port (o1, o2 : out std_logic;
        i0, i1, i2, i3, i4, clk : in std_logic);
end bit5op2;
architecture bit5op2 of bit5op2 is
  signal b1, b2 : std_logic;
  constant ff : bit_vector(63 downto 0) := f1 & f2;
  attribute rloc of lut, fd1, fd2 : label is "X0Y0";
  attribute bel of fd1 : label is abcd(index) & "5FF";
  attribute bel of fd2 : label is abcd(index) & "FF";
begin
  lut : lut6_2 generic map (init=> f2 & f1)
    port map (o5=>b1, o6=>b2, i0=>i0, i1=>i1, i2=>i2, i3=>i3, i4=>i4, i5=>'1');
  fd1 : fd port map(q=>o1, c=>clk, d=>b1);
  fd2 : fd port map(q=>o2, c=>clk, d=>b2);
end bit5op2;
