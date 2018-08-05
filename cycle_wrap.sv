module cycle_wrap(output bit Q,
  output bit [1:0] po,
  input bit D,
  input bit QE,
  input bit DE,
  input bit ld,
  input bit pa,
  input bit clk);

   int unsigned Din;
   int unsigned R;
   bit load;
   bit phase_advance;
   bit [1:0] phase_out;

   int unsigned DD;
   int unsigned QQ;

   cycle cycle(R, Din, load, phase_advance, phase_out, clk);

   always@(posedge clk) begin
      DD <= (DD << 1) | D;
      if (DE) begin
         Din <= DD;
         load <= ld;
         phase_advance <= pa;
      end
      if (QE)
        QQ <= R;
      else
        QQ <= QQ << 1;

      if (QE)
        po <= phase_out;

      Q <= QQ >> 31;
   end
endmodule
