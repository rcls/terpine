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
        phase_out : out natural range 0 to 3;
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

  signal phase4, phase5 : natural range 0 to 3 := phase_init;
  signal munged_phase2, munged_phase3 : natural range 0 to 3;

  signal A, A30 : word_t;
  signal C2 : word_t;
  signal D2 : word_t;
  signal I1 : word_t;
  signal I2 : word_t;
  signal I3 : word_t;

  -- There is intentially redundancy here, to reduce fan out.
  signal init1, init2, init3 : std_logic := '0';
  signal init1_or_2 : std_logic := '0';
  signal init2_or_3 : std_logic := '0';
  signal init3_or_4 : std_logic := '0';

  signal W : word_t;
  signal W2_15 : word_t;
  signal W3_16 : word_t;
  signal W8 : word_t;
  signal W14 : word_t;

  signal pa : std_logic;
  signal ld : std_logic;

  attribute keep_hierarchy of cycle : architecture is "true";

  attribute rloc of A : signal is col32(1,1);

  attribute rloc of C2 : signal is col32(2,1);
  attribute rloc of W2_15 : signal is col32(2,1);

  attribute rloc of I1 : signal is col32(3,1);

  --attribute rloc of D2 : signal is col32(4,1);
  attribute rloc of D2 : signal is col(1,3,24) &" "& col(4,1,8);

  attribute rloc of I2 : signal is col32(5,1);
  attribute rloc of init2_or_3, init2 : signal is "X5Y1";

  attribute rloc of W, W3_16 : signal is
    col(6, 0, 4) &" "& col(6, 1, 28);

  attribute rloc of I3 : signal is col32(7,1);

  attribute rloc of d7, d13: label is "X8Y1";

  attribute rloc of init1 : signal is "X1Y1";

  attribute rloc of munged_phase2 : signal is "X2Y0";

  attribute rloc of phase5 : signal is "X4Y5";
  attribute rloc of phase4 : signal is "X7Y1";
  attribute rloc of pa, ld : signal is "X4Y4";
  attribute rloc of munged_phase3 : signal is "X4Y3";
  attribute rloc of init1_or_2, init3_or_4, init3 : signal is "X4Y3";

  attribute use_sync_set of munged_phase3 : signal is "no";
  attribute use_sync_reset of munged_phase3 : signal is "no";

  function bb (b : boolean) return std_logic is
  begin
    if b then return '1'; else return '0'; end if;
  end bb;
begin
  R <= A;
  phase_out <= phase5;

  d7 : entity work.delay generic map (7) port map (w, w8, clk);
  d13 : entity work.delay generic map (13) port map (w, w14, clk);

  A30 <= A rol 30;
  c2w2_15s: for I in 0 to 31 generate
    constant kA : bv32 := const(iA rol 30, I);
    constant kB : bv32 := const(iB rol 30, I);
    constant kC : bv32 := const(iC, I);
    type ia is array (0 to 7) of integer;
    constant col : ia := (2, 2, 2, 2, 2, 2, 2, 4);
    attribute rloc of c2_w2_15 : label is loc(col(I/4), I/4 + 1);
  begin
    c2_w2_15 : entity work.bit5op2 generic map (
      M0 xor M1,
      (not M2 and not M3 and M4) or
      (    M2 and not M3 and kA) or
      (    M2 and     M3 and kB) or
      (not M2 and     M3 and kC), I)
      port map (W2_15(I), C2(I),
                W(I), W14(I), init1_or_2, init2_or_3, A30(I),
                clk);
  end generate;

  process
    variable kk : word_t;
  begin
    wait until rising_edge(clk);

    -- 1 cycle latency into A.
    A <= (A rol 5) + I1;
    if init1 = '1' then
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
    D2 <= C2;
    --C2 <= A rol 30;
    --if init1_or_3 and init1_or_2 then -- init1.
    --  C2 <= iA rol 30;
    --end if;
    --if init1_or_2 and not init1_or_3 then -- init2.
    --  C2 <= iB rol 30;
    --end if;
    --if init1_or_3 and not init1_or_2 then -- init3.
    --  C2 <= iC;
    --end if;

    -- 3 cycle latency into A.
    I2 <= D2 + I3;
    if init2_or_3 = '1' and not init2 = '1' then -- init3
      I2 <= iE + I3;
    end if;
    if init2 = '1' then
      I2 <= iD + I3;
    end if;

    -- 4 cycle latency into A.
    case phase4 is
      when 0 => kk := k0;
      when 1 => kk := k1;
      when 2 => kk := k2;
      when 3 => kk := k3;
    end case;
    I3 <= kk + W;

    -- 5 cycle latency into A.
    if ld = '1' then
      W <= Din;
    else
      W <= (W3_16 xor W8 xor W14) rol 1;
    end if;
    --W2_15 <= W xor W14;
    W3_16 <= W2_15;

    -- Control signals.
    ld <= load;
    pa <= phase_advance;

    if phase_advance = '1' then
      if ld = '1' then
        phase5 <= 0;
      else
        phase5 <= (phase5 + 1) mod 4;
      end if;
    end if;
    phase4 <= phase5;

    init3_or_4 <= (bb(phase4 = 3) and pa) or (init3_or_4 and not init3);
    init3 <= init3_or_4 and not init3;
    init2 <= init3;
    init1 <= init2;
    init2_or_3 <= init3_or_4;
    init1_or_2 <= init2_or_3;

    if init3_or_4 = '1' then
      munged_phase3 <= 3;
    elsif phase4 = 3 then
      munged_phase3 <= 1;
    else
      munged_phase3 <= phase4;
    end if;
    munged_phase2 <= munged_phase3;
  end process;

end cycle;
