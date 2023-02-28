//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-256 ID Buffer
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2023, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
`include "fifo_vr.sv"

module sha256_id_buf #(
    parameter DEPTH = 4,
    parameter ID_DATA_W = 6,
    parameter PTR_W = $clog2(DEPTH)  // Read/Write Pointer Width
)(
    input logic clk,
    input logic nrst,
    input logic en,
    
    // Synchronous, localised reset
    input logic sync_rst,
    
    // ID In
    input  logic [ID_DATA_W-1:0] id_in,
    input  logic id_in_last,
    input  logic id_in_valid,
    output logic id_in_ready,

    // ID Out
    output logic [ID_DATA_W-1:0] id_out,
    output logic id_out_last,
    output logic id_out_valid,
    input  logic id_out_ready,

    // Status Out
    output logic [ID_DATA_W-1:0] status_id,       // ID being passed to Validator
    output logic [PTR_W:0] status_buffered_ids    // Number of IDs in ID Validation Queue
);
    
    logic [PTR_W:0] status_ptr_dif;
    fifo_vr #( DEPTH,     // Depth
               ID_DATA_W  // Data Width 
    ) id_buffer (
        .clk (clk),
        .nrst (nrst),
        .en (en),
        .sync_rst (sync_rst),
        .data_in (id_in),
        .data_in_last (id_in_last),
        .data_in_valid (id_in_valid),
        .data_in_ready (id_in_ready),
        .data_out (id_out),
        .data_out_last (id_out_last),
        .data_out_valid (id_out_valid),
        .data_out_ready (id_out_ready),
        .status_ptr_dif (status_ptr_dif)
    );

    // Status Signal Logic
    // - status ID is updated when id_out is updated
    assign status_buffered_ids = status_ptr_dif;
    assign status_id = id_out;
endmodule