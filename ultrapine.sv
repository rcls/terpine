`default_nettype none

module ultrapine #(BLOCKS = 192) (
  input bit PCIE_REFCLK_P,
  input bit PCIE_REFCLK_N,
  input bit PCIE_PERST_LS,
  input bit PEX_RX0_P,
  input bit PEX_RX0_N,
  output bit PEX_TX0_P,
  output bit PEX_TX0_N,

  inout wire I2C_FPGA_SDA_LS,
  inout wire I2C_FPGA_SCL_LS,

  output bit FPGA_TXD_MSP,
  input bit FPGA_RXD_MSP);

   bit [19:0] command;
   bit [2:0] opcode;
   bit strobe;
   bit turbo;
   bit alarm;

   bit [BLOCKS-1:0] fifo_req;
   bit [BLOCKS-1:0] fifo_empty;
   bit [BLOCKS-1:0] fifo_oflow;
   bit [BLOCKS-1:0] fifo_bits;

   bit ClkFast, ClkSlow, axi_aclk, clk;

   genvar i;
   for (i = 0; i < BLOCKS; i = i + 1) begin:b
      block #(.id(i), .id_width(8)) b(command, opcode, strobe, clk,
     fifo_empty[i], fifo_oflow[i], fifo_req[i], fifo_bits[i],
     0, axi_aclk);
   end

   BUFGMUX_CTRL clkmux(.S(!alarm && turbo), .I0(ClkSlow), .I1(ClkFast), .O(clk));
   /*
   (* async_reg = "true" *)
   bit turbo1, turbo2, alarm1, alarm2;
   bit clk_ce = 0;
   bit clk_ce2 = 0;
   bit clk_ce3 = 0;
   bit clk_internal;
   BUFG internal(.I(ClkFast), .O(clk_internal));
   BUFGCE gate(.I(ClkFast), .O(clk), .CE(clk_ce3));
   always@(posedge clk_internal) begin
      turbo1 <= turbo;
      turbo2 <= turbo1;
      alarm1 <= alarm;
      alarm2 <= alarm1;
      clk_ce <= turbo2 && !alarm2 || (!clk_ce && !clk_ce2);
      clk_ce2 <= clk_ce;
      clk_ce3 <= clk_ce2;
   end
    */

   control con (.Alarm(alarm),
     .strobe(strobe),
     .command(command),
     .opcode(opcode),
     .fifo_bits(fifo_bits),
     .fifo_empty(fifo_empty),
     .fifo_oflow(fifo_oflow),
     .fifo_req(fifo_req),
     .turbo(turbo),

     .PCIE_REFCLK_clk_p(PCIE_REFCLK_P),
     .PCIE_REFCLK_clk_n(PCIE_REFCLK_N),
     .PCIE_PERST_LS(PCIE_PERST_LS),
     .PEX_rxp(PEX_RX0_P),
     .PEX_rxn(PEX_RX0_N),
     .PEX_txp(PEX_TX0_P),
     .PEX_txn(PEX_TX0_N),

     .I2C_FPGA_SDA_LS(I2C_FPGA_SDA_LS),
     .I2C_FPGA_SCL_LS(I2C_FPGA_SCL_LS),

     .FPGA_MSP_rxd(FPGA_RXD_MSP),
     .FPGA_MSP_txd(FPGA_TXD_MSP),

     .ClkFast(ClkFast),
     .ClkSlow(ClkSlow),
     .axi_aclk(axi_aclk)
     );

endmodule
