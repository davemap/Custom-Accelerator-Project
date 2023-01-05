//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-2 Engine Testbench
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
`timescale 1ns/1ns
`include "message_build.sv"

module tb_engine;
    
    logic clk;
    logic nrst;
    // Data In data and Handshaking
    logic [511:0] data_in;
    logic data_in_last;
    logic data_in_valid;
    logic data_in_ready;
    
    // Config data and Handshaking
    logic [63:0] cfg_size;
    logic [1:0] cfg_scheme;
    logic cfg_valid;
    logic cfg_ready;
    
    // Data Out data and Handshaking
    logic [511:0] data_out;
    logic data_out_valid;
    logic data_out_ready;
        
    message_build uut (
                  .clk (clk),
                  .nrst(nrst),
                  .data_in(data_in),
                  .data_in_valid(data_in_valid),
                  .data_in_ready(data_in_ready),
                  .data_in_last(data_in_last),
                  .cfg_size(cfg_size),
                  .cfg_scheme(cfg_scheme),
                  .cfg_valid(cfg_valid),
                  .cfg_ready(cfg_ready),
                  .data_out(data_out),
                  .data_out_valid(data_out_valid),
                  .data_out_ready(data_out_ready));
    
    logic data_in_drive_en;
    logic [511:0] data_in_queue [$];
    logic data_in_last_queue [$];
    logic data_in_wait_queue;
    
    // Handle Valid and Data for data_in
    always_ff @(posedge clk, negedge nrst) begin: data_in_valid_drive
        if (!nrst) begin
            data_in                 <= 512'd0;
            data_in_valid           <=   1'b0;
            data_in_last            <=   1'b0;
            data_in_wait_queue      <=   1'b1;
        end else if (data_in_drive_en) begin
            if (((data_in_valid == 1'b1) && (data_in_ready == 1'b1)) ||
                 (data_in_wait_queue == 1'b1)) begin
                // Data transfer just completed or transfers already up to date
                if ((data_in_queue.size() > 0) && (data_in_last_queue.size() > 0)) begin
                    data_in            <= data_in_queue.pop_front();
                    data_in_last       <= data_in_last_queue.pop_front();
                    data_in_valid      <= 1'b1;
                    data_in_wait_queue <= 1'b0;
                end else begin
                    // No data currently avaiable in queue to write but transfers up to date
                    data_in_wait_queue <= 1'b1;
                    data_in_valid      <= 1'b0;
                end
            end
        end
    end
    
    int fd; // File descriptor handle
    logic [511:0] input_data;
    logic input_data_last;
    
    initial begin
        $dumpfile("engine_sim.vcd");
        $dumpvars(0, tb_engine);
        data_in_drive_en = 0;
        
        // Read input data into Queue
        fd = $fopen("input_data_builder_stim.csv", "r");
        while ($fscanf (fd, "%x,%b", input_data, input_data_last) == 2) begin
            data_in_queue.push_back(input_data);
            data_in_last_queue.push_back(input_data_last);
        end
        $fclose(fd);
        
        cfg_size = 0;
        cfg_scheme = 0;
        cfg_valid = 0;
        
        data_out_ready = 1;
        
        #20 nrst  = 1;
        #20 nrst  = 0;
        #20 nrst  = 1;
        #20 data_in_drive_en = 1;
       
        // Write some data into the config register
        # 30 
        cfg_size = 448;
        cfg_scheme = 2;
        cfg_valid = 1;
        
        #1200
        $display("Test Complete");
        $finish;
    end
    
    initial begin
        forever begin
            #10 clk = 0;
            #10 clk = 1;
        end
    end
endmodule