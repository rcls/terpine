module cycle_test;

   typedef int unsigned uint;

   uint data[0:15] = {
    32'h54686973, 32'h20697320, 32'h61207465, 32'h73742e0a,
    32'h80000000, 32'h00000000, 32'h00000000, 32'h00000000,
    32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
    32'h00000000, 32'h00000000, 32'h00000000, 32'h00000080
   };

   uint R;
   uint D;
   uint Din;
   bit load;
   bit phase_advance;
   bit [1:0] phase_out;
   bit clk;

   cycle dut(R, Din, load, phase_advance, phase_out, clk);


   // load and phase_advance has 7 cycle latency to A.
   // Data starts the cycle after load.
   integer i = 0;
   initial begin : testit
      for (int i = 60; i < 1000; i = i + 1) begin
         clk = 0;
         load = (i % 80 < 16);
         Din = D;
         if (i % 80 < 16)
           D = data[i % 80];
         else
           D = 1234;
         phase_advance = (i % 20 == 19);
         #5;
         clk = 1;
         #5;
      end
   end
endmodule
