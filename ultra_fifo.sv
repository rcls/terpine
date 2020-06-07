module fifo_out(
  input bit [35:0] DI,
  input bit WREN,
  input bit WRCLK,

  output bit [8:0] DO,
  input bit RDCLK,
  input bit RDEN,
  input bit RST,
  output bit EMPTY,
  output bit ALMOSTEMPTY);

   // These guys can ignore the fifo reset.

   FIFO36E2
     #(.REGISTER_MODE("REGISTERED"), .WRITE_WIDTH(36), .READ_WIDTH(9),
       .FIRST_WORD_FALL_THROUGH("TRUE"), .PROG_EMPTY_THRESH(1000))
   fifo(
     .DIN({ 32'b0, DI[31:0] }),
     .DINP({ 4'b0, DI[35:32] }),
     .WREN(WREN),
     .WRCLK(WRCLK),
     .DOUT(DO[7:0]),
     .DOUTP(DO[8]),
     .RDCLK(RDCLK),
     .RDEN(RDEN),
     .RST(0),
     .EMPTY(EMPTY),
     .PROGEMPTY(ALMOSTEMPTY));

endmodule
