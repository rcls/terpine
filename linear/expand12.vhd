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

architecture behavioural of expand12 is
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

  signal Q : dataset_t (12 to 18);
  signal T : dataset_t (11 to 15);
  signal P : dataset_t (10 to 13);
begin
  process
  begin
    wait until rising_edge(clk);

    Q(12 to 15) <= I(12 to 15);
    for j in 16 to 18 loop
      Q(j) <= L(I(j-3) xor I(j-8) xor I(j-14) xor I(j-16));
    end loop;
    for j in 11 to 15 loop
      T(j) <= I(j) xor I(j-6) xor I(j-8);
    end loop;
    for j in 10 to 13 loop
      P(j) <= I(j) xor I(j-2);
    end loop;

    O(12 to 18) <= Q(12 to 18);

    O(19) <= L(Q(16) xor T(11));
    O(20) <= L(Q(17) xor T(12));
    O(21) <= L(Q(18) xor T(13));

    O(22) <= LL(Q(16) xor T(11))  xor L(T(14));
    O(23) <= LL(Q(17) xor T(12))  xor L(T(15));
    O(24) <= LL(Q(18) xor T(13))  xor L(Q(16)) xor L(P(10));

    O(25) <= LLL(Q(16) xor T(11)) xor LL(T(14)) xor L(Q(17)) xor L(P(11));
    O(26) <= LLL(Q(17) xor T(12)) xor LL(T(15)) xor L(Q(18)) xor L(P(12));
    O(27) <= LLL(Q(18) xor T(13)) xor LL(P(10)) xor L(P(13)) xor LL(T(11));
  end process;
end behavioural;
