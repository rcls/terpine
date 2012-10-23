library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.delay;
use work.defs.all;

entity core is
  port (input : in words_16_t;
        output : out words_5_t;
        --bmon : out dataset_t (0 to 64);
        clk : in std_logic);
end core;

architecture behavioral of core is
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
  function quad (i : natural; x : dataset_t) return word_t is
  begin
    return L (x(i-3) xor x(i-8) xor x(i-10) xor x(i-14));
  end;

  signal Ea : dataset_t (12 to 27);
  signal Eb : dataset_t (24 to 39);
  signal Ec : dataset_t (36 to 51);
  signal Ed : dataset_t (48 to 63);
  signal Ee : dataset_t (60 to 75);

  signal Ef : dataset_t (76 to 78);
  signal Tf : dataset_t (71 to 71);

  signal Eg : dataset_t (79 to 79);

  signal R : dataset_t (0 to 84);
  signal W : dataset_t (0 to 79);
  signal bypass : words_5_t;
begin

  expA : entity work.expand12 port map (input, Ea, clk);
  expB : entity work.expand12 port map (Ea, Eb, clk);
  expC : entity work.expand12 port map (Eb, Ec, clk);
  expD : entity work.expand12 port map (Ec, Ed, clk);
  expE : entity work.expand12 port map (Ed, Ee, clk);

  process
  begin
    wait until rising_edge (clk);

    Ef(76) <= quad(76, Ee);
    Ef(77) <= quad(77, Ee);
    Ef(78) <= quad(78, Ee);
    Tf(71) <= Ee(71) xor Ee(65) xor Ee(63);

    Eg(79) <= L(Ef(76) xor Tf(71));

  end process;

  -- We launch into the delay stages as late as possible.
  d0: for i in 0 to 11 generate
    delay: entity work.delay generic map (i +11) port map (input(i), W(i), clk);
  end generate;
  db: for i in 12 to 23 generate
    delay: entity work.delay generic map (i + 9) port map (Ea(i), W(i), clk);
  end generate;
  dd: for i in 24 to 35 generate
    delay: entity work.delay generic map (i + 7) port map (Eb(i), W(i), clk);
  end generate;
  df: for i in 36 to 47 generate
    delay: entity work.delay generic map (i + 5) port map (Ec(i), W(i), clk);
  end generate;
  dh: for i in 48 to 59 generate
    delay: entity work.delay generic map (i + 3) port map (Ed(i), W(i), clk);
  end generate;
  dj: for i in 60 to 75 generate
    delay: entity work.delay generic map (i + 1) port map (Ee(i), W(i), clk);
  end generate;
  dk: for i in 76 to 78 generate
    delay: entity work.delay generic map (i + 0) port map (Ef(i), W(i), clk);
  end generate;
  delay: entity work.delay generic map (78) port map (Eg(79), W(79), clk);

  R(4) <= x"67452301";
  R(3) <= x"efcdab89";
  R(2) <= x"98badcfe";
  R(1) <= x"10325476";
  R(0) <= x"c3d2e1f0";
  rounds: for i in 0 to 79 generate
    round : entity work.round generic map (i)
      port map (R(i+5), W(i),
                R(i+4), R(i+3), R(i+2), R(i+1), R(i), clk);
  end generate;

  bypasses: for i in 0 to 4 generate
    byp : entity work.delay generic map (94)
      port map (input (i), bypass (i), clk);
  end generate;

  process
  begin
    wait until rising_edge(clk);

    -- FIXME - this is not right.
    output(0) <= R(84) + bypass(0);
    output(1) <= R(83) + bypass(1);
    output(2) <= (R(82) rol 30) + bypass(2);
    output(3) <= (R(81) rol 30) + bypass(3);
    output(4) <= (R(80) rol 30) + bypass(4);
  end process;
end behavioral;
