//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-2 Hash Compression Testbench
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
`timescale 1ns/1ns
`include "sha256_hash_compression.sv"

module tb_sha256_hash_compression;
    
    logic clk;
    logic nrst;
    logic en;
    logic sync_rst;
    // Data In data and Handshaking
    logic [511:0] data_in;
    logic [5:0]   data_in_id;
    logic data_in_last;
    logic data_in_valid;
    logic data_in_ready;
    
    // Data Out data and Handshaking
    logic [255:0] data_out;
    logic [5:0]   data_out_id;
    logic data_out_valid;
    logic data_out_ready;
    logic data_out_last;
        
    sha256_hash_compression uut (
                  .clk            (clk),
                  .nrst           (nrst),
                  .en             (en),
                  .sync_rst       (sync_rst),
                  .data_in        (data_in),
                  .data_in_id     (data_in_id),
                  .data_in_valid  (data_in_valid),
                  .data_in_ready  (data_in_ready),
                  .data_in_last   (data_in_last),
                  .data_out       (data_out),
                  .data_out_id    (data_out_id),
                  .data_out_last  (data_out_last),
                  .data_out_valid (data_out_valid),
                  .data_out_ready (data_out_ready));
    
    logic data_in_drive_en;
    logic data_out_drive_ready;
    
    logic [511:0] data_in_queue    [$];
    logic [5:0]   data_in_id_queue [$];
    logic data_in_last_queue       [$];
    int   data_in_gap_queue        [$];
    logic data_in_wait_queue;
    
    
    logic [255:0] data_out_queue    [$];
    logic [5:0]   data_out_id_queue [$];
    logic data_out_last_queue       [$];
    int   data_out_stall_queue      [$];
    logic data_out_wait_queue;
    
    // Handle Valid and Data for data_in
    always_ff @(posedge clk, negedge nrst) begin: data_in_valid_drive
        if (!nrst) begin
            data_in                 <= 512'd0;
            data_in_id              <=   6'd0;
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
                if ((data_in_queue.size() > 0) && (data_in_id_queue.size() > 0) && (data_in_last_queue.size() > 0) && (data_in_gap_queue.size() > 0)) begin
                    data_in            <= data_in_queue.pop_front();
                    data_in_id         <= data_in_id_queue.pop_front();
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
    
    
    logic [255:0] data_out_check;
    logic [5:0]   data_out_id_check;
    logic data_out_last_check;

    int   data_in_gap;
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
            if ((data_out_queue.size() > 0) && (data_out_id_queue.size() > 0) && (data_out_last_queue.size() > 0)) begin
                data_out_check      <= data_out_queue.pop_front();
                data_out_id_check   <= data_out_id_queue.pop_front();
                data_out_last_check <= data_out_last_queue.pop_front();
                if (data_out_last_check == 1'b1) begin
                    packet_num <= packet_num + 1;
                end
            end else begin
                $display("Test Passes");
                $finish;
            end
        end
    end
    
    // File Reading Variables
    int fd; // File descriptor Handle
    
    logic [511:0] temp_data_in; // Temporary Input Data Storage
    logic [5:0]   temp_data_in_id; // Temporary Input Data Storage
    logic temp_data_in_last;    // Temporary Input Data Last
    int   temp_data_in_gap;     // Temporary Input Gap
    
    
    logic [255:0] temp_data_out; // Temporary Output Data Storage
    logic [5:0]   temp_data_out_id; // Temporary Output Data Storage
    logic temp_data_out_last;    // Temporary Output Data Last
    int  temp_data_out_stall;    // Temporary Output Stall 
    
    initial begin
        $dumpfile("sha256_hash_compression.vcd");
        if ($test$plusargs ("DEBUG")) begin
            $dumpvars(0, tb_sha256_hash_compression);
            for (int i = 0; i < 16; i++) begin
                $dumpvars(0, tb_sha256_hash_compression.uut.M[i]);
            end
            for (int i = 0; i < 8; i++) begin
                $dumpvars(0, tb_sha256_hash_compression.uut.H[i]);
                $dumpvars(0, tb_sha256_hash_compression.uut.next_H[i]);
            end
            for (int i = 0; i < 64; i++) begin
                $dumpvars(0, tb_sha256_hash_compression.uut.W[i]);
                $dumpvars(0, tb_sha256_hash_compression.uut.next_W[i]);
                $dumpvars(0, tb_sha256_hash_compression.uut.ssig1_next_W[i]);
            end
        end
        data_in_drive_en = 0;
        data_out_drive_ready = 0;
        
        // Read input data into Queue
        fd = $fopen("../stimulus/unit/input_message_block_stim.csv", "r");
        while ($fscanf (fd, "%x,%d,%b,%d", temp_data_in, temp_data_in_id, temp_data_in_last, temp_data_in_gap) == 4) begin
            data_in_queue.push_back(temp_data_in);
            data_in_id_queue.push_back(temp_data_in_id);
            data_in_last_queue.push_back(temp_data_in_last);
            data_in_gap_queue.push_back(temp_data_in_gap);
        end
        $fclose(fd);
        
        // Read output data into Queue
        fd = $fopen("../stimulus/unit/output_hash_ref.csv", "r");
        while ($fscanf (fd, "%x,%d,%b,%d", temp_data_out, temp_data_out_id, temp_data_out_last, temp_data_out_stall) == 4) begin
            data_out_queue.push_back(temp_data_out);
            data_out_id_queue.push_back(temp_data_out_id);
            data_out_last_queue.push_back(temp_data_out_last);
            data_out_stall_queue.push_back(temp_data_out_stall);
        end
        $fclose(fd);
        
        // Initialise First Checking Values
        data_out_check      = data_out_queue.pop_front();      
        data_out_id_check   = data_out_id_queue.pop_front();      
        data_out_last_check = data_out_last_queue.pop_front();
        data_out_stall      = data_out_stall_queue.pop_front();
        
        // Enable Hash Compression
        en = 1;
        
        // Defaultly set Sync Reset Low
        sync_rst  = 0;
        
        #20 nrst  = 1;
        #20 nrst  = 0;
        #20 nrst  = 1;
        #20 data_in_drive_en = 1;
       
        # 30 data_out_drive_ready = 1;
    end
    
    initial begin
        forever begin
            #10 clk = 0;
            #10 clk = 1;
        end
    end
    
endmodule