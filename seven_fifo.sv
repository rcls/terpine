`default_nettype none

module fifo_out(
  input bit [35:0] DI,
  input bit WREN,
  input bit WRCLK,

  output bit [35:0] DO,
  input bit RDCLK,
  input bit RDEN,
  input bit RST,
  output bit EMPTY,
  output bit ALMOSTEMPTY);

   FIFO36E1 #(.DO_REG(1), .DATA_WIDTH(36),
     .FIRST_WORD_FALL_THROUGH("TRUE"), .ALMOST_EMPTY_OFFSET(500))
   fifo(
     .DI({ 32'b0, DI[31:0] }),
     .DIP({ 4'b0, DI[35:32] }),
     .WREN(WREN),
     .WRCLK(WRCLK),
     .DO(DO[31:0]),
     .DOP(DO[35:32]),
     .RDCLK(RDCLK),
     .RDEN(RDEN),
     .RST(RST),
     .RSTREG(0),
     .EMPTY(EMPTY),
     .ALMOSTEMPTY(ALMOSTEMPTY));

endmodule
