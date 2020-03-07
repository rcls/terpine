module block_wrap(input bit [19:0] command,
  input bit [2:0] opcode,
  input bit async_strobe,
  input bit sys_clk_i_0,

  output bit [1:24] fifo_empty,
  input bit [1:24] fifo_req,
  output bit fifo_bit,
  input bit fifo_rst,
  input bit fifo_clk);

   bit [1:24] fifo_bits;
   bit clk1, clk2, clk3, clk4;

   PLLE2_BASE #(
     .CLKFBOUT_MULT(14),
     .CLKIN1_PERIOD(10),
     .CLKOUT0_DIVIDE(4),
     .CLKOUT1_DIVIDE(4),
     .CLKOUT2_DIVIDE(4),
     .CLKOUT3_DIVIDE(4),
     .CLKOUT0_PHASE(0),
     .CLKOUT1_PHASE(90),
     .CLKOUT2_PHASE(180),
     .CLKOUT3_PHASE(270)
     ) pll (
     .CLKIN1(sys_clk_i_0),
     .CLKOUT0(clk1), .CLKOUT1(clk2), .CLKOUT2(clk3), .CLKOUT3(clk4),
     .CLKFBOUT(pllfb), .CLKFBIN(pllfb), .PWRDWN(0), .RST(0));

   block #(1) b1(command, opcode, async_strobe, clk1,
     fifo_empty[1], fifo_req[1], fifo_bits[1], fifo_rst, fifo_clk);

   block #(2) b2(command, opcode, async_strobe, clk2,
     fifo_empty[2], fifo_req[2], fifo_bits[2], fifo_rst, fifo_clk);

   block #(3) b3(command, opcode, async_strobe, clk3,
     fifo_empty[3], fifo_req[3], fifo_bits[3], fifo_rst, fifo_clk);

   block #(4) b4(command, opcode, async_strobe, clk4,
     fifo_empty[4], fifo_req[4], fifo_bits[4], fifo_rst, fifo_clk);

   block #(5) b5(command, opcode, async_strobe, clk2,
     fifo_empty[5], fifo_req[5], fifo_bits[5], fifo_rst, fifo_clk);

   block #(6) b6(command, opcode, async_strobe, clk3,
     fifo_empty[6], fifo_req[6], fifo_bits[6], fifo_rst, fifo_clk);

   block #(7) b7(command, opcode, async_strobe, clk4,
     fifo_empty[7], fifo_req[7], fifo_bits[7], fifo_rst, fifo_clk);

   block #(8) b8(command, opcode, async_strobe, clk1,
     fifo_empty[8], fifo_req[8], fifo_bits[8], fifo_rst, fifo_clk);

   block #(9) b9(command, opcode, async_strobe, clk3,
     fifo_empty[9], fifo_req[9], fifo_bits[9], fifo_rst, fifo_clk);

   block #(10) b10(command, opcode, async_strobe, clk4,
     fifo_empty[10], fifo_req[10], fifo_bits[10], fifo_rst, fifo_clk);

   block #(11) b11(command, opcode, async_strobe, clk1,
     fifo_empty[11], fifo_req[11], fifo_bits[11], fifo_rst, fifo_clk);

   block #(12) b12(command, opcode, async_strobe, clk2,
     fifo_empty[12], fifo_req[12], fifo_bits[12], fifo_rst, fifo_clk);


   block #(13) b13(command, opcode, async_strobe, clk4,
     fifo_empty[13], fifo_req[13], fifo_bits[13], fifo_rst, fifo_clk);

   block #(14) b14(command, opcode, async_strobe, clk1,
     fifo_empty[14], fifo_req[14], fifo_bits[14], fifo_rst, fifo_clk);

   block #(15) b15(command, opcode, async_strobe, clk2,
     fifo_empty[15], fifo_req[15], fifo_bits[15], fifo_rst, fifo_clk);

   block #(16) b16(command, opcode, async_strobe, clk3,
     fifo_empty[16], fifo_req[16], fifo_bits[16], fifo_rst, fifo_clk);

   block #(17) b17(command, opcode, async_strobe, clk1,
     fifo_empty[17], fifo_req[17], fifo_bits[17], fifo_rst, fifo_clk);

   block #(18) b18(command, opcode, async_strobe, clk2,
     fifo_empty[18], fifo_req[18], fifo_bits[18], fifo_rst, fifo_clk);

   block #(19) b19(command, opcode, async_strobe, clk3,
     fifo_empty[19], fifo_req[19], fifo_bits[19], fifo_rst, fifo_clk);

   block #(20) b20(command, opcode, async_strobe, clk4,
     fifo_empty[20], fifo_req[20], fifo_bits[20], fifo_rst, fifo_clk);

   block #(21) b21(command, opcode, async_strobe, clk2,
     fifo_empty[21], fifo_req[21], fifo_bits[21], fifo_rst, fifo_clk);

   block #(22) b22(command, opcode, async_strobe, clk3,
     fifo_empty[22], fifo_req[22], fifo_bits[22], fifo_rst, fifo_clk);

   block #(23) b23(command, opcode, async_strobe, clk4,
     fifo_empty[23], fifo_req[23], fifo_bits[23], fifo_rst, fifo_clk);

   block #(24) b24(command, opcode, async_strobe, clk1,
     fifo_empty[24], fifo_req[24], fifo_bits[24], fifo_rst, fifo_clk);

   always@(posedge fifo_clk) fifo_bit = |fifo_bits;

endmodule
