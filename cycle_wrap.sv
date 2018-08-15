module cycle_wrap(output bit Q,
  input bit D,
  input bit QE,
  input bit DE,
  input bit ld,
  input bit pa,
  input bit clk);

   int unsigned Din;
   int unsigned R;

   int unsigned DD;
   (* keep = "TRUE" *)
   int unsigned QQ;

   // Control lines we generate.
   bit load7;
   bit phase_advance7;

   // Control lines from contgen_cycle.
   bit load6;
   bit [1:0] phase4;
   bit [1:0] munged_phase2;
   bit init3;
   bit init2;
   bit init1;
   bit init13;
   bit init12;

   contgen_cycle cg(load7, phase_advance7,
     load6, phase4, munged_phase2, init3, init2, init1, init13, init12, clk);

   cycle cycle(R, Din,
     load6, phase4, munged_phase2, init3, init2, init1, init13, init12, clk);

   always@(posedge clk) begin
      DD <= (DD << 1) | D;
      if (DE) begin
         Din <= DD;
         load7 <= ld;
         phase_advance7 <= pa;
      end
      if (QE)
        QQ <= R;

      Q <= |QQ;
   end
endmodule
