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
    output logic [511:0] data_out,
    output logic data_out_last,
    output logic data_out_valid,
    input  logic data_out_ready
);

// Message Chunks
logic [31:0] M [15:0];

genvar i;
generate
    for (i=0; i < 16; i++) begin
        assign M[i] = data_in[(16*i)-1:16*(i-1)];
    end
endgenerate

endmodule