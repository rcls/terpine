
module fcs_append(
  input bit [3:0] D,
  input bit DV,
  output bit [3:0] Q,
  output bit QV,
  input bit clk);

   bit [3:0] fcs_nibble_count;

   bit [31:0] fcs = 32'hffffffff;

   always@(posedge clk)
     if (DV) begin
        Q <= D;
        QV <= 1;

        fcs_nibble_count <= 4'b1000;
        fcs <= (fcs >> 4)
          ^       (D[0] ^ fcs[0] ? 32'hedb88320 >> 3 : 0)
            ^     (D[1] ^ fcs[1] ? 32'hedb88320 >> 2 : 0)
              ^   (D[2] ^ fcs[2] ? 32'hedb88320 >> 1 : 0)
                ^ (D[3] ^ fcs[3] ? 32'hedb88320      : 0);
     end
     else begin
        Q <= fcs[3:0] ^ 4'hf;
        QV <= fcs_nibble_count[3];
        fcs <= 32'hf0000000 | (fcs >> 4);
        fcs_nibble_count <= fcs_nibble_count + fcs_nibble_count[3];
     end

endmodule


module preamble_prepend(
  input bit [3:0] D,
  input bit DV,
  output bit [3:0] Q,
  output bit QV,
  input bit clk);

   // Delay D by 16 clock cycles.
   bit [3:0] Delay[1:16];
   bit DDV[1:16];
   bit [3:0] DD;

   always@(posedge clk) begin
      // This assumes the packet is at least 64 bits long.  If it's not you
      // lose.  Don't do short packets, they're meant to be at least 512 bits...
      QV <= 1;
      if (DDV[16])
        Q <= Delay[16];
      else if (DDV[15])
        Q <= 4'hd;
      else if (DV)
        Q <= 4'h5;
      else
        QV <= 0;

      Delay <= { D, Delay[1:15] };
      DDV <= { DV, DDV[1:15] };
   end;
endmodule

module preamble_remove(
  input bit [3:0] D,
  input bit DV,
  output bit [3:0] Q,
  output bit QV,
  input bit clk);

   bit in_frame;
   bit discard;

   always@(posedge clk)
   if (DV) begin
      if (!in_frame && D == 4'hd && !discard)
        in_frame <= 1;
      if (!in_frame && D != 4'h5 && D != 4'hd)
        discard <= 1;
      Q <= D;
      QV <= in_frame;
   end
   else begin
      in_frame <= 0;
      discard <= 0;
      QV <= 0;
   end
endmodule

// We don't actually remove the FCS, we just assert 'valid' after the
// frame if it's good.
module fcs_check(
  input bit[3:0] D,
  input bit DV,
  output bit Valid,
  input bit clk);

   bit [31:0] fcs;

   assign Valid = (prev_DV && !DV && fcs == 32'hdebb20e3);

   bit prev_DV;

   always@(posedge clk) begin
      fcs <= (fcs >> 4)
        ^       (D[0] ^ fcs[0] ? 32'hedb88320 >> 3 : 0)
          ^     (D[1] ^ fcs[1] ? 32'hedb88320 >> 2 : 0)
            ^   (D[2] ^ fcs[2] ? 32'hedb88320 >> 1 : 0)
              ^ (D[3] ^ fcs[3] ? 32'hedb88320      : 0);

      prev_DV <= DV;
      if (!DV)
        fcs <= 32'hffffffff;
   end

endmodule

module mii_frame(
  input  bit[3:0] D, input  bit DV,
  output bit[3:0] Q, output bit QV, input bit clk);

   bit[3:0] F;
   bit FV;

   fcs_append fa(D, DV, F, FV, clk);
   preamble_prepend pp(F, FV, Q, QV, clk);
endmodule


module mii_deframe(
  input  bit[3:0] D, input  bit DV,
  output bit[3:0] Q, output bit QV,
  output bit Valid, input bit clk);

   bit[3:0] F;
   bit FV;

   preamble_remove pr(D, DV, Q, QV, clk);
   fcs_check fa(Q, QV, Valid, clk);
endmodule
