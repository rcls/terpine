library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

library UNISIM;
use UNISIM.VComponents.all;

entity bit5op is
  generic (f : bv32; I : integer; suffix : string := "FF");
  port (o : out std_logic;
        i0, i1, i2, i3, i4, clk : in std_logic);
end bit5op;
architecture bit5op of bit5op is
  signal b : std_logic;
  attribute rloc of lut, buf : label is "X0Y0";
  attribute bel of buf : label is abcd(I) & suffix;
begin
  lut : lut5_l generic map (init=> f)
    port map (lo=>b, i0=>i0, i1=>i1, i2=>i2, i3=>i3, i4=>i4);
  buf : fd port map(q=>o, c=>clk, d=>b);
end bit5op;
