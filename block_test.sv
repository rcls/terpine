module block_test;

   bit [19:0] command;
   bit [2:0] opcode;
   bit async_strobe;

   bit fifo_empty;
   bit fifo_oflow;
   bit fifo_req;
   bit fifo_bit;
   bit fifo_rst = 1;

   bit clk;
   bit fifo_clk;

   block dut(command, opcode, async_strobe, clk,
     fifo_empty, fifo_oflow, fifo_req, fifo_bit, fifo_rst, fifo_clk);

   assign fifo_clk = clk;
   initial begin
      fifo_rst <= 1;
      #30;
      fifo_rst <= 0;
   end

   initial
     while (1) begin
        #1.25;
        clk <= 0;
        #1.25;
        clk <= 1;
     end

   bit [19:0] commands[0:7] = {
              20'h12345, 20'h6789a, 20'hcdef0, 20'h97531, 20'heb852, 0, 0,
              20'h00077 };

   // Expands to 28q5 cu4q pnng it9h te2i.
   // sha1sum is 6463a2d7ed7cc5ac09b12fac2cd580b406bb1c64
   // Result is 5um2o2dhfj2q5lvdchhq

   initial begin
      #12.5;
      for (int i = 0; i < 8; ++i) begin
         command <= commands[i];
         opcode <= i;
         #12.5;
         async_strobe <= !async_strobe;
         #12.5;
      end
   end
endmodule
