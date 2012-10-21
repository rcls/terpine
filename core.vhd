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
  signal Ea : dataset_t (12 to 18);
  signal Ta : dataset_t (11 to 15);
  signal Pa : dataset_t (10 to 13);
  signal Eb : dataset_t (12 to 27);

  signal Ec : dataset_t (24 to 30);
  signal Tc : dataset_t (23 to 27);
  signal Pc : dataset_t (22 to 25);
  signal Ed : dataset_t (24 to 39);

  signal Ee : dataset_t (36 to 42);
  signal Te : dataset_t (35 to 39);
  signal Pe : dataset_t (34 to 37);
  signal Ef : dataset_t (36 to 51);

  signal Eg : dataset_t (48 to 54);
  signal Tg : dataset_t (47 to 51);
  signal Pg : dataset_t (46 to 49);
  signal Eh : dataset_t (48 to 63);

  signal Ei : dataset_t (60 to 66);
  signal Ti : dataset_t (59 to 63);
  signal Pi : dataset_t (58 to 61);
  signal Ej : dataset_t (60 to 75);

  signal Ek : dataset_t (76 to 78);
  signal Tk : dataset_t (71 to 71);

  signal El : dataset_t (79 to 79);

  signal RR : dataset_t (0 to 84);
  signal W : dataset_t (0 to 79);
  signal bypass : words_5_t;
