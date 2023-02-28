//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-256 1 to 3 Arbitrator
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
module sha256_1_to_3_arbitrator (
    input logic clk,
    input logic nrst,
    input logic en,
    
    // Synchronous, localised reset
    input logic sync_rst,
    
    // Data In data and Handshaking
    input  logic [511:0] data_in,
    input  logic data_in_last,
    input  logic data_in_valid,
    output logic data_in_ready,
    
    // Data Out
    output logic [511:0] data_out,
    output logic data_out_last,
    output logic [4:0] data_out_packet_id,
    
    // Channel Enable - 1-hot
    input [2:0] channel_en,
    
    // Handshaking Channel 0
    output logic data_out_valid_0,
    input  logic data_out_ready_0,
    
    // Handshaking Channel 1
    output logic data_out_valid_1,
    input  logic data_out_ready_1,
    
    // Handshaking Channel 2
    output logic data_out_valid_2,
    input  logic data_out_ready_2
);
    
    logic [1:0] state, next_state;
    logic [1:0] channel_select, next_channel_select;
    
    logic [3:0] packet_id, next_packet_id;
    
    logic [511:0] next_data_out;
    logic [4:0] next_data_out_packet_id;
    logic next_data_out_last;
    
    logic [2:0] data_out_ready;
    logic [2:0] data_out_valid, next_data_out_valid;
    
    assign data_out_ready = {data_out_ready_0, data_out_ready_1, data_out_ready_2};
        
    assign data_out_valid_0 = data_out_valid[0];
    assign data_out_valid_1 = data_out_valid[1];
    assign data_out_valid_2 = data_out_valid[2];
    
    // State Machine Sequential Logic    
    always_ff @(posedge clk, negedge nrst) begin
        if ((!nrst) | sync_rst) begin
            state              <= 3'd0;
            data_in_ready      <= 1'b0;
            data_out_valid_0   <= 1'b0;
            data_out_valid_1   <= 1'b0;
            data_out_valid_2   <= 1'b0;
            data_out_last      <= 1'b0;
            data_out           <= 256'd0;
            data_out_packet_id <= 4'd0;
            channel_select     <= 2'd0;
            packet_id          <= 4'd0;
        end else if (en == 1'b1) begin
            state              <= next_state;
            data_out           <= next_data_out;
            data_out_last      <= next_data_out_last;
            data_out_packet_id <= next_data_out_packet_id;
            data_out_valid_0   <= next_data_out_valid_0;
            data_out_valid_1   <= next_data_out_valid_1;
            data_out_valid_2   <= next_data_out_valid_2;
            channel_select     <= next_channel_select;
            packet_id          <= next_packet_id;
        end else begin
            data_in_ready    <= 1'b0;
            data_out_valid_0 <= 1'b0;
            data_out_valid_1 <= 1'b0;
            data_out_valid_2 <= 1'b0;
        end
    end
    
    always_comb begin
        // Default
        next_state              = state;
        next_data_in_ready      = data_in_ready;
        next_data_out_valid_0   = data_out_valid_0;
        next_data_out_valid_1   = data_out_valid_1;
        next_data_out_valid_2   = data_out_valid_2;
        next_data_out_last      = data_out_last;
        next_data_out           = data_out;
        next_channel_select     = channel_select;
        next_packet_id          = packet_id;
        next_data_out_packet_id = data_out_packet_id
        
        // Override
        case (state)
            2'd0: begin
                    if (!(data_out_valid[channel_select] && !data_out_ready[channel_select])) begin
                        // If data out handshake has been seen, drop valid
                        next_data_out_valid = 1'b0;
                    end
                    // Work out which Channel to use
                    // - Check in order of value 0-2
                    if (|data_out_ready) begin
                        next_state = 2'd1;
                        // If there is an avaliable channel, raise the ready signal on the input
                        next_data_in_ready = 1'b1;
                        if      (data_out_ready[0] && channel_en[0]) next_channel_select = 2'd0;
                        else if (data_out_ready[1] && channel_en[1]) next_channel_select = 2'd1;
                        else if (data_out_ready[2] && channel_en[2]) next_channel_select = 2'd2;
                        // De-assert Valid on all Channels
                        next_data_out_valid = 3'd0;
                    end else begin
                        // No Channel is free, stay in this state
                        next_state = 2'd0;
                    end
                end
            
            2'd1: begin
                    // Check outputs can be written to
                    if (data_out_valid[channel_select] && !data_out_ready[channel_select]) begin
                        // If data out is valid and ready is low, there is already data waiting to be transferred
                        next_data_in_ready = 1'b0;
                    // If there is no Valid data at the output or there is a valid transfer happening on this clock cycle
                    end else begin
                        // These can be overloaded later if data is written to the outputs
                        next_data_out_valid = 3'b0; 
                        next_data_in_ready  = 1'b1;
                        // Check Inputs have data
                        if (data_in_valid && data_in_ready) begin
                            // Valid Handshake and data can be processed
                            // Data Processing Algorithm
                            next_data_in_ready  = 1'b0;
                            // Write Input Data to Output 
                            next_data_out           = data_in;
                            next_data_out_packet_id = packet_id;
                            next_data_out_last      = data_in_last;
                            next_data_out_valid     = (3'b1 << next_channel_select); 
                            if (data_in_last) begin
                                // Last Word of Packet - re-arbitrate
                                // Increment Packet ID
                                next_state     = 2'd0;
                                next_packet_id = packet_id + 4'd1;
                            end
                        end
                    end
                end
        endcase
    end
endmodule