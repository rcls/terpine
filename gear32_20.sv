// This has a 3 cycle latency for 5x32 to 5x20.  The final 96 bits are used.
module gear32_20(
  output bit [19:0] Q,
  input bit [31:0] D,
  input bit A_or_C,
  input bit A_or_B,
  input bit clk);

   parameter width = 96;

   function int unsigned rol30(int unsigned X);
     rol30 = (X << 30) | (X >> 2);
   endfunction

   bit [31:0] maskC = 32'hffffffff;
   bit [31:0] maskB = 32'hffffffff;
   bit [31:0] maskA = 32'hffffffff;

   initial begin
      if (width <= 64)
        maskC = 0;
      else if (width < 96)
        maskC = 32'hffffffff << (96 - width);

      if (width <= 32)
        maskB = 0;
      else if (width < 64)
        maskB = 32'hffffffff << (64 - width);

      if (width < 32)
        maskA = 32'hffffffff << (32 - width);
   end

   assign Q = state[19:0];

   bit [59:0] state;

   always@(posedge clk) begin
      state <= {20'h00000, state[59:20]};

      if (A_or_C && !A_or_B)
        state[35: 4] <= rol30(D) & maskC;

      if (!A_or_C && A_or_B)
        state[47:16] <= D & maskB;

      if (A_or_C && A_or_B)
        state[59:28] <= D & maskA;
   end
endmodule
