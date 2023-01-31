//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-2 ID Validator Testbench
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
`timescale 1ns/1ns
`include "sha256_id_validator.sv"

module tb_sha256_id_validator;
    
    logic clk;
    logic nrst;
    logic en;
    logic sync_rst;
    
    // ID Buffer IN
    logic [5:0] id_in_buf;
    logic id_in_buf_last;
    logic id_in_buf_valid;
    logic id_in_buf_ready;

    // Hash IN
    logic [255:0] hash_in;
    logic [5:0]   hash_in_id;
    logic hash_in_last;
    logic hash_in_valid;
    logic hash_in_ready;

    // Hash Out
    logic [255:0] hash_out;
    logic hash_out_err;
    logic hash_out_last;
    logic hash_out_valid;
    logic hash_out_ready;

    // Status Out - Gets updated after every hash
    logic [1:0] status_err;
    logic [9:0] status_packet_count;
    logic status_clear;
        
    sha256_id_validator uut (
            .clk               (clk),
            .nrst              (nrst),
            .en                (en),
            .sync_rst          (sync_rst),
            
            // ID Buffer IN
            .id_in_buf         (id_in_buf),
            .id_in_buf_last    (id_in_buf_last),
            .id_in_buf_valid   (id_in_buf_valid),
            .id_in_buf_ready   (id_in_buf_ready),

            // Hash IN
            .hash_in           (hash_in),
            .hash_in_id        (hash_in_id),
            .hash_in_last      (hash_in_last),
            .hash_in_valid     (hash_in_valid),
            .hash_in_ready     (hash_in_ready),

            // Hash Out
            .hash_out          (hash_out),
            .hash_out_err      (hash_out_err),
            .hash_out_last     (hash_out_last),
            .hash_out_valid    (hash_out_valid),
            .hash_out_ready    (hash_out_ready),

            // Status Out - Gets updated after every hash
            .status_err           (status_err),
            .status_packet_count  (status_packet_count),
            .status_clear         (status_clear)
        );
    
    logic id_in_buf_drive_en;
    logic hash_in_drive_en;

    logic hash_out_drive_ready;
    // TODO: logic status_out_handle;
    // TODO: Test varying ID Values - not always same ID's
    
    logic [5:0]  id_in_buf_queue      [$];
    logic        id_in_buf_last_queue [$];
    int          id_in_buf_gap_queue  [$];
    logic        id_in_buf_wait_queue;
    
    logic [255:0] hash_in_queue        [$];
    logic [5:0]   hash_in_id_queue     [$];
    logic         hash_in_last_queue   [$];
    int           hash_in_gap_queue    [$];
    logic         hash_in_wait_queue;

    logic [255:0] hash_out_queue        [$];
    logic         hash_out_err_queue    [$];
    logic         hash_out_last_queue   [$];
    int           hash_out_stall_queue  [$];
    logic         hash_out_wait_queue;

    // TODO: Handle Status Checking
     
    // Handle Valid and Data for id_in_buf
    always_ff @(posedge clk, negedge nrst) begin: id_in_buf_valid_drive
        if (!nrst) begin
            id_in_buf                 <= 512'd0;
            id_in_buf_valid           <=   1'b0;
            id_in_buf_last            <=   1'b0;
            id_in_buf_gap             <=   0;
            id_in_buf_wait_queue      <=   1'b1;
        end else if (id_in_buf_drive_en) begin
            if (id_in_buf_gap > 1) begin
                id_in_buf_gap <= id_in_buf_gap - 1;
                id_in_buf_valid <= 1'b0;
            end else begin
                id_in_buf_valid <= 1'b1;
            end
            if (((id_in_buf_valid == 1'b1) && (id_in_buf_ready == 1'b1)) ||
                 (id_in_buf_wait_queue == 1'b1)) begin
                // Data transfer just completed or transfers already up to date
                if ((id_in_buf_queue.size() > 0) && (id_in_buf_last_queue.size() > 0) && (id_in_buf_gap_queue.size() > 0)) begin
                    id_in_buf            <= id_in_buf_queue.pop_front();
                    id_in_buf_last       <= id_in_buf_last_queue.pop_front();
                    if (id_in_buf_gap_queue[0] == 0) begin
                        id_in_buf_valid  <= 1'b1;
                    end else begin
                        id_in_buf_valid  <= 1'b0;
                    end
                    id_in_buf_gap        <= id_in_buf_gap_queue.pop_front();
                    id_in_buf_wait_queue <= 1'b0;
                end else begin
                    // No data currently avaiable in queue to write but transfers up to date
                    id_in_buf_wait_queue <= 1'b1;
                    id_in_buf_valid      <= 1'b0;
                end
            end
        end
    end

    // Handle Valid and Data for hash_in
    always_ff @(posedge clk, negedge nrst) begin: hash_in_valid_drive
        if (!nrst) begin
            hash_in               <=  256'd0;
            hash_in_id            <=    6'd0;
            hash_in_valid         <=    1'b0;
            hash_in_last          <=    1'b0;
            hash_in_gap           <=      0;
            hash_in_wait_queue    <=    1'b1;
        end else if (hash_in_drive_en) begin
            if (hash_in_gap > 1) begin
                hash_in_gap <= hash_in_gap -1;
                hash_in_valid <= 1'b0;
            end else begin
                hash_in_valid <= 1'b1;
            end
            if (((hash_in_valid == 1'b1) && (hash_in_ready == 1'b1)) ||
                 (hash_in_wait_queue == 1'b1)) begin
                // hash_in transfer just completed or transfers already up to date
                if ((hash_in_queue.size() > 0) && (hash_in_id_queue.size() > 0 ) && (hash_in_last_queue.size() > 0) && (hash_in_gap_queue.size() > 0)) begin
                    hash_in            <= hash_in_queue.pop_front();
                    hash_in_id         <= hash_in_id_queue.pop_front();
                    hash_in_last       <= hash_in_last_queue.pop_front();
                    if (hash_in_gap_queue[0] == 0) begin
                        hash_in_valid  <= 1'b1;
                    end else begin
                        hash_in_valid  <= 1'b0;
                    end
                    hash_in_gap        <= hash_in_gap_queue.pop_front();
                    hash_in_wait_queue <= 1'b0;
                end else begin
                    // No data currently avaiable in queue to write but transfers up to date
                    hash_in_wait_queue <= 1'b1;
                    hash_in_valid      <= 1'b0;
                end
            end
        end
    end
    
    logic [255:0] hash_out_check;
    logic         hash_out_err_check;  
    logic         hash_out_last_check;

    int id_in_buf_gap;
    int hash_in_gap;
    int hash_out_stall;
    
    int packet_num;
    
    // Handle Output Ready Signal Verification
    always @(posedge clk) begin
        // Check Override Control on Ready
        if (hash_out_drive_ready) begin
            // Count down to zero before enabling Ready
            if (hash_out_stall > 1) begin
                hash_out_stall <= hash_out_stall - 1;
                hash_out_ready <= 1'b0;
            end else begin
                // Wait for handshake before updating stall value
                if ((hash_out_valid == 1'b1) && (hash_out_ready == 1'b1)) begin
                    if (hash_out_stall_queue.size() > 0) begin
                        if (hash_out_stall_queue[0] == 0) begin
                            hash_out_ready <= 1'b1;
                        end else begin
                            hash_out_ready <= 1'b0;
                        end
                        hash_out_stall <= hash_out_stall_queue.pop_front();
                    end
                // Keep Ready Asserted until handshake seen
                end else begin
                    hash_out_ready <= 1'b1;
                end
            end
        end else begin
            hash_out_ready <= 1'b0;
        end
    end
    
    // Handle Output Data Verification
    always @(posedge clk) begin
        // Check Data on Handshake
        if ((hash_out_valid == 1'b1) && (hash_out_ready == 1'b1)) begin
            // Check Size
            assert (hash_out == hash_out_check) else begin
                $error("hash_out missmatch! packet %d | recieve: %x != check: %x", packet_num, hash_out, hash_out_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("hash_out match! packet %d | recieve: %x == check: %x", packet_num, hash_out, hash_out_check);

            // Check ID
            assert (hash_out_err == hash_out_err_check) else begin
                $error("hash_out_err missmatch! packet %d | recieve: %b != check: %b", packet_num, hash_out_err, hash_out_err_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("hash_out_err match! packet %d | recieve: %b == check: %b", packet_num, hash_out_err, hash_out_err_check);

            // Check Last Flag
            assert (hash_out_last == hash_out_last_check) else begin
                $error("hash_out_last missmatch! packet %d | recieve: %x != check: %x", packet_num, hash_out_last, hash_out_last_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("hash_out_last match! packet %d | recieve: %x == check: %x", packet_num, hash_out_last, hash_out_last_check);

            // Pop new values
            if ((hash_out_queue.size() > 0) && (hash_out_err_queue.size() > 0) && (hash_out_last_queue.size() > 0)) begin
                hash_out_check          <= hash_out_queue.pop_front();
                hash_out_err_check      <= hash_out_err_queue.pop_front();
                hash_out_last_check     <= hash_out_last_queue.pop_front();
                if (hash_out_last_check == 1'b1) begin
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
    
    logic [5:0]   temp_id_in_buf;       // Temporary Input Data Storage
    logic         temp_id_in_buf_last;  // Temporary Input Data Last
    int           temp_id_in_buf_gap;   // Temporary Input Gap
     
    logic [255:0] temp_hash_in;         // Temporary Hash Value 
    logic [5:0]   temp_hash_in_id;      // Temporary Hash ID
    logic         temp_hash_in_last;    // Temporary Hash last;
    int           temp_hash_in_gap;     // Temporary Hash gap;

    logic [255:0] temp_hash_out;        // Temporary Hash Value 
    logic         temp_hash_out_err;    // Temporary Hash Error
    logic         temp_hash_out_last;   // Temporary Hash last;
    int           temp_hash_out_stall;  // Temporary Hash stall;
    
    initial begin
        $dumpfile("sha256_id_validator.vcd");
        $dumpvars(0, tb_sha256_id_validator);
        id_in_buf_drive_en = 0;
        hash_in_drive_en = 0;
        hash_out_drive_ready = 0;
        
        // Read input data into Queuein
        fd = $fopen("../stimulus/testbench/input_validator_id_stim.csv", "r");
        while ($fscanf (fd, "%d,%b,%d", temp_id_in_buf, temp_id_in_buf_last, temp_id_in_buf_gap) == 3) begin
            id_in_buf_queue.push_back(temp_id_in_buf);
            id_in_buf_last_queue.push_back(temp_id_in_buf_last);
            id_in_buf_gap_queue.push_back(temp_id_in_buf_gap);
        end
        $fclose(fd);
        
        // Read input cfg into Queue
        fd = $fopen("../stimulus/testbench/input_hash_in_stim.csv", "r");
        while ($fscanf (fd, "%x,%d,%b,%d", temp_hash_in, temp_hash_in_id, temp_hash_in_last, temp_hash_in_gap) == 4) begin
            hash_in_queue.push_back(temp_hash_in);
            hash_in_id_queue.push_back(temp_hash_in_id);
            hash_in_last_queue.push_back(temp_hash_in_last);
            hash_in_gap_queue.push_back(temp_hash_in_gap);
        end
        $fclose(fd);
        
        // Read output data into Queue
        fd = $fopen("../stimulus/testbench/output_hash_out_ref.csv", "r");
        while ($fscanf (fd, "%x,%b,%b,%d", temp_hash_out, temp_hash_out_err, temp_hash_out_last, temp_hash_out_stall) == 4) begin
            hash_out_queue.push_back(temp_hash_out);
            hash_out_err_queue.push_back(temp_hash_out_err);
            hash_out_last_queue.push_back(temp_hash_out_last);
            hash_out_stall_queue.push_back(temp_hash_out_stall);
        end
        $fclose(fd);
        
        // Initialise First Checking Values
        hash_out_check         = hash_out_queue.pop_front();      
        hash_out_err_check     = hash_out_err_queue.pop_front();      
        hash_out_last_check    = hash_out_last_queue.pop_front();      
        hash_out_stall         = hash_out_stall_queue.pop_front();      
        
        // Defaultly enable Message Builder
        en = 1;
        
        // Defaultly set Sync Reset Low
        sync_rst  = 0;
        
        #20 nrst  = 1;
        #20 nrst  = 0;
        #20 nrst  = 1;
        #20 hash_in_drive_en = 1;
       
        // Write some data into the config register
        # 30 id_in_buf_drive_en = 1;
        
        # 30 hash_out_drive_ready = 1;
    end
    
    initial begin
        forever begin
            #10 clk = 0;
            #10 clk = 1;
        end
    end
    
endmodule