library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity cycle is
  generic (phase_init : natural range 0 to 3);
  port (R : out word_t;
        Din : in word_t;
        load : in std_logic;
        phase_advance : in std_logic;
        clk : in std_logic);
end cycle;

-- 'load' to 'A' is 6 cycle latency.
-- 'Din' to 'A' is 5 cycle latency.
-- 'phase_advance' to 'A' is 5 cycle latency.
-- Then 79 cycles to first result.
architecture cycle of cycle is
  function F0(B : word_t; C : word_t; D : word_t) return word_t is
  begin
      return (B and C) or (not B and D);
  end F0;

  function F1(B : word_t; C : word_t; D : word_t) return word_t is
  begin
      return B xor C xor D;
  end F1;

  function F2(B : word_t; C : word_t; D : word_t) return word_t is
  begin
      return (B and C) or (C and D) or (D and B);
  end F2;

  constant iA : word_t := x"67452301";
  constant iB : word_t := x"efcdab89";
  constant iC : word_t := x"98badcfe";
  constant iD : word_t := x"10325476";
  constant iE : word_t := x"c3d2e1f0";

  constant k0 : word_t := x"5a827999";
  constant k1 : word_t := x"6ed9eba1";
  constant k2 : word_t := x"8f1bbcdc";
  constant k3 : word_t := x"ca62c1d6";

  signal phase3 : natural range 0 to 3 := phase_init;
  signal munged_phase2 : natural range 0 to 3;

  signal A : word_t;
  signal C2 : word_t;
  signal D2 : word_t;
  signal I1 : word_t;
  signal I2 : word_t;
  signal I3 : word_t;

  signal init1 : boolean;
  signal init2 : boolean;
  signal init3 : boolean;

  signal W : word_t;
  signal W3 : word_t;
  signal W8 : word_t;
  signal W14 : word_t;
  signal W16 : word_t;

  signal pa : std_logic;
  signal ld : std_logic;

  attribute keep_hierarchy : string;
  attribute keep_hierarchy of cycle : architecture is "soft";

begin
  R <= A;

  d3 : entity work.delay generic map (2) port map (w, w3, clk);
  d8 : entity work.delay generic map (5) port map (w3, w8, clk);
  d14: entity work.delay generic map (6) port map (w8, w14, clk);
  d16: entity work.delay generic map (2) port map (w14, w16, clk);

  process
    variable kk : word_t;
  begin
    wait until rising_edge(clk);

    -- 1 cycle latency into A.
    A <= (A rol 5) + I1;
    if init1 then
      A <= (iA rol 5) + F0(iB, iC, iD) - F0(iA, iB rol 30, iC) + I1;
    end if;

    -- 2 cycle latency into A.
    case munged_phase2 is -- 1 instead of 3; 3 means init1 or init2.
      when 0 => I1 <= F0(A, C2, D2) + I2;
      when 1 => I1 <= F1(A, C2, D2) + I2;
      when 2 => I1 <= F2(A, C2, D2) + I2;
      when 3 => I1 <= F0(iA, iB rol 30, iC) + I2;
    end case;

    -- Look aheads for these, and set up for init 1.
    C2 <= A rol 30;
    D2 <= C2;
    if init1 then -- is this needed?
      C2 <= iA rol 30;
    end if;
    if init2 then
      C2 <= iB rol 30;
      D2 <= iC;
    end if;
    init1 <= init2;

    -- 3 cycle latency into A.
    I2 <= D2 + I3;
    if init3 then
      I2 <= iE + I3;
    end if;
    if init2 then
      I2 <= iD + I3;
    end if;

    if init2 or init3 then
      munged_phase2 <= 3;
    elsif phase3 = 3 then
      munged_phase2 <= 1;
    else
      munged_phase2 <= phase3;
    end if;

    init2 <= init3;

    -- 4 cycle latency into A.
    if pa = '1' then
      case phase3 is                    -- Look-ahead...
        when 0 => kk := k1;
        when 1 => kk := k2;
        when 2 => kk := k3;
        when 3 => kk := k0;
      end case;
    else
      case phase3 is
        when 0 => kk := k0;
        when 1 => kk := k1;
        when 2 => kk := k2;
        when 3 => kk := k3;
      end case;
    end if;
    I3 <= kk + W;

    if pa = '1' then
      if ld = '1' or phase3 = 3 then
        phase3 <= 0;
      else
        phase3 <= phase3 + 1;
      end if;
    end if;

    init3 <= phase3 = 3 and pa = '1';

    -- 5 cycle latency into A.
    if ld = '1' then
      W <= Din;
    else
      W <= (W3 xor W8 xor W14 xor W16) rol 1;
    end if;

    ld <= load;
    pa <= phase_advance;
  end process;
end cycle;
