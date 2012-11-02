library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity expand12 is
  port (I : in dataset_t (0 to 15);
        O : out dataset_t (12 to 27);
        clk : in std_logic);
end expand12;

architecture expand12 of expand12 is
  function L (x : word_t) return word_t is
  begin
    return x rol 1;
  end;
  function LL (x : word_t) return word_t is
  begin
    return x rol 2;
  end;
  function LLL (x : word_t) return word_t is
  begin
    return x rol 3;
  end;

  signal Q12, Q13, Q14, Q15, Q16, Q17, Q18 : word_t;
  signal T11, T12, T13, T14, T15 : word_t;
  signal P10, P11, P12, P13 : word_t;

  signal O12, O13, O14, O15, O16, O17, O18, O19 : word_t;
  signal O20, O21, O22, O23, O24, O25, O26, O27 : word_t;

  attribute rloc of Q16, Q17, Q18, T11 : signal is row32(0,6);
  attribute rloc of T12, T13, T14, T15 : signal is row32(0,5);
  attribute rloc of P10, P11, P12, P13 : signal is row32(0,4);

  --constant outloc : string :=
  --  row32(0,3) & row32(0,3) & row32(0,3) & row32(0,3) &
  --  row32(0,2) & row32(0,2) & row32(0,2) & row32(0,2) &
  --  row32(0,1) & row32(0,1) & row32(0,1) & row32(0,1) &
  --  row32(0,0) & row32(0,0) & row32(0,0) & row32(0,0);
  --attribute rloc of O : signal is outloc;
  attribute rloc of O12, O13, O14, O15 : signal is row32(0,3);
  attribute rloc of O16, O17, O18, O19 : signal is row32(0,2);
  attribute rloc of O20, O21, O22, O23 : signal is row32(0,1);
  attribute rloc of O24, O25, O26, O27 : signal is row32(0,0);

  constant xor01234 : word_t := x"96696996";
  constant xor34 : word_t := x"00ffff00";
begin

  -- Sigh.
  O(12) <= O12; O(13) <= O13; O(14) <= O14; O(15) <= O15;
  O(16) <= O16; O(17) <= O17; O(18) <= O18; O(19) <= O19;
  O(20) <= O20; O(21) <= O21; O(22) <= O22; O(23) <= O23;
  O(24) <= O24; O(25) <= O25; O(26) <= O26; O(27) <= O27;

  process
  begin
    wait until rising_edge(clk);

    Q12 <= I(12);
    Q13 <= I(13);
    Q14 <= I(14);
    Q15 <= I(15);
    Q16 <= L(I(13) xor I( 8) xor I(2) xor I(0));
    Q17 <= L(I(14) xor I( 9) xor I(3) xor I(1));
    Q18 <= L(I(15) xor I(10) xor I(4) xor I(2));

    T11 <= I(11) xor I(5) xor I(3);
    T12 <= I(12) xor I(6) xor I(4);
    T13 <= I(13) xor I(7) xor I(5);
    T14 <= I(14) xor I(8) xor I(6);
    T15 <= I(15) xor I(9) xor I(7);

    P10 <= I(10) xor I( 8);
    P11 <= I(11) xor I( 9);
    P12 <= I(12) xor I(10);
    P13 <= I(13) xor I(11);

    O12 <= Q12;
    O13 <= Q13;
    O14 <= Q14;
    O15 <= Q15;
    O16 <= Q16;
    O17 <= Q17;
    O18 <= Q18;

    O19 <= L(Q16 xor T11);
    O20 <= L(Q17 xor T12);
    O21 <= L(Q18 xor T13);

    O22 <= LL(Q16 xor T11)  xor L(T14);
    O23 <= LL(Q17 xor T12)  xor L(T15);
    O24 <= LL(Q18 xor T13)  xor L(Q16) xor L(P10);

    O25 <= LLL(Q16 xor T11) xor LL(T14) xor L(Q17) xor L(P11);
    O26 <= LLL(Q17 xor T12) xor LL(T15) xor L(Q18) xor L(P12);
    O27 <= LLL(Q18 xor T13) xor LL(P10) xor L(P13) xor LL(T11);
  end process;
end expand12;
