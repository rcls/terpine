`default_nettype none

(* keep_hierarchy = 1 *)
module read_out
  #(parameter B = 24)
   (  input bit  [19:0] command,
      input bit  [2:0] opcode,
      input bit  strobe_in,
      input bit [7:0] seqnum,
      input bit tx_strobe_in,

      input bit  [B:1] fifo_empty,
      input bit  [B:1] fifo_oflow,
      output bit [B:1] fifo_req,
      input bit [B:1] fifo_bits,

      output bit [3:0] mii_Q,
      output bit mii_QV,

      input bit clk);

   // Opcode 5 is fifo read.  command is unit to read.
   // Opcode 6 is ram read.  command is address to read.

   // The RAM is 1k * 36.
   typedef bit [35:0] word;
   word memory[0:1023];

   bit strobe1, strobe;

   always@(posedge clk) strobe1 <= strobe_in;
   assign strobe = strobe_in ^ strobe1;

   // Memory read.
   bit [9:0] read_address;
   bit [9:0] internal_raddr;
   always@(posedge clk) begin
      if (strobe && opcode == 6)
        read_address <= command[9:0];
   end

   // Fifo read...
   bit reading_fifo = 0;
   bit [4:0] fifo_unit = 0;
   bit [8:0] fifo_read_count = 0;
   bit [9:0] write_count = 0;
   word fifo_shift = 0;

   always@(posedge clk) begin
      if (strobe && opcode == 5 && !reading_fifo) begin
         reading_fifo <= 1;
         fifo_read_count <= 0;
         fifo_unit <= command[4:0];
      end

      fifo_req <= 0;
      if (fifo_read_count[5:0] == 3)
        fifo_req[fifo_unit] <= 1;

      fifo_shift <= { |fifo_bits, fifo_shift[35:1] };

      if (fifo_read_count[5:0] >= 40) begin
         memory[write_count] <= fifo_shift;
         write_count <= write_count + 1;
      end

      if (reading_fifo) begin
         if (fifo_read_count[5:0] >= 40)
           fifo_read_count <= fifo_read_count + 25;
         else
           fifo_read_count <= fifo_read_count + 1;
      end

      if (fifo_read_count >= 320)
        reading_fifo <= 0;
   end

   // (R)MII sequencer.
   // Each opcode produces 16 bits of data output to MII:
   // 16 bits data / address
   // 4 bits sources id.
   // Strobes:
   // DV.
   // FCS compute.
   // RESET
   typedef enum bit[3:0] {
        opDATA,
        opFLAGS,
        opSEQUENCE,
        opWADDR,
        opRADDR,
        opREAD,
        opREAD1,
        opREAD2,
        opEMPTY0,
        opEMPTY1,
        opEMPTY2,
        opEMPTY3,
        // Internal use only.
        opSHIFT
   } read_op_t;

   word fDATA_VALID  = 36'h000100000;
   word fFCS_COMPUTE = 36'h000200000;
   word fFCS_OUTPUT  = 36'h000400000;
   word fRESET       = 36'h000800000;
   word fIDLE        = 36'h001000000;

   word DATA     = fFCS_COMPUTE | fDATA_VALID | opDATA;
   word PREAMBLE = fDATA_VALID | opDATA;
   word FLAGS    = (opFLAGS    << 16) | DATA;
   word SEQUENCE = (opSEQUENCE << 16) | DATA;
   word WADDR    = (opWADDR    << 16) | DATA;
   word RADDR    = (opRADDR    << 16) | DATA;
   word READ     = (opREAD     << 16) | DATA;
   word READ1    = (opREAD1    << 16) | DATA;
   word READ2    = (opREAD2    << 16) | DATA;
   word EMPTY0   = (opEMPTY0   << 16) | DATA;
   word EMPTY1   = (opEMPTY1   << 16) | DATA;
   word EMPTY2   = (opEMPTY2   << 16) | DATA;
   word EMPTY3   = (opEMPTY3   << 16) | DATA;
   word FCS      = fFCS_OUTPUT | fDATA_VALID;
   word IPG      = opDATA;

   word rom[0:43] = { fIDLE,
     PREAMBLE | 16'h5555, PREAMBLE | 16'h5555,
     PREAMBLE | 16'h5555, PREAMBLE | 16'hd555,
     // 0
     DATA | 16'hffff, DATA | 16'hffff, DATA | 16'hffff, // Dst
     DATA | 16'haaaa, DATA | 16'haaaa, DATA | 16'haaaa, // Src
     DATA | 16'h5555,                          // Type
     // 14
     FLAGS,                    // Opcode & flags.
     SEQUENCE,                 // Sequence & last sequence.
     // 18
     RADDR,
     WADDR,                             // Include write-in-progress?
     // 22

     // 64 bits of empty info; empty flags then nearly empty.
     EMPTY0, EMPTY1, EMPTY2, EMPTY3,
     // 30

     // 5 * 36bits of read data, round up to 5 * 6 = 30 bytes.
     READ, READ1, READ2,
     READ, READ1, READ2,
     READ, READ1, READ2,
     READ, READ1, READ2,
     READ, READ1, READ2,
     // 60

     FCS, FCS,

     IPG, IPG, IPG, IPG, IPG, IPG,

     fRESET | fIDLE };

   enum bit [1:0] { PHASE0, PHASE1, PHASE2, PHASE3 } phase = PHASE0;
   bit [6:0] pc;
   word operation;
   bit [15:0] param;
   bit [3:0] read_op;
   assign param = operation[15:0];
   assign read_op = operation[19:16];

   bit [15:0] mii_word;
   bit mii_word_qv;
   bit mii_word_fcs_compute;
   bit mii_word_fcs_output;
   word read_latch;
   bit tx_strobe;

   always@(posedge clk) begin
      case (phase)
        PHASE0: phase <= PHASE1;
        PHASE1: phase <= PHASE2;
        PHASE2: phase <= PHASE3;
        PHASE3: phase <= PHASE0;
      endcase

      if (phase == PHASE0)
         operation <= rom[pc];
      if (phase == PHASE3 && !(operation & fRESET) && (
                 !(operation & fIDLE)
                 || (tx_strobe_in != tx_strobe))) begin
         pc <= pc + 1;
         tx_strobe <= tx_strobe_in;
      end

      if (operation & fRESET)
        pc <= 0;

      if (phase == PHASE1) begin
         if (read_op == opRADDR)
           internal_raddr <= read_address;
         if (read_op == opREAD)
           internal_raddr <= internal_raddr + 1;
         if (read_op == opREAD)
           read_latch <= memory[internal_raddr];
      end

      // At PHASE3 we have the data ready, so present it...
      if (phase == PHASE3) begin
         mii_word_qv          <= (operation & fDATA_VALID ) != 0;
         mii_word_fcs_compute <= (operation & fFCS_COMPUTE) != 0;
         mii_word_fcs_output  <= (operation & fFCS_OUTPUT ) != 0;
      end
      case (phase == PHASE3 ? read_op : opSHIFT)
        opDATA:     mii_word <= param;
        opFLAGS:    mii_word <= 2;
        opSEQUENCE: mii_word <= { 8'b0, seqnum };
        opWADDR:    mii_word <= write_count;
        opRADDR:    mii_word <= internal_raddr;
        opREAD:     mii_word <= read_latch[15:0];
        opREAD1:    mii_word <= read_latch[31:0];
        opREAD2:    mii_word <= {12'b0, read_latch[35:32]};
        opEMPTY0:   mii_word <= fifo_empty[16:1];
        opEMPTY1:   mii_word <= fifo_empty[B:17];
        opEMPTY2:   mii_word <= fifo_oflow[16:1];
        opEMPTY3:   mii_word <= fifo_oflow[B:17];
        opSHIFT:    mii_word <= mii_word >> 4;
        default:    mii_word <= 0;
      endcase
   end

   // mii output...
   bit [31:0] fcs;
   always@(posedge clk) begin
      if (mii_word_fcs_compute) begin
        fcs <= (fcs >> 4)
          ^       (mii_word[0] ^ fcs[0] ? 32'hedb88320 >> 3 : 0)
            ^     (mii_word[1] ^ fcs[1] ? 32'hedb88320 >> 2 : 0)
              ^   (mii_word[2] ^ fcs[2] ? 32'hedb88320 >> 1 : 0)
                ^ (mii_word[3] ^ fcs[3] ? 32'hedb88320      : 0);
      end
      else begin
         fcs <= 32'hf0000000 | (fcs >> 4);
      end
      if (mii_word_fcs_output)
        mii_Q <= fcs[3:0] ^ 15;
      else
        mii_Q <= mii_word[3:0];
      mii_QV <= mii_word_qv;
   end
endmodule
