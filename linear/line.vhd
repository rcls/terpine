-- Links together a number of rounds.  (10 for now).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.defs.all;

entity line is
  generic (N : natural; dir : integer);
  port (W : in dataset_t(0 to line_len - 1);
        Ai : in word_t;
        Bi : in word_t;
        Ci : in word_t;
        Di : in word_t;
        Ei : in word_t;
        Ao : out word_t;
        Bo : out word_t;
        Co : out word_t;
        Do : out word_t;
        Eo : out word_t;

        clk : in std_logic);
end line;

architecture line of line is
  signal A : dataset_t(0 to line_len + 1);
  signal B : dataset_t(0 to line_len - 1);
  signal C : dataset_t(0 to line_len);

  attribute keep of Ai, Bi, Ci, Di, Ei : signal is "true";
  attribute keep_hierarchy of line : architecture is "soft";

begin
  A(1) <= Ai;
  A(0) <= Bi;
  B(0) <= Ci;
  C(1) <= Di;
  C(0) <= Ei;

  ll: for i in 0 to line_len - 1 generate
    attribute rloc of r: label is "X" & integer'image(dir*i*4) & "Y0";
  begin
    r: entity work.round generic map ((N+i) / 20, dir)
      port map (A(i+2), W(i),
                A(i+1), A(i), B(i), C(i+1), C(i), clk);
  end generate;
  dd: for i in 0 to line_len - 2 generate
    signal BB, CC : word_t;
    attribute rloc of BB : signal is col8(dir*(i*4+7),0);
    attribute rloc of CC : signal is col8(dir*(i*4+4),0);
  begin
      B(i+1) <= BB;
      C(i+2) <= CC;
    process
    begin
      wait until rising_edge(clk);
      BB <= A(i);
      CC <= B(i);
    end process;
  end generate;

  Ao <= A(line_len + 1);
  Bo <= A(line_len);
  Co <= A(line_len - 1);
  Do <= B(line_len - 1);
  Eo <= C(line_len);

end line;
