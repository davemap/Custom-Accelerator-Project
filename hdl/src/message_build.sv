module message_build (
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
    
    // Config data and Handshaking
    input  logic [63:0] cfg_size,
    input  logic [1:0]  cfg_scheme,
    input  logic cfg_last,
    input  logic cfg_valid,
    output logic cfg_ready,
    
    // Data Out data and Handshaking
    output logic [511:0] data_out,
    output logic data_out_last,
    output logic data_out_valid,
    input  logic data_out_ready
);

    logic [8:0]  data_word_rem, next_data_word_rem;      // Remainder number of bits after 512 division
    logic [63:0] cfg_size_reg, next_cfg_size;
    logic [2:0]  state, next_state;                      // State Machine State
    logic [54:0] data_word_count, next_data_word_count; 
    
    logic next_data_in_ready, next_cfg_ready, next_data_out_valid, next_data_out_last;
    logic [511:0] next_data_out;
    
    logic [511:0] last_word_mask;
    logic [511:0] end_marker;
    logic [511:0] last_data_word;
    
    // Create Mask for last Data Word
    // - If Muliple of 512, then no mask needed, else mask off valid data
    assign last_word_mask = |data_word_rem ? ((512'd1 << 512) - 1) << (512 - data_word_rem) : ((512'd1 << 512) - 1);
    
    // Create Position Marker to show end of data message (place a "1")
    // - only if not a multiple of 512
    assign end_marker = |data_word_rem ? 1 << (512 - data_word_rem - 1) : 512'd0;  
    
    // Combine Last Data (after being masked) with end marker and size
    assign last_data_word = (data_in & last_word_mask) | end_marker;
    
    logic [54:0] word_extract;
    logic [8:0]  rem_extract;
    
    logic extra_word, next_extra_word;
    
    assign word_extract = cfg_size[63:9];
    assign rem_extract  = cfg_size[8:0];
    
    always_ff @(posedge clk, negedge nrst) begin
        if ((!nrst) | sync_rst) begin
            state           <= 3'd0;
            data_in_ready   <= 1'b0;
            cfg_ready       <= 1'b1;
            cfg_size_reg    <= 64'd0;
            data_word_rem   <= 9'd0;
            data_out_valid  <= 1'b0;
            data_out_last   <= 1'b0;
            data_out        <= 512'd0;
            data_word_count <= 55'd0;
            extra_word      <= 1'b0;
        end else begin
            state           <= next_state;
            data_in_ready   <= next_data_in_ready;
            cfg_ready       <= next_cfg_ready;
            cfg_size_reg    <= next_cfg_size;
            data_word_rem   <= next_data_word_rem;
            data_out_valid  <= next_data_out_valid;
            data_out_last   <= next_data_out_last;
            data_out        <= next_data_out;
            data_word_count <= next_data_word_count;
            extra_word      <= next_extra_word;
        end    
    end
    
    always_comb begin
        // Default
        next_state           = state;
        next_data_in_ready   = data_in_ready;
        next_cfg_ready       = cfg_ready;
        next_cfg_size        = cfg_size_reg;
        next_data_word_rem   = data_word_rem;
        next_data_out_valid  = data_out_valid;
        next_data_out_last   = data_out_last;
        next_data_out        = data_out;
        next_data_word_count = data_word_count;
        next_extra_word      = extra_word;
        
        // Override
        case (state)
            3'd0: begin // First time State
                    next_cfg_ready = 1'b1;
                    next_state     = 3'd1;
                end

            3'd1: begin // Initial Config Read
                    if (!(data_out_valid && !data_out_ready)) begin
                        // If data out handshake has been seen, drop valid
                        next_data_out_valid = 1'b0;
                        next_data_out_last  = 1'b0;
                    end
                    // If there is no Valid data at the output or there is a valid transfer happening on this clock cycle
                    if (cfg_valid == 1'b1) begin
                        // Handshake to Acknowledge Config Has been Read
                        next_cfg_size        = cfg_size;
                        next_cfg_ready       = 1'b0;
                        next_data_in_ready   = 1'b1;
                        next_data_word_count = word_extract + {53'd0, |rem_extract}; // Divide by 512 and round up
                        next_data_word_rem   = rem_extract;
                        if (next_data_word_count > 1) begin
                            next_state = 3'd2;
                        end else begin
                            next_state = 3'd3;
                        end
                    end
                end
                
            3'd2: begin // Pass through Data Blocks
                    // Check outputs can be written to
                    if (data_out_valid && !data_out_ready) begin
                        // If data out is valid and ready is low, there is already data waiting to be transferred
                        next_data_in_ready = 1'b0;
                    // If there is no Valid data at the output or there is a valid transfer happening on this clock cycle
                    end else begin
                        // These can be overloaded later if data is written to the outputs
                        next_data_out_valid = 1'b0; 
                        next_data_in_ready  = 1'b1;
                        next_data_out_last  = 1'b0;
                        // Check Inputs have data
                        if (data_in_valid && data_in_ready) begin
                            // Valid Handshake and data can be processed
                            // Data Processing Algorithm
                            next_data_word_count = data_word_count - 1;
                            // Write Input Data to Output 
                            next_data_out       = data_in;
                            next_data_out_valid = 1'b1;
                            if (next_data_word_count == 1) begin
                                // Last Input Data Word
                                next_state = 3'd3;
                            end
                        end
                    end
                end

            3'd3: begin // Process Last Read Word
                    // Check outputs can be written to
                    if (data_out_valid && !data_out_ready) begin
                        // If data out is valid and ready is low, there is already data waiting to be transferred
                        next_data_in_ready = 1'b0;
                    // If there is no Valid data at the output or there is a valid transfer happening on this clock cycle
                    end else begin
                        // These can be overloaded later if data is written to the outputs
                        next_data_out_valid = 1'b0; 
                        next_data_in_ready  = 1'b1;
                        // Check Inputs have data
                        if (data_in_valid && data_in_ready) begin
                            // Valid Handshake and data can be processed
                            if ((data_word_rem - 1) > 9'd446) begin
                                // If can't fit size in last word
                                next_data_out       = last_data_word;
                                next_data_out_valid = 1'b1;
                                next_data_out_last  = 1'b0;
                                // NEXT STATE: Generate Additional Word
                                next_state           = 3'd4;
                                next_data_in_ready   = 1'b0;
                            end else begin
                                // Size can fit in last data word
                                next_data_out        = last_data_word | {448'd0, cfg_size_reg};
                                next_data_out_valid  = 1'b1;
                                next_data_out_last   = 1'b1;
                                next_data_word_count = data_word_count - 1;
                                next_extra_word      = 1'b1;
                                // NEXT STATE: Read Next Config
                                next_state           = 3'd1;
                                next_data_in_ready   = 1'b0;
                                next_cfg_ready       = 1'b1;
                                next_extra_word      = 1'b0;
                            end
                        end
                    end
                end
                
            3'd4: begin // Generate Extra Word
                    // Check outputs can be written to
                    if (data_out_valid && !data_out_ready) begin
                        // If data out is valid and ready is low, there is already data waiting to be transferred
                        next_data_in_ready = 1'b0;
                    // If there is no Valid data at the output or there is a valid transfer happening on this clock cycle
                    end else begin
                        // Size can fit in last data word
                        next_data_out       = {~|data_word_rem, 447'd0, cfg_size_reg};
                        next_data_out_valid = 1'b1;
                        next_data_out_last  = 1'b1;
                        // NEXT STATE: Read Next Config
                        next_state           = 3'd1;
                        next_data_in_ready   = 1'b0;
                        next_cfg_ready       = 1'b1;
                        next_extra_word      = 1'b0;
                    end
                end
                
            default: begin
                    next_state = 3'd0;
                end
        endcase
    end

endmodule