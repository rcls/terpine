-- Generate the phase signals for cycle.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

library UNISIM;
use UNISIM.VComponents.all;

entity phase is
  port (paA, paB, paC, paD : out std_logic := '0';
        ldA, ldB, ldC, ldD : out std_logic := '0';
        clk : in std_logic);
end phase;

architecture behavioral of phase is
  signal p0, p1, p2, p3, p4 : std_logic := '0';
  signal fiver : integer range 0 to 16 := 0;

  attribute rloc of paA, paB, paC, paD : signal is "X0Y0";
  attribute rloc of ldA, ldB, ldC, ldD : signal is "X0Y1";
  attribute rloc of fiver : signal is "X0Y2";
  attribute rloc of p0, p1, p2, p3, p4 : signal is "X0Y3";

  function bb (b : boolean) return std_logic is
  begin -- god vhdl sucks.
    if b then return '1'; else return '0'; end if;
  end bb;
begin
  process
  begin
    wait until rising_edge(clk);
    p1 <= p0;
    p2 <= p1;
    p3 <= p2;
    p4 <= p3;
    p0 <= not (p0 or p1 or p2 or p3);

    if p4 = '1' then
      if fiver = 16 then
        fiver <= 0;
      else
        fiver <= fiver + 1;
      end if;
    end if;

    if fiver = 2 and p0 = '1' then
      ldA <= '1';
    end if;
    if fiver = 6 and p1 = '1' then
      ldA <= '0';
      ldB <= '1';
    end if;
    if fiver = 10 and p2 = '1' then
      ldB <= '0';
      ldC <= '1';
    end if;
    if fiver = 14 and p3 = '1' then
      ldC <= '0';
      ldD <= '1';
    end if;
    if fiver = 1 and p4 = '1' then
      ldD <= '0';
    end if;

    paA <= bb(fiver = 3 or fiver = 7 or fiver = 11 or fiver = 15) and p0;
    paB <= bb(fiver = 7 or fiver = 11 or fiver = 15 or fiver = 2) and p1;
    paC <= bb(fiver = 11 or fiver = 15 or fiver = 2 or fiver = 6) and p2;
    paD <= bb(fiver = 15 or fiver = 2 or fiver = 6 or fiver = 11) and p3;
  end process;
end behavioral;
