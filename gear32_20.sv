// Final 100 bits of 5 x 32 input bits.  3 cycle delay.
// E - discard
// C[15:0] + D[31:28] -> phase B (1,2)
// B[3:0] + C[31:16]  -> phase A (1,2)
// B[23:4]            -> phase E (2)
// A[11:0] + B[31:24] -> phase D (2,3)
// A[31:12]           -> phase C (3)
module gear32_20(
  output bit [19:0] Q,
  input bit [31:0] Din,
  input bit A_or_C,
  input bit A_or_B,
  input bit clk);

   bit [63:0] W;
   bit[19:0] QQ;

   assign W[63:32] = Din;

   always@(posedge clk) begin
      W[31:0] <= Din;

      if (!A_or_B)
        QQ <= W[31:12];                 // output A on in C+1 = in E->D
      else if (A_or_C)
        QQ <= W[43:24];                 // output B on in D+1 = in A->E
      else
        QQ <= W[55:36];                 // output C on in E+1 = in B->A

      Q <= QQ;
      if (A_or_B && !A_or_C)
        Q <= W[35:16];                  // output D on in A (B->A)

      if (A_or_C && !A_or_B)
        Q <= W[47:28];                  // output E on in B (C->B)
   end

endmodule
