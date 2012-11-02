library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

library UNISIM;
use UNISIM.VComponents.all;

entity bit5op2 is
  generic (f1, f2 : bv32);
  port (o1, o2 : out std_logic;
        i0, i1, i2, i3, i4, clk : in std_logic);
end bit5op2;
architecture bit5op2 of bit5op2 is
  signal b1, b2 : std_logic;
  constant ff : bit_vector(63 downto 0) := f1 & f2;
  attribute rloc of lut, fd1, fd2 : label is "X0Y0";
  attribute hlutnm : string;
  attribute hlutnm of lut : label is "lut6";
begin
  lut : lut6_2 generic map (init=> f2 & f1)
    port map (o5=>b1, o6=>b2, i0=>i0, i1=>i1, i2=>i2, i3=>i3, i4=>i4, i5=>'1');
  fd1 : fd port map(q=>o1, c=>clk, d=>b1);
  fd2 : fd port map(q=>o2, c=>clk, d=>b2);
  --fd1 : fd port map(q=>o1, c=>clk, ce=>'1', r=>'0', d=>b1);
  --fd2 : fd port map(q=>o2, c=>clk, ce=>'1', r=>'0', d=>b2);
  --process
  --begin
  --  wait until rising_edge(clk);
  --  o1 <= b1;
  --  o2 <= b2;
  --end process;
end bit5op2;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity word5op2 is
  generic (f1, f2 : bv32; u1, u2, l0, l1, l2, l3, l4 : integer);
  port (o1, o2 : out word_t;
        i0, i1, i2, i3, i4 : in word_t;
        clk : in std_logic);
end word5op2;

architecture word5op2 of word5op2 is
  signal d0, d1, d2, d3, d4 : word_t;
  signal q1, q2 : word_t;
begin
  o1 <= q1 rol u1;
  o2 <= q2 rol u2;
  d0 <= i0 rol l0; d1 <= i1 rol l1; d2 <= i2 rol l2; d3 <= i3 rol l3;
  d4 <= i4 rol l4;
  bits : for I in 0 to 31 generate
    attribute rloc of bit : label is loc(I,0);
  begin
    bit : entity work.bit5op2 generic map (f1, f2)
      port map (q1(I), q2(I), d0(I), d1(I), d2(I), d3(I), d4(I), clk);
  end generate;
end word5op2;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity expand12b is
  port (I : in dataset_t (0 to 15);
        O : out dataset_t (12 to 27);
        clk : in std_logic);
end expand12b;

architecture expand12 of expand12b is
  signal Q12, Q13, Q14, Q15, Q16, Q17, Q18 : word_t;
  signal T11, T12, T13, T14, T15 : word_t;
  signal P10, P11, P12, P13 : word_t;

  attribute keep_hierarchy of expand12 : architecture is "true";

  constant zero     : word_t := x"00000000";

  constant xor01    : bv32 := x"66666666";
  constant xor012   : bv32 := x"96969696";
  constant xor0123  : bv32 := x"69966996";
  constant xor01234 : bv32 := x"96696996";
  constant xor03    : bv32 := x"aa5555aa";
  constant xor14    : bv32 := x"3333cccc";
  constant xor24    : bv32 := x"0f0ff0f0";
  constant xor34    : bv32 := x"00ffff00";
  constant xor134   : bv32 := x"cc3333cc";
  constant bypass0  : bv32 := x"aaaaaaaa";
  constant bypass1  : bv32 := x"cccccccc";

  attribute rloc of q12_13, q14_15,  q16_p10, q17_p11 : label is "X0Y3";
  attribute rloc of o12_13, q18_p12, t11_p13, t12_t14 : label is "X0Y2";
  attribute rloc of o14_15, t13_t15, o24_19,  o20_23  : label is "X0Y1";
  attribute rloc of o16_18, o22_25,  o23_26,  o21_27  : label is "X0Y0";

