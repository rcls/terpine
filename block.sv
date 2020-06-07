`default_nettype none

module block (input bit [19:0] command,
  input bit [2:0] opcode,
  input bit async_strobe,
  input bit clk,

  output bit fifo_empty,
  output bit fifo_oflow,
  input bit fifo_req,
  output bit fifo_bit,
  input bit fifo_rst,
  input bit fifo_clk);

   parameter id = 0;
   parameter id_width = 8;
   parameter FIFO_RWIDTH = 36;
   parameter mask_bits = 30; // mask was 32.
   bit [31:0] mask = 32'hffffffff << (32 - mask_bits);

   typedef int unsigned uint;
   uint Ar, Br, Cr, Dr, Din;
   bit Apa, Bpa, Cpa, Dpa;

   bit [19:0] D19, injectQ;
   (* srl_style = "reg_srl_reg" *)
   bit [19:0] Dshift[8:18];
   // bit [19:0] D18;

   // The quad has 83 cycles from Din to *r, and the block adds 17 cycles
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

   (* keep = 1 *)
   bit match;
   bit match_shift[10:17];

   bit sample18, inject18, match18, fifo19;

   // Opcode handling:  opcodes 0 to 4 write inject data.
   // opcodes 5, 6 are used by the read-out logic.
   // opcode 7 commits (command data match to id.)
   always@(posedge clk) begin : cmd
      (* async_reg = "true" *)
      bit strobe1;
      (* async_reg = "true" *)
      bit strobe2;
      bit strobe3;
      bit strobe4;
      bit strobe5;
      (* async_reg = "true" *)
      bit [19:0] command_sync;
      (* async_reg = "true" *)
      bit [2:0] opcode_sync;

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

      opcode_command <= strobe5 && opcode_sync == 7
                        && command_sync[7+id_width:8] == id;

      if (opcode_command) begin
         inject_cycle <= command_sync[4:0];
         inject_inject <= command_sync[5];
         inject_sample <= command_sync[6];
      end
      if (sample18)
        inject_sample <= 0;
      if (inject18)
        inject_inject <= 0;
   end

   // One-hot encoding of where the first (E) word of the quint is at (mod5).
   // E.g., quint[4] indicates that we have E-words at +4, +9, +14, +19.
   bit [4:0] quint = 1;
   bit [2:0] quint_count = 0;
   bit quint_4_2, quint_4_3;
   always@(posedge clk) begin
      if (quint_count < 4)
        quint_count <= quint_count + 1;
      else
        quint_count <= quint_count + 4;

      quint[0] <= quint_count[2];
      quint[4:1] <= quint[3:0];

      quint_4_2 <= quint[3] || quint[1];
      quint_4_3 <= quint[3] || quint[2];
   end

   bit [4:0] cycle16;
   // 80 bits / quint of metadata at 16 / clock.  64 bits of counter (the
   // low 5 bits count the in-flight operations, hence cover 0..19 not 0..31).
   // meta15[16] keeps a carry bit from the previous clock.
   (* keep = 1, extract_reset = 0 *)
   bit [16:0] meta15 = 4;
   bit [15:0] meta[16:19];
   always@(posedge clk) begin
      bit [16:0] addend1;
      bit [16:0] addend2;

      if (quint[3])
        addend1 = 0;
      else if (quint[4] && meta[19][4:0] >= 24)
        addend1 = 12 | meta15[16];
      else
        addend1 = 0 | meta15[16];

      // The control word is the last of the quint.  i.e., meta15 contains the
      // first of the four counter words on quint[0], and contains the control
      // word on quint[4].

      if (quint[3])
        // Last metadata of the quint is the control flags and id.  We set the
        // carry bit to make sure we do the increment on the next cycle.
        addend2 = { 1'b1, sample18, inject18, match18, 13'(id) };
      else
        addend2 = meta[19];

      meta15 <= addend1 + addend2;

      if (quint[0])
        cycle16 <= meta15[4:0];

      meta[16] <= meta15[15:0];
      for (int i = 17; i <= 19; ++i)
        meta[i] <= meta[i-1];
   end

   function int unsigned rol30(int unsigned X);
     rol30 = (X << 30) | (X >> 2);
   endfunction

   // R4 has E on quint[4], A on [3], B [2], C on [1] and D in [0].
   bit [31:0] R4, R5;
   always@(posedge clk) begin
      R4 <= Ar | Br | Cr | Dr;
      case (quint_count)
        0: R5 <= rol30(R4) + 32'h10325476; // D
        1: R5 <= rol30(R4) + 32'h98badcfe; // C
        2: R5 <=       R4  + 32'hefcdab89; // B
        3: R5 <=       R4  + 32'h67452301; // A
        default:
          R5  <= rol30(R4) + 32'hc3d2e1f0; // E
      endcase
   end
   gear32_20 gear(Dshift[8], R5, quint_4_2, quint_4_3, clk);

   function bit[7:0] expand5(bit [4:0] v);
      if (v < 10)
        return v + 48;
      else
        return v + 87;
   endfunction

   always@(posedge clk) begin
      // match is at +6
      match <= (mask & R5) == 0;

      // match is at +6.  Note that it is on the A word of the quint, so it
      // is effectively at +10 w.r.t. the E word of the quint.

      match_shift[11] <= match;
      for (int i = 12; i <= 17; ++i)
        match_shift[i] <= match_shift[i-1];
      match18 <= match_shift[17];

      // Delay an extra 10 stages through a shift register between D8 and D18.
      // Dshift[9] <= D8;
      for (int i = 9; i <= 18; ++i)
        Dshift[i] <= Dshift[i-1];

      if (quint[2]) begin
         // We should use 'cycle17' here.  But 'cycle16' is good enough.  When
         // the first (E) word is at +17, +16 has the same cycle number.
         inject18 <= cycle16 == inject_cycle && inject_inject;
         sample18 <= cycle16 == inject_cycle && inject_sample && !inject_inject;
      end

      if (inject18)
        D19 <= injectQ;
      else
        D19 <= Dshift[18];

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
      // for inject_idx at +16 equiv. +1.  I.e. quint[1] is index 0.
      inject_idx[2] <= quint[0];            // E
      inject_idx[1] <= quint[3] | quint[4]; // D or C
      inject_idx[0] <= quint[2] | quint[4]; // D or B
      injectQ <= inject[inject_idx];
   end

   bit [FIFO_RWIDTH-1:0] fifo_out, fifo_shift;
   bit fifo_almost_empty;
   fifo_out fifo(
     .DI({meta[19], D19 }),
     .WREN(fifo19),
     .WRCLK(clk),
     .DO(fifo_out),
     .RDCLK(fifo_clk),
     .RDEN(fifo_req),
     .RST(fifo_rst),
     .EMPTY(fifo_empty),
     .ALMOSTEMPTY(fifo_almost_empty));

   assign fifo_bit = fifo_shift[0];
   always@(posedge fifo_clk) begin
      if (fifo_req)
        fifo_shift <= fifo_out;
      else
        fifo_shift <= { 1'b0, fifo_shift[35:1] };

      if (!fifo_almost_empty)
        fifo_oflow <= 1;
      else if (fifo_empty)
        fifo_oflow <= 0;
   end
endmodule
