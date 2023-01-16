//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-256 ID Issuer
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
module sha256_id_issue (
    input logic clk,
    input logic nrst,
    input logic en,
    
    // Synchronous, localised reset
    input logic sync_rst,
    
    // Data Out - ID Out
    output logic [5:0] id_out,
    output logic id_out_last,
    
    // Concatenator Handshake
    output logic id_out_cfg_valid,
    input  logic id_out_cfg_ready,
    
    // ID Buffer Handshake
    output logic id_out_buf_valid,
    input  logic id_out_buf_ready
);
    
    logic state, next_state;
        
    logic [5:0] next_id_out;
    logic next_id_out_last;
    
    logic next_id_out_cfg_valid;
    logic next_id_out_buf_valid;

    
    // State Machine Sequential Logic    
    always_ff @(posedge clk, negedge nrst) begin
        if ((!nrst) | sync_rst) begin
            state            <= 1'd0;
            id_out           <= 6'd0;
            id_out_last      <= 1'b0;
            id_out_cfg_valid <= 1'b0;
            id_out_buf_valid <= 1'b0;
        end else if (en == 1'b1) begin
            state            <= next_state;
            id_out           <= next_id_out;
            id_out_last      <= next_id_out_last;
            id_out_cfg_valid <= next_id_out_cfg_valid;
            id_out_buf_valid <= next_id_out_buf_valid;
        end else begin
            id_out_cfg_valid <= 1'b0;
            id_out_buf_valid <= 1'b0;
        end
    end
    
    always_comb begin
        // Default
        next_state              = state;
        next_id_out_cfg_valid   = id_out_cfg_valid;
        next_id_out_buf_valid   = id_out_buf_valid;
        next_id_out_last        = id_out_last;
        next_id_out             = id_out;
        
        // Override
        case (state)
            1'd0: begin // Get Packet ID Seed
                    next_id_out_cfg_valid   = 1'b1;
                    next_id_out_buf_valid   = 1'b1;
                    next_state              = 1'd1;
                end
                
            1'd1: begin // Set Packet ID from Seed or Increment Value
                    if (!(id_out_cfg_valid && !id_out_cfg_ready)) begin
                        // If data out handshake has been seen, drop valid
                        next_id_out_cfg_valid = 1'b0;
                    end
                    if (!(id_out_buf_valid && !id_out_buf_ready)) begin
                        // If data out handshake has been seen, drop valid
                        next_id_out_buf_valid = 1'b0;
                    end
                    // Always Last
                    next_id_out_last    = 1'b1;
                    if ((!(id_out_cfg_valid && !id_out_cfg_ready)) && (!(id_out_buf_valid && !id_out_buf_ready))) begin
                        // - if no data is seen on input, increment count
                        // - if data is seen on input, count takes value of input
                        // - there will always be valid data avaliable
                        next_id_out_cfg_valid  = 1'b1;
                        next_id_out_buf_valid  = 1'b1;
                        next_id_out = id_out + 6'd1;
                    end
                end
            
            default: begin
                    next_state = 1'd0;
                end
        endcase
    end
endmodule