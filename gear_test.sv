// 32'h49b4935a, 32'hb56cf304, 32'h15d7de0c, 32'h8f0e13d1,
// 32'h9a6240d3, 32'hd2eb56da, 32'hb2c8c946, 32'h728fe2de,
module gear_test();

int unsigned inputs[0:29] = {
    32'h129f9573, 32'h49b4935a, 32'hb56cf304, 32'h15d7de0c, 32'h8f0e13d1,
    0,0,0,0,0,
    32'h653838a2, 32'h9a6240d3, 32'hd2eb56da, 32'hb2c8c946, 32'h728fe2de,
    0,0,0,0,0,
    -1,-1,-1,-1,-1,
    0,0,0,0,0
};


   bit clk, A_or_C, A_or_B;
   bit [31:0] Din;
   bit [19:0] Q;

   gear32_20 gear(Q, Din, A_or_C, A_or_B, clk);

   initial while (1) begin
      clk <= 0;
      #5;
      clk <= 1;
      #5;
   end

   initial for (int i = 0; i < 30; ++i) begin
      Din = inputs[i];
      #10;
   end

   initial while (1) begin
      A_or_C = 0;
      A_or_B = 0;
      #20;
      A_or_C = 1;
      #10;
      A_or_C = 0;
      A_or_B = 1;
      #10;
      A_or_C = 1;
      #10;
   end

endmodule
