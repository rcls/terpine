module cycle_test;

   typedef int unsigned uint;

   uint data[0:15] = {
    32'h54686973, 32'h20697320, 32'h61207465, 32'h73742031,
    32'h32332e0a, 32'h80000000, 32'h00000000, 32'h00000000,
    32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
    32'h00000000, 32'h00000000, 32'h00000000, 32'h000000a0
   };

   uint R;
   uint D;
   uint Din;

   // Control lines we generate.
   bit load6;
   bit phase_advance7;
   bit clk;

   // Control lines from contgen_cycle.
   bit load5;
   bit [1:0] phase4;
   bit [1:0] munged_phase2;
   bit init3;
   bit init2;
   bit init1;
   bit init13;
   bit init12;

   contgen_cycle cg(load6, phase_advance7,
     load5, phase4, munged_phase2, init3, init2, init1, init13, init12, clk);

   cycle dut(R, Din,
     load5, phase4, munged_phase2, init3, init2, init1, init13, init12, clk);

   // load6 and phase_advance7 has 7 cycle latency to A.
   // Data starts the cycle after load6.
   integer i = 0;
   initial begin : testit
      for (int i = 60; i < 1000; i = i + 1) begin
         clk = 0;
         load6 = (i % 80 < 16);
         Din = D;
         if (i % 80 < 16)
           D = data[i % 80];
         else
           D = 1234;
         phase_advance7 = (i % 20 == 19);
         #5;
         clk = 1;
         #5;
      end
   end
endmodule
