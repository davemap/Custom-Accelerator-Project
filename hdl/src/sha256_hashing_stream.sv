//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-256 Hashing Stream
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
`include "sha256_hash_compression.sv"
`include "sha256_message_build.sv"
`include "sha256_id_issue.sv"
`include "fifo_vr.sv"

module sha256_hashing_stream (
    // Clocking Signals
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
    output logic [255:0] data_out,
    output logic data_out_last,
    output logic data_out_valid,
    input  logic data_out_ready
);
    
    logic [511:0] data_in_buffered;
    logic data_in_last_buffered;
    logic data_in_valid_buffered;
    logic data_in_ready_buffered;
    
    logic [63:0] cfg_size_buffered;
    logic [1:0]  cfg_scheme_buffered;
    logic cfg_last_buffered;
    logic cfg_valid_buffered;
    logic cfg_ready_buffered;
    
    logic [5:0] id_val;
    
    logic [511:0] message_block;
    logic message_block_last;
    logic message_block_valid;
    logic message_block_ready;
    
    logic [511:0] message_block_buffered;
    logic message_block_last_buffered;
    logic message_block_valid_buffered;
    logic message_block_ready_buffered;
    
    logic [255:0] hash;
    logic hash_last;
    logic hash_valid;
    logic hash_ready;
    
    // Data-in FIFO
    fifo_vr #(16, // Depth
              512 // Data Width 
    ) data_in_buffer (
        .clk            (clk),
        .nrst           (nrst),
        .en             (en),
        .sync_rst       (sync_rst),
        .data_in        (data_in),
        .data_in_valid  (data_in_valid),
        .data_in_ready  (data_in_ready),
        .data_in_last   (data_in_last),
        .data_out       (data_in_buffered),
        .data_out_last  (data_in_last_buffered),
        .data_out_valid (data_in_valid_buffered),
        .data_out_ready (data_in_ready_buffered),
        .status_ptr_dif ()
    );
    
    // Configuration FIFO
    fifo_vr #(8, // Depth
              66 // Data Width 
    ) cfg_buffer (
        .clk            (clk),
        .nrst           (nrst),
        .en             (en),
        .sync_rst       (sync_rst),
        .data_in        ({cfg_size, cfg_scheme}),
        .data_in_valid  (cfg_valid),
        .data_in_ready  (cfg_ready),
        .data_in_last   (cfg_last),
        .data_out       ({cfg_size_buffered,cfg_scheme_buffered}),
        .data_out_last  (cfg_last_buffered),
        .data_out_valid (cfg_valid_buffered),
        .data_out_ready (cfg_ready_buffered),
        .status_ptr_dif ()
    );
    
    // Message Build (Construct Message Blocks)
    sha256_message_build message_block_builder (
        .clk            (clk),
        .nrst           (nrst),
        .en             (en),
        .sync_rst       (sync_rst),
        .data_in        (data_in_buffered),
        .data_in_valid  (data_in_valid_buffered),
        .data_in_ready  (data_in_ready_buffered),
        .data_in_last   (data_in_last_buffered),
        .cfg_size       (cfg_size_buffered),
        .cfg_scheme     (cfg_scheme_buffered),
        .cfg_last       (cfg_last_buffered),
        .cfg_valid      (cfg_valid_buffered),
        .cfg_ready      (cfg_ready_buffered),
        .cfg_id         (),
        .data_out       (message_block),
        .data_out_last  (message_block_last),
        .data_out_valid (message_block_valid),
        .data_out_ready (message_block_ready),
        .data_out_id    ()
    );
    
    // Intermediate FIFO
    fifo_vr #(16,  // Depth
              512 // Data Width 
    ) message_block_buffer (
        .clk            (clk),
        .nrst           (nrst),
        .en             (en),
        .sync_rst       (sync_rst),
        .data_in        (message_block),
        .data_in_valid  (message_block_valid),
        .data_in_ready  (message_block_ready),
        .data_in_last   (message_block_last),
        .data_out       (message_block_buffered),
        .data_out_last  (message_block_last_buffered),
        .data_out_valid (message_block_valid_buffered),
        .data_out_ready (message_block_ready_buffered),
        .status_ptr_dif ()
    );
    

    // Hash Compression (Peform Hash Calculation)
    sha256_hash_compression hash_calculator (
        .clk            (clk),
        .nrst           (nrst),
        .en             (en),
        .sync_rst       (sync_rst),
        .data_in        (message_block_buffered),
        .data_in_valid  (message_block_valid_buffered),
        .data_in_ready  (message_block_ready_buffered),
        .data_in_last   (message_block_last_buffered),
        .data_in_id     (),
        .data_out       (hash),
        .data_out_last  (hash_last),
        .data_out_valid (hash_valid),
        .data_out_ready (hash_ready),
        .data_out_id    ()
    );

    // Data-out FIFO
    fifo_vr #(4,  // Depth
              256 // Data Width 
    ) data_out_buffer (
        .clk            (clk),
        .nrst           (nrst),
        .en             (en),
        .sync_rst       (sync_rst),
        .data_in        (hash),
        .data_in_valid  (hash_valid),
        .data_in_ready  (hash_ready),
        .data_in_last   (hash_last),
        .data_out       (data_out),
        .data_out_last  (data_out_last),
        .data_out_valid (data_out_valid),
        .data_out_ready (data_out_ready),
        .status_ptr_dif ()
    );
    
endmodule