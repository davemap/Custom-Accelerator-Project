//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-2 Engine Top-level
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------

module sha_2_engine (
    // Clocking Signals
    input logic clk,
    input logic nrst,
    
    // Data In data and Handshaking
    input  logic [511:0] data_in,
    input  logic data_in_valid,
    output logic data_in_ready,
    
    // Config data and Handshaking
    input  logic [63:0] cfg_size,
    input  logic [1:0]  cfg_scheme,
    input  logic cfg_valid,
    output logic cfg_ready,
    
    // Data Out data and Handshaking
    output logic [511:0] data_out,
    output logic data_out_valid,
    input  logic data_out_ready
);
    
    // Stage 1: Input Data Registering
    
    // Data In FIFO Signals
    logic [511:0] data_in_fifo [3:0];
    logic [2:0]   data_in_fifo_write_ptr;
    logic [2:0]   data_in_fifo_read_ptr;
    logic [2:0]   data_in_fifo_ptr_dif;
    wire  [1:0]   data_in_fifo_write_ptr_val, data_in_fifo_read_ptr_val;
    
    // Data In FIFO Pointer Derived Signal Assignments
    assign data_in_fifo_ptr_dif = data_in_fifo_write_ptr - data_in_fifo_read_ptr;
    assign data_in_fifo_write_ptr_val = data_in_fifo_write_ptr [1:0];
    assign data_in_fifo_read_ptr_val  = data_in_fifo_read_ptr  [1:0];
    
    // Config FIFO Signals
    logic [63:0]  cfg_size_fifo   [3:0];
    logic [1:0]   cfg_scheme_fifo [3:0];
    logic [2:0]   cfg_fifo_write_ptr;
    logic [2:0]   cfg_fifo_read_ptr;
    logic [2:0]   cfg_fifo_ptr_dif;
    logic [1:0]   cfg_fifo_write_ptr_val, cfg_fifo_read_ptr_val;
    
    // Config FIFO Pointer Derived Signal Assignments
    assign cfg_fifo_ptr_dif = cfg_fifo_write_ptr - cfg_fifo_read_ptr;
    assign cfg_fifo_write_ptr_val = cfg_fifo_write_ptr [1:0];
    assign cfg_fifo_read_ptr_val  = cfg_fifo_read_ptr  [1:0];

    // Conditions to write and read from FIFO's
    // Write Ptr  | Read Ptr  | Result  | Valid Write | Valid Read
    //    000     -    000    =   000   |      Y      |     N
    //    001     -    000    =   001   |      Y      |     Y
    //    010     -    000    =   010   |      Y      |     Y
    //    011     -    000    =   011   |      Y      |     Y
    //    100     -    000    =   100   |      N      |     Y
    //    101     -    000    =   101   |      N      |     N
    //    110     -    000    =   110   |      N      |     N
    //    111     -    000    =   111   |      N      |     N
    // WriteValid: WritePtr - ReadPtr < 3'd4
    // ReadValid:  WritePtr - ReadPtr - 1 < 3'd4
    
    always_ff @(posedge clk, negedge nrst) begin: data_in_registering
        if (!nrst) begin
            data_in_fifo_write_ptr <= 3'b0;
            data_in_ready          <= 1'b1;
        end else if (data_in_fifo_ptr_dif < 3'd4) begin // Space in FIFO
            if ((data_in_valid == 1'b1) && (data_in_ready == 1'b1)) begin // Successful Handshake
                data_in_fifo [data_in_fifo_write_ptr[1:0]] <= data_in;
                data_in_fifo_write_ptr <= data_in_fifo_write_ptr + 3'b1;
                if (data_in_fifo_ptr_dif + 3'b1 >= 3'd4) begin // FIFO full with new data written
                    data_in_ready <= 1'b0;
                end else begin // Still space in FIFO after latest write
                    data_in_ready <= 1'b1;
                end
            end else begin // Unsuccessful handshake but space in FIFO
                data_in_ready <= 1'b1;
            end
        end else begin // FIFO Full
            data_in_ready <= 1'b0;
        end
    end
    
    always_ff @(posedge clk, negedge nrst) begin: cfg_registering
        if (!nrst) begin
            cfg_fifo_write_ptr <= 3'b0;
            cfg_ready          <= 1'b1;
        end else if (cfg_fifo_ptr_dif < 3'd4) begin // Space in FIFO
            if ((cfg_valid == 1'b1) && (cfg_ready == 1'b1)) begin // Successful Handshake
                cfg_size_fifo   [cfg_fifo_write_ptr[1:0]] <= cfg_size; 
                cfg_scheme_fifo [cfg_fifo_write_ptr[1:0]] <= cfg_scheme; 
                cfg_fifo_write_ptr <= cfg_fifo_write_ptr + 3'b1;
                if (cfg_fifo_ptr_dif + 3'b1 >= 3'd4) begin // FIFO full with new data written
                    cfg_ready <= 1'b0;
                end else begin // Still space in FIFO after latest write
                    cfg_ready <= 1'b1;
                end
            end else begin // Unsuccessful handshake but space in FIFO
                cfg_ready <= 1'b1;
            end
        end else begin // FIFO Full
            cfg_ready <= 1'b0;
        end
    end
    
    // Stage 2: Functional Logic 
    
    // SHA-2 State Machine
    logic [1:0]  state;
    logic [53:0] data_word_count;
    logic cfg_word_avail;
    logic data_in_word_avail;
    
    assign cfg_word_avail     = ((cfg_fifo_ptr_dif     - 3'b1) < 3'd4); // Is there a Config word in the FIFO to read?
    assign data_in_word_avail = ((data_in_fifo_ptr_dif - 3'b1) < 3'd4); // Is there a Data In word in the FIFO to read?
    
    logic [63:0] size_read, size_read_reg;
    logic [8:0]  size_word_rem, size_word_rem_reg;
    logic [53:0] words_to_read, words_to_read_reg; // Number of 512 bit words to read in
    logic round_up;
    logic extra_word_needed;
    logic [511:0] extra_word, extra_word_reg;
    
    assign size_read         = cfg_size_fifo[cfg_fifo_read_ptr_val];     // Extract Size from FIFO
    assign size_word_rem     = size_read[8:0];                           // Remainder of 512 Word Division
    assign round_up          = |size_word_rem;                           // Is there a remainder after a 512 division?
    assign words_to_read     = (size_read >> 9) + round_up;              // Total Number of 512 bit words to Read in
    assign extra_word_needed = (size_word_rem - 1) > 446;                // Extra word needed as not enough space in last word size 

    // If extra word needed, extra word is sets the value of the extra word to the value of size and determines 
    // if message end 1 needs to be put at the beginning of word or not
    // If not needed, set to 0 as invalid word (as size can't be 0) - can be detected later
    assign extra_word        = extra_word_needed ? {~round_up, 447'd0, size_read} : 512'd0;  
    
    logic [511:0] working_data;
    logic [511:0] data_in_word_read;
    
    assign data_in_word_read = data_in_fifo[data_in_fifo_read_ptr_val];  // Extract Data In Word from FIFO
    
    logic [511:0] last_word_mask;
    logic [511:0] end_marker;
    logic [511:0] last_data_word;
    
    assign last_word_mask = |size_word_rem_reg ? ((512'd1 << 512) - 1) << (512 - size_word_rem_reg) : ((512'd1 << 512) - 1); // Create mask to get data from last word
    assign end_marker = 1 << (512 - size_word_rem_reg - 1);                      // "1" to signify end of message
    // Combine Last Data with end marker and size
    assign last_data_word = (data_in_word_read & last_word_mask) | (|size_word_rem_reg ? end_marker : 512'd0)  | (~|extra_word_reg ? size_read_reg : 512'd0);
    
    always_ff @(posedge clk, negedge nrst) begin: sha_2_next_state
        if (!nrst) begin
            state                 <= 2'd0;
            data_in_fifo_read_ptr <= 3'b0;
            cfg_fifo_read_ptr     <= 3'b0;
            words_to_read_reg     <= 54'd0;
            extra_word_reg        <= 512'd0;
            working_data          <= 512'd0;
            data_word_count       <= 54'd0;
            size_read_reg         <= 64'd0;
            size_word_rem_reg     <= 9'd0;
        end else begin
            case(state)
                2'd0: begin // Initial Config Read
                        if (cfg_word_avail == 1'b1) begin
                            size_read_reg      <= size_read;
                            size_word_rem_reg  <= size_word_rem;
                            words_to_read_reg  <= words_to_read;
                            extra_word_reg     <= extra_word;
                            data_word_count    <= 54'd0;
                            cfg_fifo_read_ptr  <= cfg_fifo_read_ptr + 3'b1;
                            state              <= state + 2'b1;
                        end
                    end
                2'd1: begin // Data Processing Step
                        if (data_in_word_avail == 1'b1) begin
                            data_in_fifo_read_ptr <= data_in_fifo_read_ptr + 3'b1;
                            data_word_count       <= data_word_count + 54'd1;
                            if (data_word_count < (words_to_read_reg - 1)) begin // Not the last word to read
                                working_data  <= data_in_word_read;
                            end else begin // Last Data In Word to Process
                                working_data <= last_data_word;
                                if (|extra_word_reg == 1'b1) begin
                                    state <= state + 2'd1;
                                end else begin
                                    state <= state + 2'd2;
                                end
                            end
                        end
                    end
                2'd2: begin // Process Extra Word If Needed
                        working_data <= extra_word_reg;
                        state <= state + 2'd1;
                    end
                2'd3: begin // Write Out Result to Output
                        state <= 2'd0;
                    end
                default: begin
                        state <= 2'd0;
                    end
            endcase
        end
    end

endmodule