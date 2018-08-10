module eth_test(
  input  bit [3:0] ETH0_MII_rxd,
  input  bit       ETH0_MII_rx_dv,
  input  bit       ETH0_MII_rx_clk,
  (* IOB = "true" *)
  output bit [3:0] ETH0_MII_txd,
  (* IOB = "true" *)
  output bit       ETH0_MII_tx_en,
  input  bit       ETH0_MII_tx_clk,
  output bit       ETH0_MII_rst_n,

  input bit ETH0_MII_crs,
  input bit ETH0_MII_col,

  input bit sys_clk_i_0,
  input bit BASE_UART0_rxd,
  output bit BASE_UART0_txd,

  output bit LED_RED_XA_SC,
  output bit USERLED,
  output bit FLED1,
  output bit FLED2,

  output bit ETH0_MDIO_MDC_mdc,
  input bit ETH0_MDIO_MDC_mdio_io);

   assign ETH0_MII_rst_n = 1;
   assign BASE_UART0_txd = 1;
   assign ETH0_MDIO_MDC_mdc = 1;
   assign USERLED = 0;

   (* IOB = "true" *)
   bit [3:0] rxd;
   (* IOB = "true" *)
   bit rxdv;
   bit [3:0] rxq;
   bit rxqv, rx_valid;

   always@(posedge ETH0_MII_rx_clk) begin
      rxd <= ETH0_MII_rxd;
      rxdv <= ETH0_MII_rx_dv;
   end

   mii_deframe md(rxd, rxdv, rxq, rxqv, rx_valid, ETH0_MII_rx_clk);

   always@(posedge ETH0_MII_rx_clk)
     if (rx_valid)
       LED_RED_XA_SC <= !LED_RED_XA_SC;

   (* ram_style = "block" *)
   bit [7:0] ofr [0:127];
   initial $readmemh("eth_test_out.mem", ofr);

   bit[16:0] ocount;
   bit[3:0] txd;
   bit txdv;

   bit[3:0] txq;
   bit txqv;
   always@(posedge ETH0_MII_tx_clk) begin
      ETH0_MII_txd <= txq;
      ETH0_MII_tx_en <= txqv;
   end
   mii_frame mf(txd, txdv, txq, txqv, ETH0_MII_tx_clk);

   always@(posedge ETH0_MII_tx_clk) begin
      ocount <= ocount + 1;

      if (!ocount[0])
        txd <= ofr[ocount[7:1]][3:0];
      else
        txd <= ofr[ocount[7:1]][7:4];

      txdv <= (ocount < 124);
   end

   bit [24:0] tcnt;
   always@(posedge ETH0_MII_tx_clk) begin
      tcnt <= tcnt + 1;
      FLED1 <= tcnt[24];
   end

   bit [24:0] rcnt;
   always@(posedge ETH0_MII_rx_clk) begin
      rcnt <= rcnt + 1;
      FLED2 <= rcnt[24];
   end

endmodule
