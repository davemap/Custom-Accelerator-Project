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
`include "sha256_engine.sv"

module tb_sha256_engine;
    
    logic clk;
    logic nrst;
    logic en;
    logic sync_rst;
    // Data In data and Handshaking
    logic [511:0] data_in;
    logic data_in_last;
    logic data_in_valid;
    logic data_in_ready;
    
    // Config data and Handshaking
    logic [63:0] cfg_size;
    logic [1:0] cfg_scheme;
    logic cfg_last;
    logic cfg_valid;
    logic cfg_ready;
    
    // Data Out data and Handshaking
    logic [255:0] data_out;
    logic data_out_valid;
    logic data_out_ready;
    logic data_out_last;
        
    sha256_engine uut (
        .clk            (clk),
        .nrst           (nrst),
        .en             (en),
        .sync_rst       (sync_rst),
        .data_in        (data_in),
        .data_in_valid  (data_in_valid),
        .data_in_ready  (data_in_ready),
        .data_in_last   (data_in_last),
        .cfg_size       (cfg_size),
        .cfg_scheme     (cfg_scheme),
        .cfg_last       (cfg_last),
        .cfg_valid      (cfg_valid),
        .cfg_ready      (cfg_ready),
        .data_out       (data_out),
        .data_out_last  (data_out_last),
        .data_out_valid (data_out_valid),
        .data_out_ready (data_out_ready)
    );
    
    logic data_in_drive_en;
    logic cfg_drive_en;
    logic data_out_drive_ready;
    
    logic [511:0] data_in_queue [$];
    logic data_in_last_queue    [$];
    int   data_in_gap_queue     [$];
    logic data_in_wait_queue;
    
    logic [63:0] cfg_size_queue  [$];
    logic [1:0] cfg_scheme_queue [$];
    logic cfg_last_queue         [$];
    int   cfg_gap_queue          [$];
    logic cfg_wait_queue;
    
    logic [511:0] message_block_queue [$];
    logic message_block_last_queue    [$];
    logic message_block_wait_queue;
    
    logic [255:0] data_out_queue [$];
    logic data_out_last_queue    [$];
    int   data_out_stall_queue   [$];
    logic data_out_wait_queue;
    
    // Handle Valid and Data for data_in
    always_ff @(posedge clk, negedge nrst) begin: data_in_valid_drive
        if (!nrst) begin
            data_in                 <= 512'd0;
            data_in_valid           <=   1'b0;
            data_in_last            <=   1'b0;
            data_in_gap             <=   0;
            data_in_wait_queue      <=   1'b1;
        end else if (data_in_drive_en) begin
            if (data_in_gap > 1) begin
                data_in_gap <= data_in_gap -1;
                data_in_valid <= 1'b0;
            end else begin
                data_in_valid <= 1'b1;
            end
            if (((data_in_valid == 1'b1) && (data_in_ready == 1'b1)) ||
                 (data_in_wait_queue == 1'b1)) begin
                // Data transfer just completed or transfers already up to date
                if ((data_in_queue.size() > 0) && (data_in_last_queue.size() > 0) && (data_in_gap_queue.size() > 0)) begin
                    data_in            <= data_in_queue.pop_front();
                    data_in_last       <= data_in_last_queue.pop_front();
                    if (data_in_gap_queue[0] == 0) begin
                        data_in_valid  <= 1'b1;
                    end else begin
                        data_in_valid  <= 1'b0;
                    end
                    data_in_gap        <= data_in_gap_queue.pop_front();
                    data_in_wait_queue <= 1'b0;
                end else begin
                    // No data currently avaiable in queue to write but transfers up to date
                    data_in_wait_queue <= 1'b1;
                    data_in_valid      <= 1'b0;
                end
            end
        end
    end

    // Handle Valid and Data for cfg
    always_ff @(posedge clk, negedge nrst) begin: cfg_valid_drive
        if (!nrst) begin
            cfg_size            <=  64'd0;
            cfg_scheme          <=   2'd0;
            cfg_valid           <=   1'b0;
            cfg_last            <=   1'b0;
            cfg_gap              <=   0;
            cfg_wait_queue      <=   1'b1;
        end else if (cfg_drive_en) begin
            if (cfg_gap > 1) begin
                cfg_gap <= cfg_gap -1;
                cfg_valid <= 1'b0;
            end else begin
                cfg_valid <= 1'b1;
            end
            if (((cfg_valid == 1'b1) && (cfg_ready == 1'b1)) ||
                 (cfg_wait_queue == 1'b1)) begin
                // cfg transfer just completed or transfers already up to date
                if ((cfg_size_queue.size() > 0) && (cfg_scheme_queue.size() > 0 ) && (cfg_last_queue.size() > 0) && (cfg_gap_queue.size() > 0)) begin
                    cfg_size       <= cfg_size_queue.pop_front();
                    cfg_scheme     <= cfg_scheme_queue.pop_front();
                    cfg_last       <= cfg_last_queue.pop_front();
                    if (cfg_gap_queue[0] == 0) begin
                        cfg_valid  <= 1'b1;
                    end else begin
                        cfg_valid  <= 1'b0;
                    end
                    cfg_gap        <= cfg_gap_queue.pop_front();
                    cfg_wait_queue <= 1'b0;
                end else begin
                    // No data currently avaiable in queue to write but transfers up to date
                    cfg_wait_queue <= 1'b1;
                    cfg_valid      <= 1'b0;
                end
            end
        end
    end
    
    logic [511:0] message_block_data_out_check;
    logic message_block_data_out_last_check;
    int   message_block_packet_num;
    
    logic [255:0] data_out_check;
    logic data_out_last_check;
    int   data_in_gap;
    int   cfg_gap;
    int   data_out_stall;
    
    int   packet_num;
    
    // Handle Output Ready Signal Verification
    always @(posedge clk) begin
        // Check Override Control on Ready
        if (data_out_drive_ready) begin
            // Count down to zero before enabling Ready
            if (data_out_stall > 1) begin
                data_out_stall <= data_out_stall - 1;
                data_out_ready <= 1'b0;
            end else begin
                // Wait for handshake before updating stall value
                if ((data_out_valid == 1'b1) && (data_out_ready == 1'b1)) begin
                    if (data_out_stall_queue.size() > 0) begin
                        if (data_out_stall_queue[0] == 0) begin
                            data_out_ready <= 1'b1;
                        end else begin
                            data_out_ready <= 1'b0;
                        end
                        data_out_stall <= data_out_stall_queue.pop_front();
                    end
                // Keep Ready Asserted until handshake seen
                end else begin
                    data_out_ready <= 1'b1;
                end
            end
        end else begin
            data_out_ready <= 1'b0;
        end
    end
    
    // Handle Output Data Verification
    always @(posedge clk) begin
        // Check Data on Handshake
        if ((data_out_valid == 1'b1) && (data_out_ready == 1'b1)) begin
            assert (data_out == data_out_check) else begin
                $error("data_out missmatch! packet %d | recieve: %x != check: %x", packet_num, data_out, data_out_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("data_out match! packet %d | recieve: %x == check: %x", packet_num, data_out, data_out_check);
            assert (data_out_last == data_out_last_check) else begin
                $error("data_out_last missmatch! packet %d | recieve: %x != check: %x", packet_num, data_out_last, data_out_last_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("data_out_last match! packet %d | recieve: %x == check: %x", packet_num, data_out_last, data_out_last_check);
            if ((data_out_queue.size() > 0) && (data_out_last_queue.size() > 0)) begin
                data_out_check      <= data_out_queue.pop_front();
                data_out_last_check <= data_out_last_queue.pop_front();
                if (data_out_last_check == 1'b1) begin
                    packet_num <= packet_num + 1;
                end
            end else begin
                $display("Test Passes");
                $finish;
            end
        end
        
        // Check Message Block Handshake
        if ((message_builder_out_data_valid == 1'b1) && (message_builder_out_data_ready == 1'b1)) begin
            assert (message_builder_out_data == message_block_data_out_check) else begin
                $error("message block missmatch! packet %d | recieve: %x != check: %x", message_block_packet_num, data_out, message_block_data_out_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("message block match! packet %d | recieve: %x == check: %x", message_block_packet_num, message_builder_out_data, message_block_data_out_check);
            assert (message_builder_out_data_last == message_block_data_out_last_check) else begin
                $error("message block last missmatch! packet %d | recieve: %x != check: %x", message_block_packet_num, message_builder_out_data_last, message_block_data_out_last_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("message block last match! packet %d | recieve: %x == check: %x", message_block_packet_num, message_builder_out_data_last, message_block_data_out_last_check);
            if ((message_block_queue.size() > 0) && (message_block_last_queue.size() > 0)) begin
                message_block_data_out_check      <= message_block_queue.pop_front();
                message_block_data_out_last_check <= message_block_last_queue.pop_front();
                if (message_block_data_out_last_check == 1'b1) begin
                    message_block_packet_num <= message_block_packet_num + 1;
                end
            end
        end
    end
    
    // File Reading Variables
    int fd; // File descriptor Handle
    
    logic [511:0] input_data; // Temporary Input Data Storage
    logic input_data_last;    // Temporary Input Data Last
    int   input_data_gap;     // Temporary Input Gap
    
    logic [63:0] input_cfg_size;   // Temporary cfg size 
    logic [1:0]  input_cfg_scheme; // Temporary cfg scheme
    logic input_cfg_last;          // Temporary cfg last;
    int   input_cfg_gap;           // Temporary cfg gap;
    
    logic [255:0] output_data; // Temporary Output Data Storage
    logic output_data_last;    // Temporary Output Data Last
    int  output_data_stall;    // Temporary Output Stall 
    
    
    logic [511:0] message_block_data; // Temporary Message Block Data Storage
    logic message_block_data_last;    // Temporary Message Block Data Last
    int   message_block_stall;        // Dummy Variable to Read Stall Values into (goes unused other than file parsing)
    
    logic [511:0] message_builder_out_data;
    logic  message_builder_out_data_last;
    
    assign message_builder_out_data = tb_sha256_engine.uut.message_block;
    assign message_builder_out_data_last = tb_sha256_engine.uut.message_block_last;
    assign message_builder_out_data_valid = tb_sha256_engine.uut.message_block_valid;
    assign message_builder_out_data_ready = tb_sha256_engine.uut.message_block_ready;
    
    initial begin
        $dumpfile("sha256_engine.vcd");
        $dumpvars(0, tb_sha256_engine);
        if ($test$plusargs ("DEBUG")) begin
            for (int i = 0; i < 16; i++) begin
                $dumpvars(0, tb_sha256_engine.uut.hash_calculator.M[i]);
            end
            for (int i = 0; i < 8; i++) begin
                $dumpvars(0, tb_sha256_engine.uut.hash_calculator.H[i]);
                $dumpvars(0, tb_sha256_engine.uut.hash_calculator.next_H[i]);
            end
            for (int i = 0; i < 64; i++) begin
                $dumpvars(0, tb_sha256_engine.uut.hash_calculator.W[i]);
                $dumpvars(0, tb_sha256_engine.uut.hash_calculator.next_W[i]);
                $dumpvars(0, tb_sha256_engine.uut.hash_calculator.ssig1_next_W[i]);
            end
        end
        data_in_drive_en = 0;
        cfg_drive_en = 0;
        data_out_drive_ready = 0;
        
        // Read input data into Queue
        fd = $fopen("../stimulus/testbench/input_data_stim.csv", "r");
        while ($fscanf (fd, "%x,%b,%d", input_data, input_data_last, input_data_gap) == 3) begin
            data_in_queue.push_back(input_data);
            data_in_last_queue.push_back(input_data_last);
            data_in_gap_queue.push_back(input_data_gap);
        end
        $fclose(fd);
        
        // Read input cfg into Queue
        fd = $fopen("../stimulus/testbench/input_cfg_stim.csv", "r");
        while ($fscanf (fd, "%x,%x,%b,%d", input_cfg_size, input_cfg_scheme, input_cfg_last, input_cfg_gap) == 4) begin
            cfg_size_queue.push_back(input_cfg_size);
            cfg_scheme_queue.push_back(input_cfg_scheme);
            cfg_last_queue.push_back(input_cfg_last);
            cfg_gap_queue.push_back(input_cfg_gap);
        end
        $fclose(fd);
        
        // Read output data into Queue
        fd = $fopen("../stimulus/testbench/output_hash_ref.csv", "r");
        while ($fscanf (fd, "%x,%b,%d", output_data, output_data_last, output_data_stall) == 3) begin
            data_out_queue.push_back(output_data);
            data_out_last_queue.push_back(output_data_last);
            data_out_stall_queue.push_back(output_data_stall);
        end
        $fclose(fd);
        
        // Read Message Block data into Queue
        fd = $fopen("../stimulus/testbench/output_message_block_ref.csv", "r");
        while ($fscanf (fd, "%x,%b,%d", message_block_data, message_block_data_last, message_block_stall) == 3) begin
            message_block_queue.push_back(message_block_data);
            message_block_last_queue.push_back(message_block_data_last);
        end
        $fclose(fd);
        
        // Initialise First Checking Values
        data_out_check      = data_out_queue.pop_front();      
        data_out_last_check = data_out_last_queue.pop_front();
        data_out_stall      = data_out_stall_queue.pop_front();
        
        message_block_data_out_check      = message_block_queue.pop_front();      
        message_block_data_out_last_check = message_block_last_queue.pop_front();
        
        // Enable Hash Compression
        en = 1;
        
        // Defaultly set Sync Reset Low
        sync_rst  = 0;
        
        #20 nrst  = 1;
        #20 nrst  = 0;
        #20 nrst  = 1;
        #20 data_in_drive_en = 1;
       
        // Write some data into the config register
        # 30 cfg_drive_en = 1;
        
        # 30 data_out_drive_ready = 1;
    end
    
    initial begin
        forever begin
            #10 clk = 0;
            #10 clk = 1;
        end
    end
    
endmodule