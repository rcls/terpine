`default_nettype none

module quad(
  output int unsigned R,
  input int unsigned Din,
  input bit phase_advance,
  input bit clk);

   // phase_advance is two cycles before the first (E) value in Din.
   // Din has an 83 cycle latency to output.

   int unsigned D;
   int unsigned Aa, Ba, Ca, Da;
   int unsigned Rint;

   bit Ald6, Ald5, Ai3, Ai2, Ai1, Ai13, Ai12;
   bit Bld6, Bld5, Bi3, Bi2, Bi1, Bi13, Bi12;
   bit Cld6, Cld5, Ci3, Ci2, Ci1, Ci13, Ci12;
   bit Dld6, Dld5, Di3, Di2, Di1, Di13, Di12;
   bit pa7;

   typedef bit [1:0] twobit;
   twobit Af2, Bf2, Cf2, Df2, Af4, Bf4, Cf4, Df4;

   // Every 20 cycles we get a 5 cycle burst = 160 bit.  Extend this to a 20
   // cycle load on Din.
   cycle cA (Aa, D, Ald5, Af4, Af2, Ai3, Ai2, Ai1, Ai13, Ai12, clk);
   cycle cB (Ba, D, Bld5, Bf4, Bf2, Bi3, Bi2, Bi1, Bi13, Bi12, clk);
   cycle cC (Ca, D, Cld5, Cf4, Cf2, Ci3, Ci2, Ci1, Ci13, Ci12, clk);
   cycle cD (Da, D, Dld5, Df4, Df2, Di3, Di2, Di1, Di13, Di12, clk);

   contgen_cycle gA(Ald6, pa7, Ald5, Af4, Af2, Ai3, Ai2, Ai1, Ai13, Ai12, clk);
   contgen_cycle gB(Bld6, pa7, Bld5, Bf4, Bf2, Bi3, Bi2, Bi1, Bi13, Bi12, clk);
   contgen_cycle gC(Cld6, pa7, Cld5, Cf4, Cf2, Ci3, Ci2, Ci1, Ci13, Ci12, clk);
   contgen_cycle gD(Dld6, pa7, Dld5, Df4, Df2, Di3, Di2, Di1, Di13, Di12, clk);

   bit [4:0] count;
   bit [1:0] unit = 3;                  // Makes testing of cA easier...

   enum bit[1:0] { ZERO, DATA, TRAIL, COUNT } data_load;
   bit out_zero;

   always@(posedge clk) begin
      if (phase_advance)
        unit <= unit + 1;

      if (phase_advance)
        count <= 0;
      else
        count <= count + 1;

      if (count <= 4)
        data_load <= DATA;
      else if (count == 5)
        data_load <= TRAIL;
      else if (count == 15)
        data_load <= COUNT;
      else
        data_load <= ZERO;

      case (data_load)
        DATA:    D <= Din;
        TRAIL:   D <= 32'h80000000;
        COUNT:   D <= 160;
        default: D <= 0;
      endcase

      // unit&count have 7 cycle to A, 86 cycles to final A, 82 cycles to
      // final 'E'.
      case (unit)
        0: Rint <= Aa;
        1: Rint <= Ba;
        2: Rint <= Ca;
        3: Rint <= Da;
      endcase

      out_zero <= (count < 1 || count > 5);
      if (out_zero)
        Rint <= 0;

      R <= Rint;

      pa7 <= (count >= 19);

      Ald6 <= (unit == 0) && count < 16;
      Bld6 <= (unit == 1) && count < 16;
      Cld6 <= (unit == 2) && count < 16;
      Dld6 <= (unit == 3) && count < 16;
   end
endmodule
