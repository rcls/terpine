library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity wrap is
  port (R : out word_t;
        Din : in word_t;
        strobe0, strobe1, strobe2, strobe3 : in boolean;
        sel : in natural range 0 to 3;
        clk : in std_logic);
end wrap;

architecture behaviour of wrap is
  signal R0, R1, R2, R3 : word_t;
  signal D0, D1, D2, D3 : word_t;
  signal loadA : std_logic;
  signal loadB : std_logic;
  signal loadC : std_logic;
  signal loadD : std_logic;
  signal phase_advance : std_logic;

  attribute rloc of q0 : label is "X0Y0";
  attribute rloc of q1 : label is "X16Y0";
  attribute rloc of q2 : label is "X0Y16";
  attribute rloc of q3 : label is "X16Y16";
  attribute rloc of R : signal is col32(-4,2);
  attribute rloc of p : label is "X-5Y0";
  attribute rloc of D0 : signal is col32(-6,2);
  attribute rloc of D1 : signal is col32(-7,2);
  attribute rloc of D2 : signal is col32(-8,2);
  attribute rloc of D3 : signal is col32(-9,2);
begin
  p : entity work.phase port map (
    phase_advance, loadA, loadB, loadC, loadD, clk);
  q0 : entity work.quad port map (
    R0, D0, phase_advance, loadA, loadB, loadC, loadD, clk);
  q1 : entity work.quad port map (
    R1, D1, phase_advance, loadA, loadB, loadC, loadD, clk);
  q2 : entity work.quad port map (
    R2, D2, phase_advance, loadA, loadB, loadC, loadD, clk);
  q3 : entity work.quad port map (
    R3, D3, phase_advance, loadA, loadB, loadC, loadD, clk);
  process
  begin
    wait until rising_edge(clk);
    if strobe0 then
      D0 <= Din;
    end if;
    if strobe1 then
      D1 <= Din;
    end if;
    if strobe2 then
      D2 <= Din;
    end if;
    if strobe3 then
      D3 <= Din;
    end if;
    case sel is
      when 0 => R <= R0;
      when 1 => R <= R1;
      when 2 => R <= R2;
      when 3 => R <= R3;
    end case;
  end process;
end behaviour;
