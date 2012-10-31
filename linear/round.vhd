library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity round is
  generic (N : natural range 0 to 3; dir : integer);
  port (R : out word_t;
        W : in word_t;
        A : in word_t;
        B : in word_t;
        C : in word_t;
        D : in word_t; -- E buffered one stage.
        E : in word_t;
        clk : in std_logic);
end round;

architecture behavioral of round is
  function FF (Bu : word_t; Cu : word_t; Du : word_t) return word_t is
  begin
    if N = 0 then
      return (Bu and Cu) or (not Bu and Du);
    elsif N = 1 then
      return Bu xor Cu xor Du;
    elsif N = 2 then
      return (Bu and Cu) or (Cu and Du) or (Du and Bu);
    else
      return Bu xor Cu xor Du;
    end if;
  end FF;
  function KK (NN : natural) return word_t is
  begin
    if NN = 0 then
      return x"5a827999";
    elsif NN = 1 then
      return x"6ed9eba1";
    elsif NN = 2 then
      return x"8f1bbcdc";
    else
      return x"ca62c1d6";
    end if;
  end KK;
  signal I1 : word_t;
  signal I2 : word_t;
  signal I3 : word_t;
  signal BB : word_t;
  signal DD : word_t;
  signal WW : word_t;

  attribute rloc of I3 : signal is col8(0,0);
  attribute rloc of I2,WW : signal is col8(dir,0);
  attribute rloc of I1 : signal is col8(dir*2,0);
  attribute rloc of R  : signal is col8(dir*3,0);
begin
  process
  begin
    wait until rising_edge(clk);
    WW <= W;
    I3 <= KK(N) + WW;
    I2 <= (E rol 30) + I3;
    I1 <= FF(B, C rol 30, D rol 30) + I2;
    R <= (A rol 5) + I1;
  end process;
end behavioral;
