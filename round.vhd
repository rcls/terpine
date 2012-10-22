library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity round is
  generic (N : natural);
  port (R : out word_t;
        W : in word_t;
        A : in word_t;
        B : in word_t;
        C : in word_t;
        D : in word_t;
        E : in word_t;
        clk : in std_logic);
end round;

architecture behavioral of round is
  function FF (Bu : word_t; Ci : word_t; Di : word_t) return word_t is
    variable Cu : word_t := Ci rol 30;
    variable Du : word_t := Di rol 30;
  begin
    if N < 20 then
      return (Bu and Cu) or (not Bu and Du);
    elsif N < 40 then
      return Bu xor Cu xor Du;
    elsif N < 60 then
      return (Bu and Cu) or (Cu and Du) or (Du and Bu);
    else
      return Bu xor Cu xor Du;
    end if;
  end FF;
  function KK return word_t is
  begin
    if N < 20 then
      return x"5a827999";
    elsif N < 40 then
      return x"6ed9eba1";
    elsif N < 60 then
      return x"8f1bbcdc";
    else
      return x"ca62c1d6";
    end if;
  end KK;
  signal I1 : word_t;
  signal I2 : word_t;
  signal I3 : word_t;
begin
  process
  begin
    wait until rising_edge(clk);
    I3 <= W + KK;
    I2 <= (E rol 30) + I3;
    I1 <= FF(B,C,D) + I2;
    R <= (A rol 5) + I1;
  end process;
end behavioral;