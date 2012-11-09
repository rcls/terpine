library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity cycle is
  port (R : out word_t;
        Din : in word_t;
        load : in std_logic;
        phase_advance : in std_logic;
        phase_out : out natural range 0 to 3;
        clk : in std_logic);
end cycle;

-- 'load' to 'A' is 6 cycle latency.
-- 'Din' to 'A' is 5 cycle latency.
-- 'phase_advance' to 'A' is 7 cycle latency.
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

  constant k0 : word_t := x"5a827999";
  constant k1 : word_t := x"6ed9eba1";
  constant k2 : word_t := x"8f1bbcdc";
  constant k3 : word_t := x"ca62c1d6";

  signal phase4, phase5 : natural range 0 to 3 := 3;
  signal munged_phase2, munged_phase3 : natural range 0 to 3;

  signal A : word_t;
  signal C2 : word_t;
  signal D2 : word_t;
  signal I1 : word_t;
  signal I2 : word_t;
  signal I3 : word_t;

  signal init1_to_5, init2_to_6, init3_to_7, init4_to_8, init5_to_9
    : std_logic := '0';

  signal W : word_t;
  signal W2_15 : word_t;
  signal W3_16 : word_t;
  signal W8 : word_t;
  signal W14 : word_t;

  signal pa5, pa6, ld, ldb : std_logic := '0';

  attribute keep_hierarchy of cycle : architecture is "true";

  attribute rloc of A : signal is col32(0,0);
  attribute rloc of init1_to_5 : signal is "X0Y0";

  attribute rloc of C2, W2_15 : signal is col(3,7,4) & col(1,0,28);

  attribute rloc of I1 : signal is col32(2,0);

  --attribute rloc of D2 : signal is col32(4,1);
  attribute rloc of D2 : signal is col(4,1,28) & col(3,0,4);

  attribute rloc of I2 : signal is col32(4,0);
  attribute rloc of init3_to_7 : signal is "X4Y0";

  attribute rloc of W : signal is col32(5,0);
  attribute rloc of W3_16 : signal is col(5,1,28) & col(3,2,4);

  attribute rloc of I3 : signal is col32(6,0);
  attribute rloc of init4_to_8 : signal is "X5Y0";

  attribute rloc of d7, d13: label is "X7Y0";

  attribute rloc of munged_phase2 : signal is "X1Y-1";

  attribute rloc of phase5, pa6, init5_to_9 : signal is "X3Y4";
  attribute rloc of phase4 : signal is "X5Y0";
  attribute rloc of pa5, ld, ldb : signal is "X3Y3";
  attribute rloc of munged_phase3 : signal is "X3Y3";
  attribute rloc of init2_to_6 : signal is "X3Y3";

  attribute use_sync_set of phase5, munged_phase3 : signal is "no";
  attribute use_sync_reset of phase5, munged_phase3 : signal is "no";
  attribute use_clock_enable of phase5 : signal is "no";

  function bb (b : boolean) return std_logic is
  begin
    if b then return '1'; else return '0'; end if;
  end bb;
begin
  R <= A;
  phase_out <= phase5;

  d7 : entity work.delay generic map (7) port map (w, w8, clk);
  d13 : entity work.delay generic map (13) port map (w, w14, clk);

  w2_15s: for I in 0 to 31 generate
    type int8 is array (0 to 7) of integer;
    constant col : int8 := (1, 1, 1, 1, 1, 1, 1, 3);
    attribute rloc of w2_15b : label is loc(col(I/4), I/4);
  begin
    w2_15b: entity work.bit5op generic map (M0 xor M1, I, "5FF")
      port map (W2_15(I), W(I), W14(I), 'X', 'X', 'X', clk);
  end generate;

  process
    variable kk, addendA, addend1, addend2 : word_t;
  begin
    wait until rising_edge(clk);

    -- 1 cycle latency into A.
    addendA := A rol 5;
    if init1_to_5 = '1' then
      addendA := x"00000000";
    end if;
    A <= addendA + I1;

    -- 2 cycle latency into A.
    case munged_phase2 is -- 1 instead of 3; 3 means init2_to_6.
      when 0 => addend1 := F0(A, C2, D2);
      when 1 => addend1 := F1(A, C2, D2);
      when 2 => addend1 := F2(A, C2, D2);
      when 3 => addend1 := x"00000000";
    end case;
    I1 <= addend1 + I2;

    -- Look aheads for these, and set up for init 1.
    C2 <= A rol 30;
    D2 <= C2;

    -- 3 cycle latency into A.
    addend2 := D2;
    if init3_to_7 = '1' then -- init3
      addend2 := x"00000000";
    end if;
    I2 <= addend2 + I3;

    -- 4 cycle latency into A.
    case phase4 is
      when 0 => kk := k0;
      when 1 => kk := k1;
      when 2 => kk := k2;
      when 3 => kk := k3;
    end case;
    if init4_to_8 = '1' then
      kk := x"00000000";
    end if;
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
    ldb <= load;
    ld <= ldb;
    -- 'init' is just before phase, so we want init5_to_9 to go back 0 on the
    -- same cycle phase5 advances.
    if ldb = '1' and ld = '0' then
      init5_to_9 <= '1';
    elsif pa6 = '1' then
      init5_to_9 <= '0';
    end if;
    init4_to_8 <= init5_to_9;
    init3_to_7 <= init4_to_8;
    init2_to_6 <= init3_to_7;
    init1_to_5 <= init2_to_6;
    pa6 <= phase_advance;
    pa5 <= pa6;

    if pa6 = '1' and ld = '1' then
      phase5 <= 0;
    elsif pa6 = '1' then
      phase5 <= (phase5 + 1) mod 4;
    end if;
    phase4 <= phase5;

    if init4_to_8 = '1' then
      munged_phase3 <= 3;
    elsif phase4 = 3 then
      munged_phase3 <= 1;
    else
      munged_phase3 <= phase4;
    end if;
    munged_phase2 <= munged_phase3;
  end process;

end cycle;
