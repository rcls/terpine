`default_nettype none

(* keep_hierarchy = 1 *)
module control(
  input bit[3:0] rmii_RX,
  input bit[1:0] rmii_RX_DV_CRS,

  output bit [19:0] command,
  output bit [2:0] opcode,
  output bit strobe,
  output bit [7:0] seqnum,
  output bit tx_strobe,

  input bit clk);

   bit [3:0] rmii_RX_buf, Din;
   bit [1:0] rmii_RX_DV_buf;
   bit DinV, Daccept;

   rmii_deframe deframe(rmii_RX_buf, rmii_RX_DV_buf, Din, DinV, Daccept, clk);

   bit [7:0] Dbyte;
   bit [9:0] nibble_count;
   bit Dstrobe;
   bit [7:0] byte_count;
   assign byte_count = nibble_count[8:1];
   assign Dbyte[7:4] = Din;
   assign Dstrobe = nibble_count[0];

   initial seqnum = 0;

   always@(posedge clk) begin
      rmii_RX_buf <= rmii_RX;
      rmii_RX_DV_buf <= rmii_RX_DV_CRS;

      Dbyte[3:0] <= Dbyte[7:4];

      if (!DinV)
        nibble_count <= 0;
      else
        nibble_count <= nibble_count + 1;

   end

   bit Pinvalid, Prespond;
   always@(posedge clk) begin
      if (!DinV) begin
         Pinvalid <= 0;
         Prespond <= 0;
      end
      if (Dstrobe) begin
         // Ethertype.
         if (byte_count == 12 && Dbyte != 8'h55)
           Pinvalid <= 1;
         if (byte_count == 13 && Dbyte != 8'h55)
           Pinvalid <= 1;
         if (byte_count == 14 && Dbyte != 1)
           Pinvalid <= 1;
         // 15: flags.
         if (byte_count == 16)
           Prespond <= !Pinvalid;
         if (byte_count == 16 && Dbyte != seqnum)
           Pinvalid <= 1;
         // 17: sequence upper.
         if (byte_count == 18)
           opcode <= Dbyte[2:0];
         if (byte_count == 19)
           command[7:0] <= Dbyte;
         if (byte_count == 20)
           command[15:8] <= Dbyte;
         if (byte_count == 21)
           command[19:16] <= Dbyte[3:0];

         if (byte_count > 64)
           Pinvalid <= 1;
      end
      if (byte_count >= 22 && !Pinvalid && Daccept) begin
         strobe <= !strobe;
         seqnum <= seqnum + 1;
      end
      if (Prespond && Daccept) begin
         tx_strobe <= !tx_strobe;
      end
   end
endmodule

module rmii_deframe(
  input bit[3:0] D, input bit [1:0] CRS_DV,
  // QV is asserted over the frame from addresses to FCS, inclusive.  Accept is
  // asserted on the first cycle of Accept deasserted, if it was a good frame.
  output bit[3:0] Q, output bit QV, output bit Accept,
  input bit clk);

   // Sync up the CRS/DV bits.
   bit[1:0] Dprev;
   bit CRS_DV_prev;
   bit skew;

   always@(posedge clk) begin
      Dprev <= D[3:2];
      CRS_DV_prev <= CRS_DV[1];
      // Order received is CRS_DV_prev, CRS_DV[0], CRS_DV[1].
      // If we get 0,0,0 or 0,0,1 we set the skew flag.
      if (!CRS_DV_prev && !CRS_DV[0])
        skew <= CRS_DV[1];

   end

   bit in_packet;

   always@(*) begin
      if (skew) begin
         Q  = { D[1], D[0], Dprev[1], Dprev[0] };
         in_packet = CRS_DV[0];
      end
      else begin
         Q = D;
         in_packet = CRS_DV[1];
      end
   end

   bit preamble_error;
   bit in_frame;
   always@(posedge clk) begin
      if (!in_packet)
        preamble_error <= 0;
      else if (Q[1:0] == 2'b10 || Q[3:2] == 2'b10)
        preamble_error <= 1;

      if (!in_packet)
        in_frame <= 0;
      else if (Q == 4'b1101 && !preamble_error)
        in_frame <= 1;
   end

   bit [31:0] fcs = 32'hffffffff;
   always@(posedge clk) begin
      if (in_frame)
        fcs <= (fcs >> 4)
          ^       (Q[0] ^ fcs[0] ? 32'hedb88320 >> 3 : 0)
            ^     (Q[1] ^ fcs[1] ? 32'hedb88320 >> 2 : 0)
              ^   (Q[2] ^ fcs[2] ? 32'hedb88320 >> 1 : 0)
                ^ (Q[3] ^ fcs[3] ? 32'hedb88320      : 0);
      else
        fcs <= 32'hf0000000 | (fcs >> 4);
   end

   // in_frame takes a cycle to de-assert so we can leach off that.
   assign QV = in_packet && in_frame;
   assign Accept = !in_packet && in_frame && fcs == 32'hdebb20e3;
endmodule
