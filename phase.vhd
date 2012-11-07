-- Generate the phase signals for cycle.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

library UNISIM;
use UNISIM.VComponents.all;

entity phase is
  port (phase_advance : out std_logic;
        loadA : out std_logic;
        loadB : out std_logic;
        loadC : out std_logic;
        loadD : out std_logic;
        clk : in std_logic);
end phase;

architecture behavioral of phase is
  signal pa : std_logic := '0';
  signal ldA, ldB, ldC, ldD : std_logic := '0';
  signal count : natural range 0 to 19 := 0;
  signal phase : natural range 0 to 3 := 0;

  attribute rloc of ldA, ldB, ldC, ldD : signal is "X0Y0";
  attribute rloc of count : signal is "X0Y1";
  attribute rloc of pa : signal is "X0Y2";
  attribute rloc of phase : signal is "X0Y3";

  function b_to_l (b : boolean) return std_logic is
  begin -- god vhdl sucks.
    if b then return '1'; else return '0'; end if;
  end b_to_l;
begin
  --l0 : bufg port map (i=> ld0, o=> load0);
  --l1 : bufg port map (i=> ld1, o=> load1);
  --l2 : bufg port map (i=> ld2, o=> load2);
  --l3 : bufg port map (i=> ld3, o=> load3);

  --p_a : bufg port map (i=>pa, o=> phase_advance);
  loadA <= ldA;
  loadB <= ldB;
  loadC <= ldC;
  loadD <= ldD;
  phase_advance <= pa;

  process
  begin
    wait until rising_edge(clk);
    if count = 19 then
      count <= 0;
      phase <= (phase + 1) mod 4;
    else
      count <= count + 1;
    end if;

    pa <= b_to_l(count = 19);
    ldA <= b_to_l(phase = 0 and count < 16);
    ldB <= b_to_l(phase = 1 and count < 16);
    ldC <= b_to_l(phase = 2 and count < 16);
    ldD <= b_to_l(phase = 3 and count < 16);
  end process;
end behavioral;
