`default_nettype none

(* keep_hierarchy = "true" *)
module cycle(output int unsigned A,
  input int unsigned Din,               // 6-cycle latency to A.
  input bit load5,
  input bit [1:0] phase4,
  input bit [1:0] munged_phase2,
  input bit init3,
  input bit init2,
  input bit init1,
  input bit init13,
  input bit init12,
  input bit clk);

   typedef int unsigned uint;

   uint iA = 32'h67452301;
   uint iB = 32'hefcdab89;
   uint iC = 32'h98badcfe;
   uint iD = 32'h10325476;
   uint iE = 32'hc3d2e1f0;

   uint k0 = 32'h5a827999;
   uint k1 = 32'h6ed9eba1;
   uint k2 = 32'h8f1bbcdc;
   uint k3 = 32'hca62c1d6;

   function uint F0(uint B, uint C, uint D);
      F0 = (C & B) | (D & ~B);
   endfunction
   function uint F1(uint B, uint C, uint D);
      F1 = B ^ C ^ D;
   endfunction
   function uint F2(uint B, uint C, uint D);
      F2 = (B & C) | (C & D) | (D & B);
   endfunction
   function uint rol1(uint X);
     rol1 = (X << 1) | (X >> 31);
   endfunction
   function uint rol5(uint X);
     rol5 = (X << 5) | (X >> 27);
   endfunction
   function uint rol30(uint X);
     rol30 = (X << 30) | (X >> 2);
   endfunction;

   (* extract_reset = "false" *)
   uint C2;
   uint D2;
   uint I1;
   uint I2;
   uint I3;

   uint W;

   always@(posedge clk) begin
      uint WS[2:14];
      uint W_2_15;
      uint W_3_16;

      // 5 cycle latency into A.
      if (load5)
        W <= Din;
      else
        W <= rol1(W_3_16 ^ WS[8] ^ WS[14]);

      // W = W1.
      W_2_15 <= W ^ WS[14];
      W_3_16 <= W_2_15;
      WS[2] <= W;
      for (int i = 2; i < 14; ++i)
        WS[i+1] <= WS[i];
   end;

   always@(posedge clk) begin
      // 1 cycle latency into A.
      if (init1)
        A <= rol5(iA) + F0(iB, iC, iD) - F0(iA, rol30(iB), iC) + I1;
      else
        A <= rol5(A) + I1;

      // 2 cycle latency into A.  phase '3' means an init.
      case (munged_phase2)
        2'b00: I1 <= F0(A, C2, D2) + I2;
        2'b01: I1 <= F1(A, C2, D2) + I2;
        2'b10: I1 <= F2(A, C2, D2) + I2;
        2'b11: I1 <= F0(iA, rol30(iB), iC) + I2;
      endcase

      // Look aheads for these, and set up for init 1.
      if (init12 && init13)
        C2 <= rol30(iA);
      else if (init12)
        C2 <= rol30(iB);
      else if (init13)
        C2 <= iC;
      else
        C2 <= rol30(A);

      D2 <= C2;

      // 3 cycle latency into A.
      if (init2)
        I2 <= iD + I3;
      else if (init3)
        I2 <= iE + I3;
      else
        I2 <= D2 + I3;

      // 4 cycle latency into A.
      case (phase4)
        0: I3 <= W + k0;
        1: I3 <= W + k1;
        2: I3 <= W + k2;
        3: I3 <= W + k3;
      endcase
   end
endmodule

module contgen_cycle(
  input bit load6,
  input bit phase_advance7,
  output bit load5,
  output bit [1:0] phase4,
  output bit [1:0] munged_phase2,
  output bit init3,
  output bit init2,
  output bit init1,
  output bit init13,
  output bit init12,
  input bit clk);

   bit phase_advance6, phase_advance5;
   bit [1:0] phase5 = 3;
   initial phase4 <= 3;
   bit [1:0] munged_phase3;
   bit init4, init23, init24;

   always@(posedge clk) begin
      load5 <= load6;
      phase4 <= phase5;
      munged_phase2 <= munged_phase3;

      init3 <= init4;
      init2 <= init3;
      init1 <= init2;

      init12 <= init23;
      init13 <= init24;
   end

   always@(posedge clk) begin
      phase_advance6 <= phase_advance7;

      if (phase_advance6 && load6)
        phase5 <= 0;
      else if (phase_advance6)
        phase5 <= phase5 + 1;

      phase_advance5 <= phase_advance6;

      init23 <= init3 || init4;
      init24 <= init3 || (phase5 == 0 && phase_advance5);

      phase4 <= phase5;
      init4 <= (phase5 == 0 && phase_advance5);
      init3 <= init4;

      if (init3 || init4)
        munged_phase3 <= 3;
      else if (phase4 == 3)
        munged_phase3 <= 1;
      else
        munged_phase3 <= phase4;
   end

endmodule
