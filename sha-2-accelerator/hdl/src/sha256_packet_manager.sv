//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-256 Packet Manager
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2023, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
`include "sha256_id_buf.sv"
`include "sha256_id_issue.sv"
`include "sha256_id_validator.sv"
`include "sha256_config_sync.sv"

module sha256_packet_manager (
    // Clocking Signals
    input logic clk,
    input logic nrst,
    input logic en,

    // Synchronous, localised reset
    input logic sync_rst,
    
    // Config data and Handshaking
    input  logic [63:0] cfg_in_size,
    input  logic [1:0]  cfg_in_scheme,
    input  logic cfg_in_last,
    input  logic cfg_in_valid,
    output logic cfg_in_ready,
    
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

    // Status Signals
    output logic [5:0] status_id,
    output logic [1:0] status_err,
    output logic [9:0] status_packet_count,
    output logic [2:0] status_buffered_ids,
    output logic [63:0] status_size,
    input  logic status_err_clear
);

    logic [5:0] issue_id;
    logic issue_id_last;
    logic issue_id_buf_ready, issue_id_buf_valid;
    logic issue_id_cfg_ready, issue_id_cfg_valid;

    logic [5:0] id_buf_id;
    logic id_buf_id_last;
    logic id_buf_id_ready, id_buf_id_valid;

    logic [63:0] cfg_size;
    logic [1:0]  cfg_scheme;
    logic [5:0] cfg_id;
    logic cfg_last;
    logic cfg_ready, cfg_valid;

    sha256_id_issue id_issuer (
        .clk               (clk),
        .nrst              (nrst),
        .en                (en),
        .sync_rst          (sync_rst),
        .id_out            (issue_id),
        .id_out_last       (issue_id_last),
        .id_out_cfg_valid  (issue_id_cfg_valid),
        .id_out_cfg_ready  (issue_id_cfg_ready),
        .id_out_buf_valid  (issue_id_buf_valid),
        .id_out_buf_ready  (issue_id_buf_ready)
    );

    sha256_config_sync config_synchroniser (
        .clk             (clk),
        .nrst            (nrst),
        .en              (en),
        .sync_rst        (sync_rst),
        .id_in           (issue_id),
        .id_in_last      (issue_id_last),
        .id_in_valid     (issue_id_cfg_valid),
        .id_in_ready     (issue_id_cfg_ready),
        .cfg_in_size     (cfg_in_size),
        .cfg_in_scheme   (cfg_in_scheme),
        .cfg_in_last     (cfg_in_last),
        .cfg_in_valid    (cfg_in_valid),
        .cfg_in_ready    (cfg_in_ready),
        .cfg_out_size    (cfg_size),
        .cfg_out_scheme  (cfg_scheme),
        .cfg_out_id      (cfg_id),
        .cfg_out_last    (cfg_last),
        .cfg_out_valid   (cfg_valid),
        .cfg_out_ready   (cfg_ready),
        .status_size     (status_size)
    );

    sha256_id_buf id_buffer (
        .clk                 (clk),
        .nrst                (nrst),
        .en                  (en),
        .sync_rst            (sync_rst),
        .id_in               (issue_id),
        .id_in_last          (issue_id_last),
        .id_in_valid         (issue_id_buf_valid),
        .id_in_ready         (issue_id_buf_ready),
        .id_out              (id_buf_id),
        .id_out_last         (id_buf_id_last),
        .id_out_valid        (id_buf_id_valid),
        .id_out_ready        (id_buf_id_ready),
        .status_id           (status_id),
        .status_buffered_ids (status_buffered_ids)
    );

    sha256_id_validator id_validator (
        .clk                  (clk),
        .nrst                 (nrst),
        .en                   (en),
        .sync_rst             (sync_rst),
        .id_in_buf            (id_buf_id),
        .id_in_buf_last       (id_buf_id_last),
        .id_in_buf_valid      (id_buf_id_valid),
        .id_in_buf_ready      (id_buf_id_ready),
        .hash_in              (hash_in),
        .hash_in_id           (hash_in_id),
        .hash_in_last         (hash_in_last),
        .hash_in_valid        (hash_in_valid),
        .hash_in_ready        (hash_in_ready),
        .hash_out             (hash_out),
        .hash_out_err         (hash_out_err),
        .hash_out_last        (hash_out_last),
        .hash_out_valid       (hash_out_valid),
        .hash_out_ready       (hash_out_ready),
        .status_err           (status_err),
        .status_packet_count  (status_packet_count),
        .status_clear         (status_err_clear)
    );
    
endmodule