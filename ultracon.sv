`default_nettype none

module ultracon #(BLOCKS = 192) (
  input wire [7:0] axi_AWADDR,
  input wire axi_AWVALID,
  output wire axi_AWREADY,

  input wire [7:0] axi_ARADDR,
  input wire axi_ARVALID,
  output reg axi_ARREADY,

  input wire [31:0] axi_WDATA,
  input wire [3:0] axi_WSTRB,
  input wire axi_WVALID,
  output wire axi_WREADY,

  output reg [31:0] axi_RDATA,
  output wire [1:0] axi_RRESP,
  output reg axi_RVALID,
  input wire axi_RREADY,

  output wire [1:0] axi_BRESP,
  output reg axi_BVALID,
  input wire axi_BREADY,

  input wire axi_resetn,

  input wire clk,

  input wire [BLOCKS-1:0] fifo_empty,
  input wire [BLOCKS-1:0] fifo_oflow,
  input wire [BLOCKS-1:0] fifo_bits,
  output reg [BLOCKS-1:0] fifo_req,

  output reg [19:0] command,
  output reg [2:0] opcode,
  output reg strobe,
  output reg turbo);

   wire artransaction;
   reg wtransaction;
   reg [255:0] fifo_empty_buf = 0;
   reg [255:0] fifo_oflow_buf = 0;
   reg [179:0] fifo_shift;
   reg reading_fifo;

   assign axi_RRESP = 0;
   assign axi_BRESP = 0;

   assign artransaction = axi_ARREADY && axi_ARVALID;
   assign axi_AWREADY = wtransaction;
   assign axi_WREADY = wtransaction;

   wire [99:0] shift_data;
   wire [79:0] shift_meta;

   genvar i;
   for (i = 0; i < 5; i = i + 1) begin:d
     assign shift_data[i*20+19 : i*20] = fifo_shift[i*36+19 : i*36];
     assign shift_meta[i*16+15 : i*16] = fifo_shift[i*36+35 : i*36+20];
   end

   always@(posedge clk) begin
      fifo_empty_buf <= fifo_empty;
      fifo_oflow_buf <= fifo_oflow;
   end

   reg strobe_pulse;
   always@(posedge clk) begin
      if (axi_resetn == 0)
        axi_BVALID <= 0;
      else if (wtransaction)
        axi_BVALID <= 1;
      else if (axi_BREADY)
        axi_BVALID <= 0;

      // Be careful not to allow back-to-back write transactions...
      wtransaction <= axi_AWVALID && axi_WVALID && (!axi_BVALID || axi_BREADY)
        && !wtransaction && axi_resetn != 0;

      strobe_pulse <= 0;
      if (wtransaction && (axi_WSTRB != 0) && axi_AWADDR == 24) begin
         // All writes go to OPCODE + CMD.
         turbo <=  axi_WDATA[28];
         opcode <= axi_WDATA[26:24];
         command <= axi_WDATA[19:0];
         strobe_pulse <= 1;
      end

      strobe <= strobe ^ strobe_pulse;
   end

   always@(posedge clk) begin
      fifo_empty_buf <= fifo_empty;
      fifo_oflow_buf <= fifo_oflow;
   end

   always@(posedge clk) begin
      if (axi_resetn == 0)
        axi_RVALID <= 0;
      else if (artransaction)
        axi_RVALID <= 1;
      else if (axi_RREADY)
        axi_RVALID <= 0;

      axi_ARREADY <= (!axi_RVALID || axi_RREADY) && axi_resetn != 0;

      // Could just use ARREADY!
      if (artransaction) begin
         case (axi_ARADDR[6:2])
           0 : axi_RDATA <= fifo_empty_buf[31:0];
           1 : axi_RDATA <= fifo_empty_buf[63:32];
           2 : axi_RDATA <= fifo_empty_buf[95:64];
           3 : axi_RDATA <= fifo_empty_buf[127:96];
           4 : axi_RDATA <= fifo_empty_buf[159:128];
           5 : axi_RDATA <= fifo_empty_buf[191:160];
           6 : axi_RDATA <= fifo_empty_buf[223:192];
           7 : axi_RDATA <= fifo_empty_buf[255:224];

           8 : axi_RDATA <= fifo_oflow_buf[31:0];
           9 : axi_RDATA <= fifo_oflow_buf[63:32];
           10: axi_RDATA <= fifo_oflow_buf[95:64];
           11: axi_RDATA <= fifo_oflow_buf[127:96];
           12: axi_RDATA <= fifo_oflow_buf[159:128];
           13: axi_RDATA <= fifo_oflow_buf[191:160];
           14: axi_RDATA <= fifo_oflow_buf[223:192];
           15: axi_RDATA <= fifo_oflow_buf[255:224];

           16: axi_RDATA <= shift_data[31:0];
           17: axi_RDATA <= shift_data[63:32];
           18: axi_RDATA <= shift_data[95:64];
           19: axi_RDATA <= shift_data[99:96];
           20: axi_RDATA <= shift_meta[31:0];
           21: axi_RDATA <= shift_meta[63:32];
           22: axi_RDATA <= shift_meta[79:64];

           24: axi_RDATA
             <= { reading_fifo, 2'b0, turbo, 1'b0, opcode, 4'b0, command };
           default: axi_RDATA <= 0;
         endcase
      end
   end

   reg fifo_strobe = 0;
   reg fifo_shifting = 0;
   reg [8:0] fifo_read_count = 0;
   reg [7:0] fifo_unit = 0;

   always@(posedge clk) begin
      if (strobe_pulse && opcode == 5 && !reading_fifo) begin
         reading_fifo <= 1;
         fifo_unit <= command[7:0];
      end

      fifo_req <= 0;
      if (fifo_strobe == 1)
        fifo_req[fifo_unit] <= 1;

      fifo_strobe <= fifo_read_count[3:0] == (16-9-2);

      if (fifo_read_count[3:0] >= (16-9))
        fifo_shifting <= 1;

      if (fifo_shifting)
        fifo_shift <= { |fifo_bits, fifo_shift[179:1] };

      if (reading_fifo)
           fifo_read_count <= fifo_read_count + 1;

      if (fifo_read_count >= 320) begin
         reading_fifo <= 0;
         fifo_read_count <= 0;
      end
   end

endmodule