begin

  -- Q16 <= L(I(13) xor I( 8) xor I(2) xor I(0));
  -- P10 <= I(10) xor I( 8);
  q16_p10 : entity work.word5op2
    generic map (xor0123, xor14, 1, 0, 0, 0, 0, 0, 0)
    port map (Q16, P10, I(13), I(8), I(2), I(0), I(10), clk);

  -- Q17 <= L(I(14) xor I( 9) xor I(3) xor I(1));
  -- P11 <= I(11) xor I( 9);
  q17_p11 : entity work.word5op2
    generic map (xor0123, xor14, 1, 0, 0, 0, 0, 0, 0)
    port map (Q17, P11, I(14), I(9), I(3), I(1), I(11), clk);

  -- Q18 <= L(I(15) xor I(10) xor I(4) xor I(2));
  -- P12 <= I(12) xor I(10);
  q18_p12 : entity work.word5op2
    generic map (xor0123, xor14, 1, 0, 0, 0, 0, 0, 0)
    port map (Q18, P12, I(15), I(10), I(4), I(2), I(12), clk);

  -- T11 <= I(11) xor I(5) xor I(3);
  -- P13 <= I(13) xor I(11);
  t11_p13 : entity work.word5op2
    generic map (xor012, xor03, 0, 0, 0, 0, 0, 0, 0)
    port map (T11, P13, I(11), I(5), I(3), I(13), x"00000000", clk);

  -- T12 <= I(12) xor I(6) xor I(4);
  -- T14 <= I(14) xor I(8) xor I(6);
  t12_t14 : entity work.word5op2
    generic map (xor012, xor134, 0,0,0,0,0,0,0)
    port map (T12, T14, I(12), I(6), I(4), I(14), I(8), clk);

  -- T13 <= I(13) xor I(7) xor I(5);
  -- T15 <= I(15) xor I(9) xor I(7);
  t13_t15 : entity work.word5op2
    generic map (xor012, xor134, 0,0,0,0,0,0,0)
    port map (T13, T15, I(13), I(7), I(5), I(15), I(9), clk);

  -- O24 <= LL(Q18 xor T13)  xor L(Q16) xor L(P10);
  -- O19 <= L(Q16 xor T11);
  o24_19 : entity work.word5op2
    generic map(xor0123, xor24, 1, 1, 1, 1, 0, 0, 0)
    port map (O(24), O(19), Q18, T13, Q16, P10, T11, clk);

  -- O20 <= L(Q17 xor T12);
  -- O17 <= Q17
  o20_23 : entity work.word5op2
    generic map (xor01, bypass0, 1, 0, 0, 0, 0, 0, 0)
    port map (O(20), O(17), Q17, T12, zero, zero, zero, clk);

  --O22 <= LL(Q16 xor T11)  xor L(T14);
  --O25 <= LLL(Q16 xor T11) xor LL(T14) xor L(Q17) xor L(P11);
  o22_25 : entity work.word5op2
    generic map (xor012, xor01234, 1, 2, 1, 1, 0, -1, -1)
    port map (O(22), O(25), Q16, T11, T14, Q17, p11, clk);

  -- O23 <= LL(Q17 xor T12)  xor L(T15);
  -- O26 <= LLL(Q17 xor T12) xor LL(T15) xor L(Q18) xor L(P12);
  o23_26 : entity work.word5op2
    generic map (xor012, xor01234, 1, 2, 1, 1, 0, -1, -1)
    port map (O(23), O(26), Q17, T12, T15, Q18, P12, clk);

  -- O21 <= L(Q18 xor T13);
  -- O27 <= LLL(Q18 xor T13) xor LL(P10) xor L(P13) xor LL(T11);
  o21_27 : entity work.word5op2
    generic map (xor01, xor01234, 0, 2, 1, 1, 0, -1, 0)
    port map (O(21), O(27), Q18, T13, P10, P13, T11, clk);

  q12_13 : entity work.word5op2
    generic map (bypass0, bypass1, 0, 0, 0, 0, 0, 0, 0)
    port map (Q12, Q13, I(12), I(13), zero, zero, zero, clk);

  q14_15 : entity work.word5op2
    generic map (bypass0, bypass1, 0, 0, 0, 0, 0, 0, 0)
    port map (Q14, Q15, I(14), I(15), zero, zero, zero, clk);

  o12_13 : entity work.word5op2
    generic map (bypass0, bypass1, 0, 0, 0, 0, 0, 0, 0)
    port map (O(12), O(13), Q12, Q13, zero, zero, zero, clk);

  o14_15 : entity work.word5op2
    generic map (bypass0, bypass1, 0, 0, 0, 0, 0, 0, 0)
    port map (O(14), O(15), Q14, Q15, zero, zero, zero, clk);

  o16_18 : entity work.word5op2
    generic map (bypass0, bypass1, 0, 0, 0, 0, 0, 0, 0)
    port map (O(16), O(18), Q16, Q18, zero, zero, zero, clk);

end expand12;
