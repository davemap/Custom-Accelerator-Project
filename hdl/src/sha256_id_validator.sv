//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-256 ID Validator
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2023, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
module sha256_id_validator (
    input logic clk,
    input logic nrst,
    input logic en,
    
    // Synchronous, localised reset
    input logic sync_rst,
    
    // ID Buffer IN
    input  logic [5:0] id_in_buf,
    input  logic id_in_buf_last,
    input  logic id_in_buf_valid,
    output logic id_in_buf_ready,

    // Hash IN
    input  logic [255:0] hash_in,
    input  logic [5:0]   hash_in_id,
    input  logic hash_in_last,
    input  logic hash_in_valid,
    output logic hash_in_ready,

    // Hash Out
    output logic [255:0] hash_out,
    output logic hash_out_err,
    output logic hash_out_last,
    output logic hash_out_valid,
    input  logic hash_out_ready,

    // Status Out - Gets updated after every hash
    output logic [1:0] status_err,
    output logic [9:0] status_packet_count,
    input  logic status_clear

);
    
    logic [1:0]   state, next_state;
        
    logic [255:0] next_hash_out;
    logic next_hash_out_err;
    logic next_hash_out_last, next_hash_out_valid;
    logic next_hash_in_ready, next_id_in_buf_ready;

    logic [255:0] hash_buf;
    logic [255:0] next_hash_buf;

    logic [5:0]   hash_buf_id, id_buf;
    logic [5:0]   next_hash_buf_id, next_id_buf;

    // Status
    logic [1:0]   next_status_err;
    logic [9:0]   next_status_packet_count;
    // Status Error
    // bit 1 high - ID Buffer Error - Buffer has skipped and ID
    // bit 0 high - Hash ID Error   - Packet has been dropped
    
    // State Machine Sequential Logic    
    always_ff @(posedge clk, negedge nrst) begin
        if ((!nrst) | sync_rst) begin
            state            <=   1'd0;
            hash_out         <= 256'd0;
            hash_out_err     <=   1'b0;
            hash_out_last    <=   1'b0;
            hash_out_valid   <=   1'b0;
            hash_in_ready    <=   1'b0;
            id_in_buf_ready  <=   1'b0;
            hash_buf         <= 256'd0;
            hash_buf_id      <=   6'd0;
            id_buf           <=   6'd0;
        end else if (en == 1'b1) begin
            state            <= next_state;
            hash_out         <= next_hash_out;
            hash_out_err     <= next_hash_out_err;
            hash_out_last    <= next_hash_out_last;
            hash_out_valid   <= next_hash_out_valid;
            hash_in_ready    <= next_hash_in_ready;
            id_in_buf_ready  <= next_id_in_buf_ready;
            hash_buf         <= next_hash_buf;
            hash_buf_id      <= next_hash_buf_id;
            id_buf           <= id_buf;
        end else begin
            hash_out_valid   <= 1'b0;
            hash_in_ready    <= 1'b0;
            id_in_buf_ready  <= 1'b0;
        end
    end
    
    always_comb begin
        // Default
        next_state              = state;
        next_hash_out           = hash_out;
        next_hash_out_err       = hash_out_err;
        next_hash_out_last      = hash_out_last;
        next_hash_out_valid     = hash_out_valid;
        next_hash_in_ready      = hash_in_ready;
        next_id_in_buf_ready    = id_in_buf_ready;     
        next_hash_buf           = hash_buf;
        next_hash_buf_id        = hash_buf_id;
        next_id_buf             = id_buf;
        
        // Override
        case (state)
            2'd0: begin
                    next_hash_in_ready    = 1'b1;
                    next_id_in_buf_ready  = 1'b1;
                    next_state            = 2'd1;
                end
                
            2'd1: begin // Set Packet ID from Seed or Increment Value
                    if (status_clear) begin
                        next_status_out_err = 2'b0;
                    end
                    if (hash_out_valid && !hash_out_ready) begin
                        // If data out handshake has not been seen, drop ready
                        next_hash_in_ready   = 1'b0;
                        next_id_in_buf_ready = 1'b0;
                    end else begin
                        // Check Hash Input Handshaked
                        if (hash_in_ready && hash_in_ready) begin
                            next_hash_in_ready = 1'b0;
                            next_hash_buf      = hash_in;
                            next_hash_buf_id   = hash_in_id;
                            // Wait for ID Buffer State
                            next_state         = 2'd2;
                        end
                        // Check ID Buffer Input Handshaked
                        if (id_in_buf_ready && id_in_buf_valid) begin
                            next_id_in_buf_ready = 1'b0;
                            next_id_buf          = id_buf;
                            // Wait for Hash Input State
                            next_state           = 2'd3;
                        end
                        // Check if Both Input Handshaked
                        if (hash_in_ready && hash_in_ready) && (id_in_buf_ready && id_in_buf_valid) begin
                            // Do ID's match?
                            next_hash_out       = hash_in;
                            next_hash_out_valid = 1'b0;
                            if (!cfg_out_valid && cfg_out_ready) begin 
                                // In case where no valid data and ready is waiting for valid data 
                                // - (will be asserted next cc), guaranteed handshake next cycle
                                next_id_in_buf_ready = 1'b1;
                                next_hash_in_ready   = 1'b1;
                            end else begin
                                next_id_in_buf_ready = 1'b0;
                                next_hash_in_ready   = 1'b0;
                            end
                            // ID's don't match
                            if ((id_in_buf > hash_in_id)||(~id_in_buf[5] & hash_in_id[5])) begin
                                // If ID Buffer ID > Hash ID - ID Buffer Error
                                // Pop an additional hash
                                next_state         = 2'd3;
                                next_hash_out_err  = 1'b1;
                                next_status_err[1] = 1'b1; 
                            end else if ((id_in_buf < hash_in_id)||(id_in_buf[5] & ~hash_in_id[5])) begin
                                // If ID Buffer ID < Hash ID - Lost Packet Error
                                // Pop an additional value from the Buffer FIFO
                                next_state         = 2'd2;
                                next_hash_out_err  = 1'b1;
                                next_status_err[0] = 1'b1;
                            end else begin
                                next_hash_out_err = 1'b0;
                                next_state        = 2'd1;
                            end
                        end
                    end
                end
            
            default: begin
                    next_state = 2'd0;
                end
        endcase
    end
endmodule