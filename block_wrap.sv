`default_nettype none

module block_wrap(
  input bit[1:0] rmii_RX,
  input bit rmii_RX_CRS_DV,

  output bit eth_rst,
  output bit[1:0] rmii_TX,
  output bit rmii_TX_EN,
  input bit link_led,
  input bit sys_diff_clock_clk_p,
  input bit sys_diff_clock_clk_n);

   bit [19:0] command;
   bit [2:0] opcode;
   bit strobe;
   bit rmii_CLK_pad;

   bit [24:1] fifo_req;
   bit [24:1] fifo_empty;
   bit [24:1] fifo_oflow;
   bit [24:1] fifo_bits;
   bit pllfb, mii_clk;
   bit [2:0] fast_clk, slow_clk, clk;
   bit fifo_rst;
   bit xadc_alarm;

   IBUFDS sys_clock(.I(sys_diff_clock_clk_p), .IB(sys_diff_clock_clk_n),
     .O(rmii_CLK_pad));

   BUFGMUX_CTRL clkmux0(.S(xadc_alarm), .I0(fast_clk[0]), .I1(slow_clk[0]), .O(clk[0]));
   BUFGMUX_CTRL clkmux1(.S(xadc_alarm), .I0(fast_clk[1]), .I1(slow_clk[1]), .O(clk[1]));
   BUFGMUX_CTRL clkmux2(.S(xadc_alarm), .I0(fast_clk[2]), .I1(slow_clk[2]), .O(clk[2]));

   MMCME2_BASE #(
     .CLKFBOUT_MULT_F(21),
     .CLKIN1_PERIOD(20),
     .CLKOUT0_DIVIDE_F(3),
     .CLKOUT1_DIVIDE(3),
     .CLKOUT2_DIVIDE(3),
     .CLKOUT3_DIVIDE(6),
     .CLKOUT4_DIVIDE(6),
     .CLKOUT5_DIVIDE(6),
     .CLKOUT6_DIVIDE(42),
     .CLKOUT0_PHASE(0),
     .CLKOUT1_PHASE(120),
     .CLKOUT2_PHASE(240),
     .CLKOUT3_PHASE(0),
     .CLKOUT4_PHASE(240),
     .CLKOUT5_PHASE(120)
     ) pll (
     .CLKIN1(rmii_CLK_pad),
     .CLKOUT0(fast_clk[0]), .CLKOUT1(fast_clk[1]), .CLKOUT2(fast_clk[2]),
     .CLKOUT3(slow_clk[0]), .CLKOUT4(slow_clk[1]), .CLKOUT5(slow_clk[2]),
     .CLKOUT6(mii_clk),
     .CLKFBOUT(pllfb), .CLKFBIN(pllfb), .PWRDWN(0), .RST(0));

   genvar i;
   for (i = 1; i <= 24; i = i + 1) begin:b
      block #(i) b(command, opcode, strobe, clk[i % 3],
     fifo_empty[i], fifo_oflow[i], fifo_req[i], fifo_bits[i],
     fifo_rst, mii_clk);
   end

   // "At least 1µs" for the PHY.
   bit [7:0] fifo_rst_count = 8'h80;
   assign fifo_rst = fifo_rst_count[7];
   assign eth_rst = !fifo_rst_count[7];
   always@(posedge mii_clk)
     fifo_rst_count <= fifo_rst_count + fifo_rst;

   bit [3:0] rmii_D;
   bit [3:0] mii_Q;
   bit [1:0] rmii_DV;
   bit mii_QV;

   // The IDDR in "same edge mode" has Q2 earlier than Q1!
   IDDR #(.DDR_CLK_EDGE("SAME_EDGE")) rmii_RX0
     (.D(rmii_RX[0]), .Q2(rmii_D[0]), .Q1(rmii_D[2]), .C(mii_clk));
   IDDR #(.DDR_CLK_EDGE("SAME_EDGE")) rmii_RX1
     (.D(rmii_RX[1]), .Q2(rmii_D[1]), .Q1(rmii_D[3]), .C(mii_clk));
   IDDR #(.DDR_CLK_EDGE("SAME_EDGE")) rmii_RDV
     (.D(rmii_RX_CRS_DV), .Q2(rmii_DV[0]), .Q1(rmii_DV[1]), .C(mii_clk));

   ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) rmii_TX0
     (.Q(rmii_TX[0]), .D1(mii_Q[0]), .D2(mii_Q[2]), .C(mii_clk));
   ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) rmii_O1
     (.Q(rmii_TX[1]), .D1(mii_Q[1]), .D2(mii_Q[3]), .C(mii_clk));
   ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) rmii_TXDV
     (.Q(rmii_TX_EN), .D1(mii_QV), .D2(mii_QV), .C(mii_clk));

   bit [7:0] seqnum;
   bit tx_strobe;

   read_out ro(command, opcode, strobe, seqnum, tx_strobe,
     fifo_empty, fifo_oflow, fifo_req, fifo_bits,
     mii_Q, mii_QV, mii_clk);

   control con(rmii_D, rmii_DV,
     command, opcode, strobe, seqnum, tx_strobe, mii_clk);

   xadc_temp mon(.dclk_in(mii_clk), .alarm_out(xadc_alarm));

endmodule
