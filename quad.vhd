-- Drive 4 instances of cycle.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity quad is
  port (R : out word_t;
        Din : in word_t;
        phase_advance : in std_logic;
        loadA : in std_logic;
        loadB : in std_logic;
        loadC : in std_logic;
        loadD : in std_logic;
        clk : in std_logic);
end quad;

architecture quad of quad is
  attribute keep_hierarchy : string;
  attribute keep_hierarchy of quad : architecture is "soft";
  signal phase : natural range 0 to 3;
  signal rA : word_t;
  signal rB : word_t;
  signal rC : word_t;
  signal rD : word_t;
  signal pa : std_logic;
  signal ldA : std_logic;
  signal ldB : std_logic;
  signal ldC : std_logic;
  signal ldD : std_logic;

  -- FIXME, these need to disappear...
  attribute rloc of pa : signal is "X0Y0";
  attribute rloc of loadA, loadB, loadC, loadD : signal is "X1Y0";
  attribute rloc of phase : signal is "X2Y0";

  attribute rloc of cA : label is "X0Y2";
  attribute rloc of cB : label is "X8Y2";
  attribute rloc of cC : label is "X0Y10";
  attribute rloc of cD : label is "X8Y10";

  attribute rloc of R : signal is
    "X4Y9 X4Y9 X4Y9 X4Y9 X4Y8 X4Y8 X4Y8 X4Y8 " &
    "X12Y9 X12Y9 X12Y9 X12Y9 X12Y8 X12Y8 X12Y8 X12Y8 " &
    "X4Y17 X4Y17 X4Y17 X4Y17 X4Y16 X4Y16 X4Y16 X4Y16 " &
    "X12Y17 X12Y17 X12Y17 X12Y17 X12Y16 X12Y16 X12Y16 X12Y16";

begin
  cA : entity work.cycle generic map (3) port map (rA, Din, ldA, pa, clk);
  cB : entity work.cycle generic map (2) port map (rB, Din, ldB, pa, clk);
  cC : entity work.cycle generic map (1) port map (rC, Din, ldC, pa, clk);
  cD : entity work.cycle generic map (0) port map (rD, Din, ldD, pa, clk);

  process
  begin
    wait until rising_edge(clk);
    pa <= phase_advance;
    ldA <= loadA;
    ldB <= loadB;
    ldC <= loadC;
    ldD <= loadD;

    if phase_advance = '1' then
      if loadA = '1' then
        phase <= 0;
      else
        phase <= (phase + 1) mod 4;
      end if;
    end if;
    case phase is
      when 0 => R <= rA;
      when 1 => R <= rB;
      when 2 => R <= rC;
      when 3 => R <= rD;
    end case;
  end process;
end quad;
