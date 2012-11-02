library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.delay;
use work.defs.all;

entity core is
  port (input : in words_16_t;
        output : out words_5_t;
        clk : in std_logic);
end core;

architecture core of core is
  attribute keep_hierarchy of core : architecture is "soft";

  function L (x : word_t) return word_t is
  begin
    return x rol 1;
  end;
  function quad (i : natural; x : dataset_t) return word_t is
  begin
    return L (x(i-3) xor x(i-8) xor x(i-14) xor x(i-16));
  end;

  signal Ea : dataset_t (12 to 27);
  signal Eb : dataset_t (24 to 39);
  signal Ec : dataset_t (36 to 51);
  signal Ed : dataset_t (48 to 63);
  signal Ee : dataset_t (60 to 75);

  signal Ef : dataset_t (76 to 78);
  signal Tf : dataset_t (71 to 71);

  signal Eg : dataset_t (79 to 79);

  signal W : dataset_t (0 to 79);

  signal oB : word_t;
  signal oC1 : word_t;
  signal oD1 : word_t;
  signal oE1 : word_t;
  signal oE2 : word_t;

  function dly0(n, adj : integer) return integer is
  begin
    return n * 2 + adj + (n * 2) / line_len;
  end function;
  function dly1(n, adj : integer) return integer is
  begin
    return n * 2 + 1 + adj + (n * 2 + 1) / line_len;
  end function;

  signal A, B, C, D, E : dataset_t (0 to core_len);
  attribute keep of A, B, C, D, E : signal is "soft";

begin

  expA : entity work.expand12b port map (input, Ea, clk);
  expB : entity work.expand12b port map (Ea, Eb, clk);
  expC : entity work.expand12b port map (Eb, Ec, clk);
  expD : entity work.expand12b port map (Ec, Ed, clk);
  expE : entity work.expand12b port map (Ed, Ee, clk);

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
  da: for i in 0 to 5 generate
    delay: entity work.double_delay generic map (dly0(i,3), dly1(i,3))
      port map (input(2*i), W(2*i), input(2*i+1), W(2*i+1), clk);
  end generate;
  db: for i in 6 to 11 generate
    delay: entity work.double_delay generic map (dly0(i,1), dly1(i,1))
      port map (Ea(2*i), W(2*i), Ea(2*i+1), W(2*i+1), clk);
  end generate;
  dd: for i in 12 to 17 generate
    delay: entity work.double_delay generic map (dly0(i,-1), dly1(i,-1))
      port map (Eb(2*i), W(2*i), Eb(2*i+1), W(2*i+1), clk);
  end generate;
  df: for i in 18 to 23 generate
    delay: entity work.double_delay generic map (dly0(i,-3), dly1(i,-3))
      port map (Ec(2*i), W(2*i), Ec(2*i+1), W(2*i+1), clk);
  end generate;
  dh: for i in 24 to 29 generate
    delay: entity work.double_delay generic map (dly0(i,-5), dly1(i,-5))
      port map (Ed(2*i), W(2*i), Ed(2*i+1), W(2*i+1), clk);
  end generate;
  dj: for i in 30 to 37 generate
    delay: entity work.double_delay generic map (dly0(i,-7), dly1(i,-7))
      port map (Ee(2*i), W(2*i), Ee(2*i+1), W(2*i+1), clk);
  end generate;

  penul: entity work.double_delay generic map (dly0(38,-8), dly1(38,-8))
    port map (Ef(76), W(76), Ef(77), W(77), clk);
  delay: entity work.double_delay generic map (dly0(39,-8), dly1(39,-9))
    port map (Ef(78), W(78), Eg(79), W(79), clk);

  A(0) <= x"67452301";
  B(0) <= x"efcdab89";
  C(0) <= x"98badcfe" rol 2;
  D(0) <= x"10325476" rol 2;
  E(0) <= x"c3d2e1f0" rol 2;
  lines: for i in 0 to core_len-1 generate
    constant dir : integer := 1 - 2 * (i mod 2);
    signal Cbuf, Dbuf: word_t;
    signal Ai, Bi, Ci, Di, Ei : word_t;
    attribute keep of Cbuf, Dbuf : signal is "soft";
  begin
    lne: entity work.line generic map (i*line_len, dir)
      port map (W(i*line_len to i*line_len + line_len - 1),
                Ai, Bi, Ci, Di, Ei,
                A(i+1), B(i+1), Cbuf, Dbuf, E(i+1),
                clk);
    process
    begin
      wait until rising_edge(clk);
      Ai <= A(i);
      Bi <= B(i);
      Ci <= C(i);
      Di <= D(i);
      Ei <= E(i);
      C(i+1) <= Cbuf;
      D(i+1) <= Dbuf;
    end process;
  end generate;

  process
  begin
    wait until rising_edge(clk);

    output(0) <= A(core_len) + x"67452301";
    oB <= B(core_len);
    output(1) <= oB + x"efcdab89";
    oC1 <= C(core_len) rol 30;
    output(2) <= oC1 + x"98badcfe";
    oD1 <= D(core_len) rol 30;
    output(3) <= oD1 + x"10325476";
    oE1 <= E(core_len) rol 30;
    oE2 <= oE1;
    output(4) <= oE2 + x"c3d2e1f0";
  end process;
end core;
