//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-2 Hash Processing Module
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
`include "hashing_functions.sv"


module hash_process (
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
    
    // Data Out data and Handshaking
    output logic [255:0] data_out,
    output logic data_out_last,
    output logic data_out_valid,
    input  logic data_out_ready
);

    import hashing_functions::*;

    // Message Chunks
    logic [31:0] M [15:0];
    
    // Assign M Variables to 32 bit chunks of the input data
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign M[i] = data_in[(32*((15-i)+1))-1:32*(15-i)];
        end
    endgenerate
    
    // Hash Value Registers
    logic [31:0] H [7:0];
    logic [31:0] next_H [7:0];
    
    // Message Schedule Registers
    logic [31:0] W [63:0];
    logic [31:0] next_W [63:0];
    
    // Working Registers
    logic [31:0] a,b,c,d,e,f,g,h;
    logic [31:0] next_a,next_b,next_c,next_d,next_e,next_f,next_g,next_h;
    
    // Working Combinatorial Words
    logic [31:0] T1, T2;
    
    // State Machine Registers
    logic [2:0] state, next_state;
    logic [255:0] next_data_out;
    logic next_data_in_ready, next_data_out_valid, next_data_out_last;
    logic [5:0] hash_iter, next_hash_iter;
    logic last_block, next_last_block;
    
    // // SHA-2 Constants
    logic [31:0] K [63:0];

    assign K[0]  = 32'h428a2f98; 
    assign K[1]  = 32'h71374491; 
    assign K[2]  = 32'hb5c0fbcf; 
    assign K[3]  = 32'he9b5dba5;
    assign K[4]  = 32'h3956c25b; 
    assign K[5]  = 32'h59f111f1; 
    assign K[6]  = 32'h923f82a4; 
    assign K[7]  = 32'hab1c5ed5;
    assign K[8]  = 32'hd807aa98; 
    assign K[9]  = 32'h12835b01; 
    assign K[10] = 32'h243185be; 
    assign K[11] = 32'h550c7dc3;
    assign K[12] = 32'h72be5d74; 
    assign K[13] = 32'h80deb1fe; 
    assign K[14] = 32'h9bdc06a7; 
    assign K[15] = 32'hc19bf174;
    assign K[16] = 32'he49b69c1; 
    assign K[17] = 32'hefbe4786; 
    assign K[18] = 32'h0fc19dc6; 
    assign K[19] = 32'h240ca1cc;
    assign K[20] = 32'h2de92c6f; 
    assign K[21] = 32'h4a7484aa; 
    assign K[22] = 32'h5cb0a9dc; 
    assign K[23] = 32'h76f988da;
    assign K[24] = 32'h983e5152; 
    assign K[25] = 32'ha831c66d; 
    assign K[26] = 32'hb00327c8; 
    assign K[27] = 32'hbf597fc7;
    assign K[28] = 32'hc6e00bf3; 
    assign K[29] = 32'hd5a79147; 
    assign K[30] = 32'h06ca6351; 
    assign K[31] = 32'h14292967;
    assign K[32] = 32'h27b70a85; 
    assign K[33] = 32'h2e1b2138; 
    assign K[34] = 32'h4d2c6dfc; 
    assign K[35] = 32'h53380d13;
    assign K[36] = 32'h650a7354; 
    assign K[37] = 32'h766a0abb; 
    assign K[38] = 32'h81c2c92e; 
    assign K[39] = 32'h92722c85;
    assign K[40] = 32'ha2bfe8a1; 
    assign K[41] = 32'ha81a664b; 
    assign K[42] = 32'hc24b8b70; 
    assign K[43] = 32'hc76c51a3;
    assign K[44] = 32'hd192e819; 
    assign K[45] = 32'hd6990624; 
    assign K[46] = 32'hf40e3585; 
    assign K[47] = 32'h106aa070;
    assign K[48] = 32'h19a4c116; 
    assign K[49] = 32'h1e376c08; 
    assign K[50] = 32'h2748774c; 
    assign K[51] = 32'h34b0bcb5;
    assign K[52] = 32'h391c0cb3; 
    assign K[53] = 32'h4ed8aa4a; 
    assign K[54] = 32'h5b9cca4f; 
    assign K[55] = 32'h682e6ff3;
    assign K[56] = 32'h748f82ee; 
    assign K[57] = 32'h78a5636f; 
    assign K[58] = 32'h84c87814; 
    assign K[59] = 32'h8cc70208;
    assign K[60] = 32'h90befffa; 
    assign K[61] = 32'ha4506ceb; 
    assign K[62] = 32'hbef9a3f7; 
    assign K[63] = 32'hc67178f2;
    
    // ssig1 next_W assignments - issues using functions with arrayed objects in ivlog
    logic [31:0] ssig0_next_W [63:0];
    logic [31:0] ssig1_next_W [63:0];
    
    generate
        for (i = 0; i < 64; i ++) begin
            assign ssig0_next_W[i] = ((next_W[i] << 25) | (next_W[i] >> 7)) ^ ((next_W[i] << 14) | (next_W[i] >> 18)) ^ (next_W[i] >> 3);
            assign ssig1_next_W[i] = ((next_W[i] << 15) | (next_W[i] >> 17)) ^ ((next_W[i] << 13) | (next_W[i] >> 19)) ^ (next_W[i] >> 10);
        end
    endgenerate
    
    // State Machine Sequential Logic    
    always_ff @(posedge clk, negedge nrst) begin
        if ((!nrst) | sync_rst) begin
            state           <= 3'd0;
            hash_iter       <= 6'd0;
            last_block      <= 1'b0;
            data_in_ready   <= 1'b0;
            data_out_valid  <= 1'b0;
            data_out_last   <= 1'b0;
            data_out        <= 256'd0;
            // Reset Working Registers
            a <= 32'd0;
            b <= 32'd0;
            c <= 32'd0;
            d <= 32'd0;
            e <= 32'd0;
            f <= 32'd0;
            g <= 32'd0;
            h <= 32'd0;
            // Reset H Registers
            for (int i=0; i < 8; i++) begin
                H[i] <= 32'd0;
            end
            // Reset W Registers
            for (int i=0; i < 64; i++) begin
                W[i] <= 32'd0;
            end
        end else begin
            state           <= next_state;
            hash_iter       <= next_hash_iter;
            last_block      <= next_last_block;
            data_in_ready   <= next_data_in_ready;
            data_out_valid  <= next_data_out_valid;
            data_out_last   <= next_data_out_last;
            data_out        <= next_data_out;
            // Set Working Registers
            a <= next_a;
            b <= next_b;
            c <= next_c;
            d <= next_d;
            e <= next_e;
            f <= next_f;
            g <= next_g;
            h <= next_h;
            // Set H Registers
            for (int i=0; i < 8; i++) begin
                H[i] <= next_H[i];
            end
            // Set W Registers
            for (int i=0; i < 64; i++) begin
                W[i] <= next_W[i];
            end
        end    
    end
    
    // State Machine Combinatorial Logic
    always_comb begin
        // Default
        next_state           = state;
        next_hash_iter       = hash_iter;
        next_last_block      = last_block;
        next_data_in_ready   = data_in_ready;
        next_data_out_valid  = data_out_valid;
        next_data_out_last   = data_out_last;
        next_data_out        = data_out;
        // Set next Working Registers
        next_a = a;
        next_b = b;
        next_c = c;
        next_d = d;
        next_e = e;
        next_f = f;
        next_g = g;
        next_h = h;
        // Set next H Registers
        for (int i=0; i < 8; i++) begin
            next_H[i] = H[i];
        end
        // Set next W Registers
        for (int i=0; i < 64; i++) begin
            next_W[i] = W[i];
        end
        
        // Override
        case (state)
            3'd0: begin // Initialise Hash Registers -- this state may be able to be removed (reset values could be changed to these values)
                    if (!(data_out_valid && !data_out_ready)) begin
                        // If data out handshake has been seen, drop valid
                        next_data_out_valid = 1'b0;
                    end
                    // Initialise Hash Value Registers
                    next_H[0]          = 32'h6a09e667;
                    next_H[1]          = 32'hbb67ae85;
                    next_H[2]          = 32'h3c6ef372;
                    next_H[3]          = 32'ha54ff53a;
                    next_H[4]          = 32'h510e527f;
                    next_H[5]          = 32'h9b05688c;
                    next_H[6]          = 32'h1f83d9ab;
                    next_H[7]          = 32'h5be0cd19;
                    next_data_in_ready = 1'b1;
                    next_state         = 3'd1;
                end
            
            3'd1: begin // Perform Hash Initialisation
                    if (!(data_out_valid && !data_out_ready)) begin
                        // If data out handshake has been seen, drop valid
                        next_data_out_valid = 1'b0;
                    end
                    if (data_in_valid && data_in_ready) begin
                        // Valid Handshake and data can be processed
                        // Use the Message chunks to populate the message schedule
                        for (logic [31:0] t = 0; t < 16; t++) begin
                            next_W[t] = M[t];
                        end
                        for (logic [31:0] t = 16; t < 64; t++) begin
                            next_W[t] = ssig1_next_W[t-2] + next_W[t-32'd7] + ssig0_next_W[t-15] + next_W[t-32'd16];
                            // next_W[t] = next_W[t-32'd7] + ssig0(t-15) + next_W[t-32'd16];
                        end
                        // Set Working Variables
                        next_a = H[0];
                        next_b = H[1];
                        next_c = H[2];
                        next_d = H[3];
                        next_e = H[4];
                        next_f = H[5];
                        next_g = H[6];
                        next_h = H[7];
                        // Move to next state
                        next_state      = 3'd2;
                        next_hash_iter  = 6'd0;
                        next_last_block = data_in_last;
                        // Drop Ready Signal to confirm handshake
                        next_data_in_ready = 1'b0;
                    end
                end
            
            3'd2: begin // Perform the main hash computation
                    if (!(data_out_valid && !data_out_ready)) begin
                        // If data out handshake has been seen, drop valid
                        next_data_out_valid = 1'b0;
                    end
                    // Perform Hash Function
                    T1 = h + bsig1(e) + ch(e,f,g) + K[hash_iter] + W[hash_iter];
                    T2 = bsig0(a) + maj(a,b,c);
                    next_a = T1 + T2;
                    next_b = a;
                    next_c = b;
                    next_d = c;
                    next_e = d + T1;
                    next_f = e;
                    next_g = f;
                    next_h = g;
                    // Decrement Iteration Register
                    next_hash_iter = hash_iter + 6'd1;
                    if (hash_iter == 63) begin
                        next_state = 3'd3;
                    end
                end
            
            3'd3: begin // Compute intermediate hash value
                    if (!(data_out_valid && !data_out_ready)) begin
                        // If data out handshake has been seen, drop valid
                        next_data_out_valid = 1'b0;
                    end
                    next_H[0] = a + H[0];
                    next_H[1] = b + H[1];
                    next_H[2] = c + H[2];
                    next_H[3] = d + H[3];
                    next_H[4] = e + H[4];
                    next_H[5] = f + H[5];
                    next_H[6] = g + H[6];
                    next_H[7] = h + H[7];
                    if (last_block) begin
                        if (!data_out_valid) begin // No Data waiting at output
                            next_data_out       = {next_H[0], next_H[1], next_H[2], next_H[3], next_H[4], next_H[5], next_H[6], next_H[7]};
                            next_data_out_last  = 1'b1;
                            next_data_out_valid = 1'b1;
                            // Next State Logic
                            next_state = 3'd1;
                            next_data_in_ready = 1'b1;
                            // Initialise Hash Value Registers
                            next_H[0]          = 32'h6a09e667;
                            next_H[1]          = 32'hbb67ae85;
                            next_H[2]          = 32'h3c6ef372;
                            next_H[3]          = 32'ha54ff53a;
                            next_H[4]          = 32'h510e527f;
                            next_H[5]          = 32'h9b05688c;
                            next_H[6]          = 32'h1f83d9ab;
                            next_H[7]          = 32'h5be0cd19;
                        end else begin
                            // Still Waiting for previous data to be recieved
                            next_state = 3'd4;
                            next_data_in_ready = 1'b0;
                        end
                    end else begin
                        // Next State Logic
                        next_data_in_ready = 1'b1;
                        next_state = 3'd1;
                    end
                end
                
            3'd4: begin // Output Handling
                    if (!(data_out_valid && !data_out_ready)) begin
                        // If data out handshake has been seen, drop valid
                        next_data_out_valid = 1'b0;
                    end
                    if (!data_out_valid) begin // No Data waiting at output
                        next_data_out       = {next_H[0], next_H[1], next_H[2], next_H[3], next_H[4], next_H[5], next_H[6], next_H[7]};
                        next_data_out_last  = 1'b1;
                        next_data_out_valid = 1'b1;
                        // Next State Logic
                        next_state = 3'd1;
                        next_data_in_ready = 1'b1;
                        // Initialise Hash Value Registers
                        next_H[0]          = 32'h6a09e667;
                        next_H[1]          = 32'hbb67ae85;
                        next_H[2]          = 32'h3c6ef372;
                        next_H[3]          = 32'ha54ff53a;
                        next_H[4]          = 32'h510e527f;
                        next_H[5]          = 32'h9b05688c;
                        next_H[6]          = 32'h1f83d9ab;
                        next_H[7]          = 32'h5be0cd19;
                    end else begin
                        // Still Waiting for previous data to be recieved
                        next_state = 3'd4;
                        next_data_in_ready = 1'b0;
                    end
                end
        endcase
    end
endmodule