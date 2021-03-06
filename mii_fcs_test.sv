`default_nettype none

module mii_fcs_test;

   typedef bit[3:0] nibble;
   bit[7:0] test1[0:59] = {
            8'hff, 8'hff, 8'hff, 8'hff, 8'hff, 8'hff, 8'hd0, 8'h50,
            8'h99, 8'h7c, 8'he4, 8'h32, 8'h55, 8'h55, 8'h01, 8'h00,
            8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
            8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
            8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
            8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
            8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
            8'h00, 8'h00, 8'h00, 8'h00
            };
/*
   bit[7:0] test1[0:59] = {
        8'h08, 8'h00, 8'h20, 8'h0A, 8'h70, 8'h66, 8'h08, 8'h00,
        8'h20, 8'h0A, 8'hAC, 8'h96, 8'h08, 8'h00, 8'h45, 8'h00,
        8'h00, 8'h28, 8'hA6, 8'hF5, 8'h00, 8'h00, 8'h1A, 8'h06,
        8'h75, 8'h94, 8'hC0, 8'h5D, 8'h02, 8'h01, 8'h84, 8'hE3,
        8'h3D, 8'h05, 8'h00, 8'h15, 8'h0F, 8'h87, 8'h9C, 8'hCB,
        8'h7E, 8'h01, 8'h27, 8'hE3, 8'hEA, 8'h01, 8'h50, 8'h12,
        8'h10, 8'h00, 8'hDF, 8'h3D, 8'h00, 8'h00, 8'h20, 8'h20,
        8'h20, 8'h20, 8'h20, 8'h20
        };
*/

   nibble d, m, q;
   bit dv, mv, qv, valid, clk;

   bit [19:0] ocommand;
   bit [2:0] oopcode;
   bit ostrobe;
   bit oseqnum;
   bit otxstrobe;
   mii_frame mf(d, dv, m, mv, clk);
   control control(m, {mv,mv}, ocommand, oopcode, ostrobe, oseqnum, otxstrobe,
     clk);
   // rmii_deframe mdf(m, {mv, mv}, q, qv, valid, clk);

initial
  while (1) begin
     clk = 0;
     #20;
     clk = 1;
     #20;
  end;

initial begin
   d = 0;
   dv = 0;
   #80;

   while (1) begin
      for (int i = 0; i < 60; ++i) begin
         dv = 1;
         d = test1[i][3:0];
         #40;
         d = test1[i][7:4];
         #40;
      end
      dv = 0;
      #2000;
   end
end

   bit [1:24] fifo_req;
   bit [3:0] R;
   bit RV;
   bit tx_strobe;
   read_out ro(0, 0, 0, 8'h23, tx_strobe, 0, 0, fifo_req, 0, R, RV, clk);

   rmii_deframe mdf(R, {RV, RV}, q, qv, valid, clk);

initial begin
   while (1) begin
      // 200 bytes * 40ns = 8µs.
      #8000;
      tx_strobe = !tx_strobe;
   end
end

endmodule