begin
  process
  begin
    wait until rising_edge (clk);

    -- First
    Ea(12 to 15) <= input(12 to 15);
    Ea(16) <= quad(16, input);
    Ea(17) <= quad(17, input);
    Ea(18) <= quad(18, input);

    for i in 11 to 15 loop
      Ta(i) <= input(i) xor input(i-2) xor input(i-6);
    end loop;
    for i in 10 to 13 loop
      Pa(i) <= input(i) xor input(i-2);
    end loop;

    Eb(12 to 18) <= Ea(12 to 18);
    Eb(19) <= L(Ea(16)) xor L(Ta(11));
    Eb(20) <= L(Ea(17)) xor L(Ta(12));
    Eb(21) <= L(Ea(18)) xor L(Ta(13));

    Eb(22) <= LL(Ea(16)) xor LL(Ta(11)) xor L(Ta(14));
    Eb(23) <= LL(Ea(17)) xor LL(Ta(12)) xor L(Ta(15));
    Eb(24) <= LL(Ea(18)) xor LL(Ta(13)) xor L(Ea(16)) xor L(Pa(10));

    Eb(25) <= LLL(Ea(16)) xor LLL(Ta(11)) xor LL(Ta(14)) xor L(Ea(17)) xor L(Pa(11));
    Eb(26) <= LLL(Ea(17)) xor LLL(Ta(12)) xor LL(Ta(15)) xor L(Ea(18)) xor L(Pa(12));
    Eb(27) <= LLL(Ea(18)) xor LLL(Ta(13)) xor LL(Pa(10)) xor L(Pa(13)) xor LL(Ta(11));

    -- Second
    Ec(24 to 27) <= Eb(24 to 27);
    Ec(28) <= quad(28, Eb);
    Ec(29) <= quad(29, Eb);
    Ec(30) <= quad(30, Eb);

    for i in 23 to 27 loop
      Tc(i) <= Eb(i) xor Eb(i-2) xor Eb(i-6);
    end loop;
    for i in 22 to 25 loop
      Pc(i) <= Eb(i) xor Eb(i-2);
    end loop;

    Ed(24 to 30) <= Ec(24 to 30);
    Ed(31) <= L(Ec(28)) xor L(Tc(23));
    Ed(32) <= L(Ec(29)) xor L(Tc(24));
    Ed(33) <= L(Ec(30)) xor L(Tc(25));

    Ed(34) <= LL(Ec(28)) xor LL(Tc(23)) xor L(Tc(26));
    Ed(35) <= LL(Ec(29)) xor LL(Tc(24)) xor L(Tc(27));
    Ed(36) <= LL(Ec(30)) xor LL(Tc(25)) xor L(Ec(28)) xor L(Pc(22));

    Ed(37) <= LLL(Ec(28)) xor LLL(Tc(23)) xor LL(Tc(26)) xor L(Ec(29)) xor L(Pc(23));
    Ed(38) <= LLL(Ec(29)) xor LLL(Tc(24)) xor LL(Tc(27)) xor L(Ec(30)) xor L(Pc(24));
    Ed(39) <= LLL(Ec(30)) xor LLL(Tc(25)) xor LL(Pc(22)) xor L(Pc(25)) xor LL(Tc(23));

    -- Third
    Ee(36 to 39) <= Ed(36 to 39);
    Ee(40) <= quad(40, Ed);
    Ee(41) <= quad(41, Ed);
    Ee(42) <= quad(42, Ed);

    for i in 35 to 39 loop
      Te(i) <= Ed(i) xor Ed(i-2) xor Ed(i-6);
    end loop;
    for i in 34 to 37 loop
      Pe(i) <= Ed(i) xor Ed(i-2);
    end loop;

    Ef(36 to 42) <= Ee(36 to 42);
    Ef(43) <= L(Ee(40)) xor L(Te(35));
    Ef(44) <= L(Ee(41)) xor L(Te(36));
    Ef(45) <= L(Ee(42)) xor L(Te(37));

    Ef(46) <= LL(Ee(40)) xor LL(Te(35)) xor L(Te(38));
    Ef(47) <= LL(Ee(41)) xor LL(Te(36)) xor L(Te(39));
    Ef(48) <= LL(Ee(42)) xor LL(Te(37)) xor L(Ee(40)) xor L(Pe(34));

    Ef(49) <= LLL(Ee(40)) xor LLL(Te(35)) xor LL(Te(38)) xor L(Ee(41)) xor L(Pe(35));
    Ef(50) <= LLL(Ee(41)) xor LLL(Te(36)) xor LL(Te(39)) xor L(Ee(42)) xor L(Pe(36));
    Ef(51) <= LLL(Ee(42)) xor LLL(Te(37)) xor LL(Pe(34)) xor L(Pe(37)) xor LL(Te(35));

    -- Fourth
    Eg(48 to 51) <= Ef(48 to 51);
    Eg(52) <= quad(52, Ef);
    Eg(53) <= quad(53, Ef);
    Eg(54) <= quad(54, Ef);

    for i in 47 to 51 loop
      Tg(i) <= Ef(i) xor Ef(i-2) xor Ef(i-6);
    end loop;
    for i in 46 to 49 loop
      Pg(i) <= Ef(i) xor Ef(i-2);
    end loop;

    Eh(48 to 54) <= Eg(48 to 54);
    Eh(55) <= L(Eg(52)) xor L(Tg(47));
    Eh(56) <= L(Eg(53)) xor L(Tg(48));
    Eh(57) <= L(Eg(54)) xor L(Tg(49));

    Eh(58) <= LL(Eg(52)) xor LL(Tg(47)) xor L(Tg(50));
    Eh(59) <= LL(Eg(53)) xor LL(Tg(48)) xor L(Tg(51));
    Eh(60) <= LL(Eg(54)) xor LL(Tg(49)) xor L(Eg(52)) xor L(Pg(46));

    Eh(61) <= LLL(Eg(52)) xor LLL(Tg(47)) xor LL(Tg(50)) xor L(Eg(53)) xor L(Pg(47));
    Eh(62) <= LLL(Eg(53)) xor LLL(Tg(48)) xor LL(Tg(51)) xor L(Eg(54)) xor L(Pg(48));
    Eh(63) <= LLL(Eg(54)) xor LLL(Tg(49)) xor LL(Pg(46)) xor L(Pg(49)) xor LL(Tg(47));

    -- Fifth
    Ei(60 to 63) <= Eh(60 to 63);
    Ei(64) <= quad(64, Eh);
    Ei(65) <= quad(65, Eh);
    Ei(66) <= quad(66, Eh);

    for i in 59 to 63 loop
      Ti(i) <= Eh(i) xor Eh(i-2) xor Eh(i-6);
    end loop;
    for i in 58 to 61 loop
      Pi(i) <= Eh(i) xor Eh(i-2);
    end loop;

    Ej(60 to 66) <= Ei(60 to 66);
    Ej(67) <= L(Ei(64)) xor L(Ti(59));
    Ej(68) <= L(Ei(65)) xor L(Ti(60));
    Ej(69) <= L(Ei(66)) xor L(Ti(61));

    Ej(70) <= LL(Ei(64)) xor LL(Ti(59)) xor L(Ti(62));
    Ej(71) <= LL(Ei(65)) xor LL(Ti(60)) xor L(Ti(63));
    Ej(72) <= LL(Ei(66)) xor LL(Ti(61)) xor L(Ei(64)) xor L(Pi(58));

    Ej(73) <= LLL(Ei(64)) xor LLL(Ti(59)) xor LL(Ti(62)) xor L(Ei(65)) xor L(Pi(59));
    Ej(74) <= LLL(Ei(65)) xor LLL(Ti(60)) xor LL(Ti(63)) xor L(Ei(66)) xor L(Pi(60));
    Ej(75) <= LLL(Ei(66)) xor LLL(Ti(61)) xor LL(Pi(58)) xor L(Pi(61)) xor LL(Ti(59));

    -- Sixth...
    --Ek(0 to 75) <= Ej;
    Ek(76) <= quad(76, Ej);
    Ek(77) <= quad(77, Ej);
    Ek(78) <= quad(78, Ej);
    Tk(71) <= Ej(71) xor Ej(65) xor Ej(63);
    El(79) <= L(Ek(76) xor Tk(71));

  end process;

  -- We launch into the delay stages as late as possible.
  d0: for i in 0 to 11 generate
    delay: entity work.delay generic map (i +11) port map (input(i), W(i), clk);
  end generate;
  db: for i in 12 to 23 generate
    delay: entity work.delay generic map (i + 9) port map (Eb(i), W(i), clk);
  end generate;
  dd: for i in 24 to 35 generate
    delay: entity work.delay generic map (i + 7) port map (Ed(i), W(i), clk);
  end generate;
  df: for i in 36 to 47 generate
    delay: entity work.delay generic map (i + 5) port map (Ef(i), W(i), clk);
  end generate;
  dh: for i in 48 to 59 generate
    delay: entity work.delay generic map (i + 3) port map (Eh(i), W(i), clk);
  end generate;
  dj: for i in 60 to 75 generate
    delay: entity work.delay generic map (i + 1) port map (Ej(i), W(i), clk);
  end generate;
  dk: for i in 76 to 78 generate
    delay: entity work.delay generic map (i + 0) port map (Ek(i), W(i), clk);
  end generate;
  delay: entity work.delay generic map (78) port map (El(79), W(79), clk);

  RR(4) <= x"67452301";
  RR(3) <= x"efcdab89";
  RR(2) <= x"98badcfe";
  RR(1) <= x"10325476";
  RR(0) <= x"c3d2e1f0";
  rounds: for i in 5 to 84 generate
    round : entity work.round generic map (i)
      port map (RR(i), W(i-5),
                RR(i-1), RR(i-2), RR(i-3), RR(i-4), RR(i-5), clk);
  end generate;

  bypasses: for i in 0 to 4 generate
    byp : entity work.delay generic map (94)
      port map (input (i), bypass (i), clk);
  end generate;

  process
  begin
    wait until rising_edge(clk);
    output(0) <= RR(84) + bypass(0);
    output(1) <= RR(83) + bypass(1);
    output(2) <= (RR(82) rol 30) + bypass(2);
    output(3) <= (RR(81) rol 30) + bypass(3);
    output(4) <= (RR(80) rol 30) + bypass(4);
  end process;
end behavioral;
