library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package defs is

  subtype word_t is unsigned (31 downto 0);

  type dataset_t is array (natural range <>) of word_t;
  subtype words_16_t is dataset_t (0 to 15);
  subtype words_5_t is dataset_t (0 to 4);

  constant dly : integer := 5;

end defs;
