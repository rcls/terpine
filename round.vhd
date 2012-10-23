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
  function FF (Bu : word_t; Cu : word_t; Du : word_t) return word_t is
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
  signal CC : word_t;
  signal DD : word_t;
  signal DDD : word_t;
  signal EE : word_t;
  signal EEE : word_t;

  signal A1 : word_t;
  signal B1 : word_t;
  signal C1 : word_t;
  signal D1 : word_t;
  signal E1 : word_t;

  attribute keep : string;
  attribute keep of A : signal is "soft";
  attribute keep of B : signal is "soft";
  attribute keep of C : signal is "soft";
  attribute keep of D : signal is "soft";
  attribute keep of E : signal is "soft";
  attribute keep of A1 : signal is "soft";
  attribute keep of B1 : signal is "soft";
  attribute keep of C1 : signal is "soft";
  attribute keep of D1 : signal is "soft";
  attribute keep of E1 : signal is "soft";
  attribute keep of DD : signal is "soft";
  attribute keep of EE : signal is "soft";

  function delay (i : natural) return boolean is
  begin return N >= 16 and N mod 16 < i; end delay;
begin
  d_a: if not delay (1) generate
    A1 <= A;
  end generate;
  d_b: if not delay (2) generate
    B1 <= B;
  end generate;
  d_c: if not delay (3) generate
    C1 <= C;
  end generate;
  d_d: if not delay (4) generate
    D1 <= D;
  end generate;
  d_e: if not delay (5) generate
    E1 <= E;
  end generate;

  process
  begin
    wait until rising_edge(clk);
    if delay (1) then
      A1 <= A;
    end if;
    if delay (2) then
      B1 <= B;
    end if;
    if delay (3) then
      C1 <= C;
    end if;
    if delay (4) then
      D1 <= D;
    end if;
    if delay (5) then
      E1 <= E;
    end if;

    CC <= C1;
    DD <= D1;
    DDD <= DD;
    EE <= E1;
    EEE <= EE;
    I2 <= (EEE rol 30) + W;
    I1 <= FF(B1, CC rol 30, DDD rol 30) + KK + I2;
    R <= (A1 rol 5) + I1;
  end process;
end behavioral;
