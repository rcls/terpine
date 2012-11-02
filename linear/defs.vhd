library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package defs is

  subtype word_t is unsigned (31 downto 0);
  subtype bv32 is bit_vector (31 downto 0);

  type dataset_t is array (natural range <>) of word_t;
  subtype words_16_t is dataset_t (0 to 15);
  subtype words_5_t is dataset_t (0 to 4);

  constant line_len : natural := 8;
  constant core_len : natural := 10;

  function loc(x, y : integer) return string is
  begin
    return "X" & integer'image(x) & "Y" & integer'image(y);
  end loc;
  function lc4(x, y : integer) return string is
  begin
    return loc(x, y) &" "& loc(x, y) &" "& loc(x, y) &" "& loc(x, y) &" ";
  end lc4;
  function col8(x, y : integer) return string is
  begin
    return lc4(x,y+7) & lc4(x,y+6) & lc4(x,y+5) & lc4(x,y+4)
      &    lc4(x,y+3) & lc4(x,y+2) & lc4(x,y+1) & lc4(x,y);
  end col8;

  function rowN(x, y, N : integer) return string is
  begin
    if N = 0 then
      return "";
    elsif N = 1 then
      return loc (x, y);
    else
      return rowN(x + N / 2, y, N - (N/2)) &" "& rowN(x, y, N / 2);
    end if;
  end rowN;
  function row32(x, y : integer) return string is
  begin
    return rowN(x, y, 32);
  end row32;
  attribute rloc : string;
  attribute keep_hierarchy : string;
  attribute keep : string;

end defs;
