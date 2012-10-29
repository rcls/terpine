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

  -- There is intentially redundancy here, to reduce fan out.
  signal init1 : boolean;
  signal init2 : boolean;
  signal init1_or_2 : boolean;
  signal init2_or_3 : boolean;
  signal init1_or_3 : boolean;

  signal W : word_t;
  signal W2 : word_t;
  signal W3 : word_t;
  signal W8 : word_t;
  signal W14 : word_t;
  signal W15 : word_t;
  signal W16 : word_t;

  signal pa : std_logic;
  signal ld : std_logic;

  function loc(x, y : integer) return string is
  begin
    return "X" & integer'image(x) & "Y" & integer'image(y);
  end loc;
  function lc4(x, y : integer) return string is
  begin
    return loc(x, y) & " " & loc(x, y) & " " & loc(x, y) & " " & loc(x, y);
  end lc4;
  function col8(x, y : integer) return string is
  begin
    return  lc4(x,y+7) &" "& lc4(x,y+6) &" "& lc4(x,y+5) &" "& lc4(x,y+4)
      &" "& lc4(x,y+3) &" "& lc4(x,y+2) &" "& lc4(x,y+1) &" "& lc4(x,y);
  end col8;

  attribute keep_hierarchy : string;
  attribute keep_hierarchy of cycle : architecture is "soft";

  attribute use_clock_enable : string;
  attribute use_sync_set : string;
  attribute use_sync_reset : string;
  attribute hu_set : string;
  attribute rloc : string;

  attribute hu_set of A : signal is "adders";
  attribute hu_set of W2 : signal is "adders";
  attribute rloc of A : signal is col8(1,1);
  attribute rloc of W2 : signal is col8(1,1);

  attribute hu_set of I1 : signal is "adders";
  attribute rloc of I1 : signal is col8(2,1);

  attribute hu_set of C2 : signal is "adders";
  attribute hu_set of W15 : signal is "adders";
  attribute rloc of C2 : signal is col8(3,1);
  attribute rloc of W15 : signal is col8(8,1);

  attribute hu_set of I2 : signal is "adders";
  attribute hu_set of D2 : signal is "adders";
  attribute rloc of I2 : signal is col8(4,1);
  attribute rloc of D2 : signal is col8(4,1);

  attribute hu_set of W : signal is "adders";
  attribute hu_set of W3 : signal is "adders";
  attribute rloc of W : signal is col8(6,1);
  attribute rloc of W3 : signal is col8(6,1);

  attribute hu_set of I3 : signal is "adders";
  attribute hu_set of W16 : signal is "adders";
  attribute rloc of I3 : signal is col8(5,1);
  attribute rloc of W16 : signal is col8(5,1);

  attribute hu_set of init1 : signal is "adders";
  attribute rloc of init1 : signal is "X1Y0";

  attribute hu_set of munged_phase2 : signal is "adders";
  attribute rloc of munged_phase2 : signal is "X2Y0";

  attribute hu_set of phase3 : signal is "adders";
  attribute hu_set of pa : signal is "adders";
  attribute rloc of phase3 : signal is "X5Y0";
  attribute rloc of pa : signal is "X5Y0";
  attribute use_clock_enable of phase3 : signal is "no";
  attribute use_sync_set of phase3 : signal is "no";
  attribute use_sync_reset of phase3 : signal is "no";

  attribute hu_set of init2_or_3 : signal is "adders";
  attribute hu_set of init2 : signal is "adders";
  attribute rloc of init2_or_3 : signal is "X4Y0";
  attribute rloc of init2 : signal is "X4Y0";

  attribute hu_set of w8 : signal is "adders";
  attribute hu_set of w14 : signal is "adders";
  attribute rloc of w8 : signal is col8(7,1);
  attribute rloc of w14 : signal is col8(7,1);

begin
  R <= A;

  d7_13 : entity work.double_delay generic map (7, 13)
    port map (w, w, w8, w14, clk);
  --d14_16 : entity work.double_delay generic map (13, 15)
  --  port map (w, w, w14, w16, clk);

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
    D2 <= C2;
    C2 <= A rol 30;
    if init1_or_3 and init1_or_2 then -- init1.
      C2 <= iA rol 30;
    end if;
    if init1_or_2 and not init1_or_3 then -- init2.
      C2 <= iB rol 30;
    end if;
    if init1_or_3 and not init1_or_2 then -- init3.
      C2 <= iC;
    end if;

    -- 3 cycle latency into A.
    I2 <= D2 + I3;
    if init2_or_3 and not init2 then -- init3
      I2 <= iE + I3;
    end if;
    if init2 then
      I2 <= iD + I3;
    end if;

    if init2_or_3 then
      munged_phase2 <= 3;
    elsif phase3 = 3 then
      munged_phase2 <= 1;
    else
      munged_phase2 <= phase3;
    end if;

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

    init2_or_3 <= (phase3 = 3 and pa = '1') or init2_or_3;
    init2 <= init2_or_3;
    if init2 then
      init2 <= false;
      init2_or_3 <= false;
    end if;
    init1_or_2 <= init2_or_3;
    init1_or_3 <= (phase3 = 3 and pa = '1') or (init1_or_2 and not init1_or_3);
    init1 <= init2;

    -- 5 cycle latency into A.
    if ld = '1' then
      W <= Din;
    else
      W <= (W3 xor W8 xor W14 xor W16) rol 1;
    end if;
    W2 <= W;
    W3 <= W2;
    W15 <= W14;
    W16 <= W15;

    ld <= load;
    pa <= phase_advance;

  end process;
end cycle;
