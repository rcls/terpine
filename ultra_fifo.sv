module fifo_out(
  input bit [35:0] DI,
  input bit WREN,
  input bit WRCLK,

  output bit [35:0] DO,
  input bit RDCLK,
  input bit RDEN,
  input bit RST,
  output bit EMPTY);

   FIFO36E2
     #(.REGISTER_MODE("REGISTERED"), .WRITE_WIDTH(36), .READ_WIDTH(36))
   fifo(
     .DIN({ 32'b0, DI[31:0] }),
     .DINP({ 4'b0, DI[35:32] }),
     .WREN(WREN),
     .WRCLK(WRCLK),
     .DOUT(DO[31:0]),
     .DOUTP(DO[35:32]),
     .RDCLK(RDCLK),
     .RDEN(RDEN),
     .RST(RST),
     .EMPTY(EMPTY));

endmodule
