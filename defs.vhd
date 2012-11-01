library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package defs is

  subtype word_t is unsigned (31 downto 0);
  subtype bv32 is bit_vector (31 downto 0);

  type dataset_t is array (natural range <>) of word_t;
  --subtype words_16_t is dataset_t (0 to 15);
  --subtype words_5_t is dataset_t (0 to 4);

  attribute rloc : string;

  function loc(x, y : integer) return string is
  begin
    return "X" & integer'image(x) & "Y" & integer'image(y);
  end loc;
  function lc4(x, y : integer) return string is
  begin
    return loc(x, y) & " " & loc(x, y) & " " & loc(x, y) & " " & loc(x, y);
  end lc4;
  function col8(x, y : integer) return string is
  begin
    return  lc4(x,y+7) &" "& lc4(x,y+6) &" "& lc4(x,y+5) &" "& lc4(x,y+4)
      &" "& lc4(x,y+3) &" "& lc4(x,y+2) &" "& lc4(x,y+1) &" "& lc4(x,y);
  end col8;

  constant M0 : bv32 := x"aaaaaaaa";
  constant M1 : bv32 := x"cccccccc";
  constant M2 : bv32 := x"f0f0f0f0";
  constant M3 : bv32 := x"ff00ff00";
  constant M4 : bv32 := x"ffff0000";
  constant zero : bv32 := x"00000000";
  function const (w : word_t; b : integer) return bv32 is
  begin
    if w(b) = '1' then return x"ffffffff"; else return zero; end if;
  end const;
end defs;
