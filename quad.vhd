-- Drive 4 instances of cycle.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity quad is
  port (R : out word_t;
        Din : in word_t;
        pa : in std_logic;
        ldA : in std_logic;
        ldB : in std_logic;
        ldC : in std_logic;
        ldD : in std_logic;
        clk : in std_logic);
end quad;

architecture quad of quad is
  attribute keep_hierarchy : string;
  attribute keep_hierarchy of quad : architecture is "soft";

  signal ph5A, ph5B, ph5C, ph5D : natural range 0 to 3;
  signal rA, rB, rC, rD : word_t;
  signal Db : word_t;

  attribute rloc of cA : label is "X0Y0";
  attribute rloc of cB : label is "X8Y0";
  attribute rloc of cC : label is "X0Y8";
  attribute rloc of cD : label is "X8Y8";

  attribute rloc of R : signal is
    col(11,13,8) & col(3,13,8) & col(11,5,8) & col(3,5,8);
  attribute rloc of Db : signal is
    col(11,13,8) & col(3,13,8) & col(11,5,8) & col(3,5,8);

  function choose(m : natural range 0 to 3; n : natural;
                  A, B, C, D : word_t) return byte_t is
    variable r : byte_t;
  begin
    case m is
      when 0 => r := A(n+7 downto n);
      when 1 => r := B(n+7 downto n);
      when 2 => r := C(n+7 downto n);
      when 3 => r := D(n+7 downto n);
    end case;
    return r;
  end choose;

begin
  cA : entity work.cycle port map (rA, Db, ldA, pa, ph5A, clk);
  cB : entity work.cycle port map (rB, Db, ldB, pa, ph5B, clk);
  cC : entity work.cycle port map (rC, Db, ldC, pa, ph5C, clk);
  cD : entity work.cycle port map (rD, Db, ldD, pa, ph5D, clk);

  process
  begin
    wait until rising_edge(clk);
    Db <= Din;
    R( 7 downto  0) <= choose (ph5A, 0, rA, rB, rC, rD);
    R(15 downto  8) <= choose (ph5B, 8, rB, rC, rD, rA);
    R(23 downto 16) <= choose (ph5C,16, rC, rD, rA, rB);
    R(31 downto 24) <= choose (ph5D,24, rD, rA, rB, rC);
  end process;
end quad;
