//-----------------------------------------------------------------------------
// SoC Labs Digest Valid Signal Filter Module
// A joint work commissioned on behalf of SoC Labs; under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright 2023; SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------

module wrapper_digest_filter(
   input  logic 	  clk,
   input  logic 	  rst,
   input  logic	      s_tlast_i,
   input  logic	      s_tvalid_i,
   input  logic 	  s_tready_o,
   input  logic	      digest_valid_o,
   output logic       hash_valid_o
); 

logic [63:0] block_count, count_check, digest_count;
logic prev_last;
logic prev_digest_valid_o;

always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        block_count  <= 'd0;
        count_check  <= 'd0;
        digest_count <= 'd0;
        prev_digest_valid_o <= 'd0;
        // hash_valid_o <= 1'd0;
        prev_last <= 1'd0;
    end else begin
        prev_digest_valid_o <= digest_valid_o;
        if (s_tvalid_i && s_tready_o) begin
            prev_last <= s_tlast_i;
            if (s_tlast_i) begin
                block_count <= 'd0;
                count_check <= block_count + 1'd1;
            end else begin
                block_count <= block_count + 64'd1;
            end
        end
        // hash_valid_o <= 1'b0;
        if (digest_valid_o == 1'd0 && prev_digest_valid_o == 1'd1) begin
            if (digest_count == (count_check - 64'd1)) begin
                digest_count <= 'd0;
                // hash_valid_o <= 1'b1;
            end else begin
                digest_count <= digest_count + 'd1;
            end
        end
    end
end

// Only takes Valid High for 1 Clock Cycle (Requires Change) and only takes valid high on when correct number of output packets seen
assign hash_valid_o = (digest_count == (count_check - 64'd1)) && ~prev_digest_valid_o ? digest_valid_o : 1'b0;
endmodule