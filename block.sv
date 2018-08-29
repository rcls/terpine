module block(input bit [19:0] command,
  input bit [2:0] opcode,
  input bit async_strobe,
  input bit clk,

  output bit fifo_empty,
  input bit fifo_req,
  output bit fifo_bit,
  input bit fifo_rst,
  input bit fifo_clk);

   parameter id = 0;
   parameter mask_bits = 32;
   bit [31:0] mask = 32'hfffffff << (32 - mask_bits);

   typedef int unsigned uint;
   uint Ar, Br, Cr, Dr, Din;
   bit Apa, Bpa, Cpa, Dpa;

   bit [19:0] D6, D18, D19, injectQ;
   bit [19:0] Dshift [7:17];

   // The quad has 82 cycles from Din to *r, and the block adds 18 cycles
   // latency for a total of 100.  We define Din to be at +20 === -80.  So Ar
   // etc are at +2.
   quad qA(Ar, Din, Apa, clk);
   quad qB(Br, Din, Bpa, clk);
   quad qC(Cr, Din, Cpa, clk);
   quad qD(Dr, Din, Dpa, clk);

   bit [19:0] inject [0:7];
   bit [4:0] inject_cycle;
   bit inject_inject;
   bit inject_sample;

   (* retiming_backward = 1 *)
   bit match_int;
   bit match;
   bit match_shift[10:17];

   bit sample18, inject18, match18, fifo19;

   always@(posedge clk) begin : cmd
      (* async_reg = "true" *)
      bit strobe1;
      bit strobe2;
      bit strobe3;
      bit strobe4;
      bit strobe5;
      (* async_reg = "true" *)
      bit [19:0] command_sync;
      (* async_reg = "true" *)
      bit [2:0] opcode_sync;
      (* retiming_backward = 1 *)
      bit opcode_command_int;
      bit opcode_command;

      strobe1 <= async_strobe;
      strobe2 <= strobe1;
      strobe3 <= strobe2;
      strobe4 <= strobe2 ^ strobe3;
      strobe5 <= strobe4;

      if (strobe4) begin
         command_sync <= command;
         opcode_sync <= opcode;
      end

      if (strobe5)
         inject[opcode_sync] <= command_sync;

      opcode_command_int <= strobe5 && opcode_sync == 7
                            && command_sync[15:8] == id;
      opcode_command <= opcode_command_int;

      if (opcode_command) begin
         inject_cycle <= command_sync[4:0];
         inject_inject <= command_sync[5];
         inject_sample <= command_sync[6];
      end
      if (sample18) begin
         inject_inject <= 0;
         inject_sample <= 0;
      end
   end

   // One-hot encoding of where the first (E) word of the quint is at (mod5).
   // E.g., quint[4] indicates that we have E-words at +4, +9, +14, +19.
   bit [4:0] quint = 1;
   bit quint4;
   always@(posedge clk) begin
      quint[4:1] <= quint[3:0];
      quint[0] <= quint4;
      quint4 <= !(quint[0] | quint[1] | quint[2] | quint[4]);
   end

   bit [4:0] cycle16;
   bit [16:0] meta15 = 4;
   bit [15:0] meta[16:19];
   always@(posedge clk) begin
      bit [3:0] addend;
      if (quint[4] && meta[19][4:0] >= 24)
        addend = 12 | meta15[16];
      else
        addend = meta15[16];
      // The control word is the last of the quint.  i.e., meta15 contains the
      // first of the four counter words on quint[0], and contains the control
      // word on quint[4].
      if (quint[3])
        meta15 <= { 1'b1, sample18, inject18, match18, 13'(id) };
      else
        // Increment low bits, (mod5)
        meta15 <= meta[19] + addend;

      if (quint[0])
        cycle16 <= meta15[4:0];
      meta[16] <= meta15[15:0];
      for (int i = 17; i <= 19; ++i)
        meta[i] <= meta[i-1];
   end

   // R has E on quint[3], A on quint[2], B on quint[1] and C on quint[0].
   bit quint_0_2, quint_1_2;
   bit [31:0] R;
   always@(posedge clk) begin
      quint_0_2 <= quint[4] | quint[1];
      quint_1_2 <= quint[0] | quint[1];
   end
   gear32_20 gear(D6, R, quint_0_2, quint_1_2, clk);

   function bit[7:0] expand5(bit [4:0] v);
      if (v < 10)
        return v + 48;
      else
        return v + 87;
   endfunction

   always@(posedge clk) begin
      // R is at +3
      R <= Ar | Br | Cr | Dr;

      match_int <= (mask & R) == (mask & -32'h67452301);

      // match is at +5.  Note that it is on the A word of the quint, so it
      // is effectively at +9 w.r.t. the E word of the quint.
      match <= match_int;

      match_shift[10] <= match;
      for (int i = 11; i <= 17; ++i)
        match_shift[i] <= match_shift[i-1];
      match18 <= match_shift[17];

      // Delay an extra 11 stages through a shift register between D6 and D18.
      Dshift[7] <= D6;
      for (int i = 8; i <= 17; ++i)
        Dshift[i] <= Dshift[i-1];
      D18 <= Dshift[17];

      if (quint[2]) begin
         // We should use 'cycle17' here.  But 'cycle16' is good enough.  When
         // the first (E) word is at +17, +16 has the same cycle number.
         inject18 <= cycle16 == inject_cycle && inject_sample && inject_inject;
         sample18 <= cycle16 == inject_cycle && inject_sample;
      end

      if (inject18)
        D19 <= injectQ;
      else
        D19 <= D18;

      if (quint[3])
        fifo19 <= sample18 | inject18 | match18;

      // Expand D19 to Din...
      Din[ 7: 0] <= expand5(D19[4:0]);
      Din[15: 8] <= expand5(D19[9:5]);
      Din[23:16] <= expand5(D19[14:10]);
      Din[31:24] <= expand5(D19[19:15]);

      // The phase advance is two cycles before E.  E is at +20 on quint[0], so
      // pa is at +20 on quint[3].  The calculations are done on the +19 values
      // (pa at quint[2]), and +16 is on the same quint at that time.
      Apa <= quint[2] && cycle16[1:0] == 0;
      Bpa <= quint[2] && cycle16[1:0] == 1;
      Cpa <= quint[2] && cycle16[1:0] == 2;
      Dpa <= quint[2] && cycle16[1:0] == 3;
   end

   always@(posedge clk) begin
      bit [2:0] inject_idx;
      // injectQ is at +18 so we produce the signals for it at +17, the signals
      // for inject_idx at +16.
      inject_idx[2] <= quint[1];            // E
      inject_idx[1] <= quint[2] | quint[3]; // D or C
      inject_idx[0] <= quint[2] | quint[4]; // D or B
      injectQ <= inject[inject_idx];
   end

   bit [35:0] fifo_out, fifo_shift;
   bit fifo_req1;
   FIFO36E1 #(.DO_REG("TRUE"), .DATA_WIDTH(36)) fifo(
     .DI({ 32'b0, meta[19][11:0], D19 }),
     .DIP({ 4'b0, meta[19][15:12] }),
     .WREN(fifo19),
     .WRCLK(clk),
     .DO(fifo_out[31:0]),
     .DOP(fifo_out[35:32]),
     .RDCLK(fifo_clk),
     .RDEN(fifo_req),
     .RST(fifo_rst),
     .RSTREG(0),
     .EMPTY(fifo_empty));

   assign fifo_bit = fifo_shift[0];
   always@(posedge fifo_clk) begin
      bit fifo_req1;
      fifo_req1 <= fifo_req;
      if (fifo_req1)
        fifo_shift <= fifo_out;
      else
        fifo_shift <= { 1'b0, fifo_shift[35:1] };
   end
endmodule
