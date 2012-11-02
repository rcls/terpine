library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package defs is

  subtype word_t is unsigned (31 downto 0);
  subtype byte_t is unsigned (7 downto 0);

  subtype bv32 is bit_vector (31 downto 0);

  type dataset_t is array (natural range <>) of word_t;
  --subtype words_16_t is dataset_t (0 to 15);
  --subtype words_5_t is dataset_t (0 to 4);

  attribute bel : string;
  attribute hu_set : string;
  attribute keep : string;
  attribute keep_hierarchy : string;
  attribute rloc : string;
  attribute use_clock_enable : string;
  attribute use_sync_reset : string;
  attribute use_sync_set : string;

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

  function abcd(index : integer) return string is
  begin
    case index mod 4 is
      when 0 => return "A";
      when 1 => return "B";
      when 2 => return "C";
      when 3 => return "D";
    end case;
  end abcd;
  function abcd56(index : integer) return string is
  begin
    if index mod 2 = 0 then
      return abcd(index / 2);
    else
      return abcd(index / 2) & "5";
    end if;
  end abcd56;

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
