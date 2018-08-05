module cycle(output int unsigned R,
  input int unsigned Din,
  input bit load,
  input bit phase_advance,
  output bit [1:0] phase_out,
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

   uint A;
   uint C2, D2;
   (* dont_touch = "true" *)
   uint I1, I2, I3;

   (* dont_touch = "true" *)
   bit init1, init2, init3, init4;
   bit init12;
   bit init13;
   // bit init_3_4;

   uint W;

   bit pa5, pa6, ld;

   bit [1:0] phase5 = 3;
   bit [1:0] phase4 = 3;
   bit [1:0] munged_phase3;
   (* dont_touch = "true" *)
   bit [1:0] munged_phase2;

   assign R = A;
   assign phase_out = phase5;

   // Put a route-through onto init2 so that it can be LUT-combined.
   bit init2_buf;
   (* keep = "true" *)
   LUT1 #(.INIT(2'b10)) init2r(.O(init2_buf), .I0(init2));

   // Ditto C2[3:0]....
   bit [3:0] C2_buf;
   (* keep = "true" *) LUT1 #(.INIT(2'b10)) C2r0(.O(C2_buf[0]), .I0(C2[0]));
   (* keep = "true" *) LUT1 #(.INIT(2'b10)) C2r1(.O(C2_buf[1]), .I0(C2[1]));
   (* keep = "true" *) LUT1 #(.INIT(2'b10)) C2r2(.O(C2_buf[2]), .I0(C2[2]));
   (* keep = "true" *) LUT1 #(.INIT(2'b10)) C2r3(.O(C2_buf[3]), .I0(C2[3]));

   always@(posedge clk) begin
      uint WS[2:14];
      uint W_2_15;
      uint W_3_16;

      // 5 cycle latency into A.
      if (ld)
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

   // Stop control set generation for C2 by breaking it's logic out.
   (* keep = "true" *)
   uint C3;
   always_comb
     if (init12 && init13)
       C3 = rol30(iA);
     else if (init12)
       C3 = rol30(iB);
     else if (init13)
       C3 = iC;
     else
       C3 = rol30(A);

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
      D2[3:0]  <= C2_buf[3:0];
      D2[31:4] <= C2[31:4];
      C2 <= C3;

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

      // Control signals.
      ld <= load;
      pa6 <= phase_advance;
      pa5 <= pa6;

      if (pa6 && ld)
        phase5 <= 0;
      else if (pa6)
        phase5 <= phase5 + 1;

      phase4 <= phase5;

      init4 <= (phase4 == 3 && pa5);
      init3 <= init4;
      init2 <= init3;
      init1 <= init2_buf;

      init12 <= init2 || init3;
      init13 <= init2 || init4;

      if (init4)
        munged_phase3 <= 3;
      else if (phase4 == 3)
        munged_phase3 <= 1;
      else
        munged_phase3 <= phase4;

      if (init2)
        munged_phase2 <= 3;
      else
        munged_phase2 <= munged_phase3;
   end
endmodule
