//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-256 Configuration Synchroniser
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2023, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
module sha256_config_sync (
    input logic clk,
    input logic nrst,
    input logic en,
    
    // Synchronous, localised reset
    input logic sync_rst,
    
    // ID In and Handshaking
    input  logic [5:0] id_in,
    input  logic id_in_last,
    input  logic id_in_valid,
    output logic id_in_ready,
    
    // Config data and Handshaking
    input  logic [63:0] cfg_in_size,
    input  logic [1:0]  cfg_in_scheme,
    input  logic cfg_in_last,
    input  logic cfg_in_valid,
    output logic cfg_in_ready,
    
    // Data Out data and Handshaking
    output logic [63:0] cfg_out_size,
    output logic [1:0]  cfg_out_scheme,
    output logic [5:0]  cfg_out_id,
    output logic cfg_out_last,
    output logic cfg_out_valid,
    input  logic cfg_out_ready,

    // Status Out - Gets updated after every hash
    // - outputs size and then clears size to 0
    // - status regs are looking for non-zero size
    output logic [63:0] status_size,
    input  logic status_clear
);

    logic [1:0] state, next_state;

    logic next_cfg_in_ready;
    logic next_id_in_ready;

    logic [63:0] next_cfg_out_size;
    logic [1:0]  next_cfg_out_scheme;
    logic [5:0]  next_cfg_out_id;
    logic        next_cfg_out_last;
    logic        next_cfg_out_valid;

    logic [63:0] next_status_size;

    // State Machine Sequential Logic    
    always_ff @(posedge clk, negedge nrst) begin
        if ((!nrst) | sync_rst) begin
            state            <= 2'd0;
            cfg_out_size     <= 64'd0;
            cfg_out_scheme   <= 2'd0;
            cfg_out_id       <= 6'd0;
            cfg_out_last     <= 1'b0;
            cfg_out_valid    <= 1'b0;
            cfg_in_ready     <= 1'b0;
            id_in_ready      <= 1'b0;
            status_size      <= 64'd0;
        end else if (en == 1'b1) begin
            state            <= next_state;   
            cfg_out_size     <= next_cfg_out_size;
            cfg_out_scheme   <= next_cfg_out_scheme;
            cfg_out_id       <= next_cfg_out_id;
            cfg_out_last     <= next_cfg_out_last;
            cfg_out_valid    <= next_cfg_out_valid;
            cfg_in_ready     <= next_cfg_in_ready;
            id_in_ready      <= next_id_in_ready;
            status_size      <= next_status_size;
        end else begin
            cfg_out_valid    <= 1'b0;
            cfg_in_ready     <= 1'b0;
            id_in_ready      <= 1'b0;
            status_size      <= 64'd0;
        end
    end

    always_comb begin
        // Default
        next_state           = state;   
        next_cfg_out_size    = cfg_out_size;
        next_cfg_out_scheme  = cfg_out_scheme;
        next_cfg_out_id      = cfg_out_id;
        next_cfg_out_last    = cfg_out_last;
        next_cfg_out_valid   = cfg_out_valid;
        next_cfg_in_ready    = cfg_in_ready;
        next_id_in_ready     = id_in_ready;
        next_status_size     = status_size;
        
        // Override
        case (state)
            2'd0: begin
                    next_cfg_in_ready  = 1'b1;
                    next_id_in_ready   = 1'b1;
                    next_state         = 2'd1;
                end
            
            2'd1: begin
                    // Handle Status Signals
                    if (status_clear) begin
                        next_status_size = 64'd0;
                    end
                    // Check outputs can be written to
                    if (cfg_out_valid && !cfg_out_ready) begin
                        // If data out is valid and ready is low, there is already data waiting to be transferred
                        next_cfg_in_ready = 1'b0;
                        next_id_in_ready  = 1'b0;
                    // If there is no Valid data at the output or there is a valid transfer happening on this clock cycle
                    end else begin
                        // These can be overloaded later if data is written to the outputs
                        next_cfg_out_valid = 1'b0; 
                        next_cfg_in_ready  = 1'b1;
                        next_id_in_ready   = 1'b1;
                        next_cfg_out_last  = 1'b0;
                        // Check cfg input
                        if (cfg_in_ready && cfg_in_valid) begin
                            next_cfg_out_last   = cfg_in_last;
                            next_cfg_out_scheme = cfg_in_scheme;
                            next_cfg_out_size   = cfg_in_size;
                            next_status_size    = cfg_in_size;
                            next_cfg_in_ready   = 1'b0;
                            next_state          = 2'd2;
                        end
                        // Check Id input
                        if (id_in_ready && id_in_valid) begin
                            next_cfg_out_id     = id_in;
                            next_id_in_ready    = 1'b0;
                            next_state          = 2'd3;
                        end
                        // Check if both inputs handshaked
                        if ((id_in_ready && id_in_valid) && (cfg_in_ready && cfg_in_valid)) begin
                            next_cfg_out_valid  = 1'b1;
                            if (!cfg_out_valid && cfg_out_ready) begin 
                                // In case where no valid data and ready is waiting for valid data 
                                // - (will be asserted next cc), guaranteed handshake next cycle
                                next_cfg_in_ready   = 1'b1;
                                next_cfg_in_ready   = 1'b1;
                            end else begin
                                next_cfg_in_ready   = 1'b0;
                                next_id_in_ready    = 1'b0;
                            end
                            next_state          = 2'd1;
                        end
                    end
                end
            
            2'd2: begin // Cfg already handshaked - wait for ID handshake
                    // Handle Status Signals
                    if (status_clear) begin
                        next_status_size = 64'd0;
                    end
                    // These can be overloaded later if data is written to the outputs
                    next_cfg_out_valid = 1'b0; 
                    next_cfg_in_ready  = 1'b0;
                    next_id_in_ready   = 1'b1;
                    // Check Id input
                    if (id_in_ready && id_in_valid) begin
                        next_cfg_out_id    = id_in;
                        next_cfg_out_valid = 1'b1;
                        if (cfg_out_ready) begin // Guaranteeded Handshake next clock cycle
                            next_cfg_in_ready   = 1'b1;
                            next_id_in_ready    = 1'b1;
                        end else begin
                            next_cfg_in_ready   = 1'b0;
                            next_id_in_ready    = 1'b0;
                        end
                        next_state         = 2'd1;
                    end
                end

            2'd3: begin // ID already handshaked - wait for config handshake
                    // Handle Status Signals
                    if (status_clear) begin
                        next_status_size = 64'd0;
                    end
                    // These can be overloaded later if data is written to the outputs
                    next_cfg_out_valid = 1'b0; 
                    next_cfg_in_ready  = 1'b1;
                    next_id_in_ready   = 1'b0;
                    // Check config input
                    if (cfg_in_ready && cfg_in_valid) begin
                        next_cfg_out_last   = cfg_in_last;
                        next_cfg_out_scheme = cfg_in_scheme;
                        next_cfg_out_size   = cfg_in_size;
                        next_cfg_out_valid  = 1'b1;
                        next_status_size    = cfg_in_size;
                        if (cfg_out_ready) begin // Guaranteeded Handshake next clock cycle
                            next_cfg_in_ready   = 1'b1;
                            next_id_in_ready    = 1'b1;
                        end else begin
                            next_cfg_in_ready   = 1'b0;
                            next_id_in_ready    = 1'b0;
                        end
                        next_state          = 2'd1;
                    end
                end
        endcase
    end
endmodule