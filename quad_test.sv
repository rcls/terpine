module quad_test;

   typedef int unsigned uint;

   uint data[0:4] = {
    32'h54686973, 32'h20697320, 32'h61207465, 32'h73742031,
    32'h32332e0a };

   uint R;
   uint Din;
   bit phase_advance;
   bit clk;

   int count;

   quad q(R, Din, phase_advance, clk);

   initial begin
      while (1) begin
         #5;
         clk <= 1;
         #5;
         clk <= 0;
      end
   end

   always@(posedge clk) begin
      phase_advance <= (count == 18);
      if (count == 19)
        count <= 0;
      else
        count <= count + 1;

      if (count <= 4)
        Din <= data[count];
      else
        Din <= 32'h96877869;
   end
endmodule
