//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-2 ID Issuer Testbench
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
`timescale 1ns/1ns
`include "sha256_id_issue.sv"

module tb_sha256_id_issue;
    
    logic clk;
    logic nrst;
    logic en;
    logic sync_rst;
    
    // Data Out - ID Out
    logic [5:0] id_out;
    logic id_out_last;
    
    // Concatenator Handshake
    logic id_out_cfg_valid;
     logic id_out_cfg_ready;
    
    // ID Buffer Handshake
    logic id_out_buf_valid;
    logic id_out_buf_ready;
        
    sha256_id_issue uut (
                  .clk               (clk),
                  .nrst              (nrst),
                  .en                (en),
                  .sync_rst          (sync_rst),
                  .id_out            (id_out),
                  .id_out_last       (id_out_last),
                  .id_out_cfg_valid  (id_out_cfg_valid),
                  .id_out_cfg_ready  (id_out_cfg_ready),
                  .id_out_buf_valid  (id_out_buf_valid),
                  .id_out_buf_ready  (id_out_buf_ready)
                );
    
    logic id_out_cfg_drive_ready;
    logic id_out_buf_drive_ready;
    
    logic [511:0] id_out_cfg_queue [$];
    logic id_out_cfg_last_queue    [$];
    int   id_out_cfg_stall_queue   [$];
    logic id_out_cfg_wait_queue;
    
    logic [511:0] id_out_buf_queue [$];
    logic id_out_buf_last_queue    [$];
    int   id_out_buf_stall_queue   [$];
    logic id_out_buf_wait_queue;
    
    logic [5:0] id_out_cfg_check, id_out_buf_check;
    logic id_out_cfg_last_check, id_out_buf_last_check;
    int   id_out_cfg_stall, id_out_buf_stall;
    
    int   packet_num_cfg, packet_num_buf ;
    
    // Handle Cfg Output Ready Signal Verification
    always @(posedge clk) begin
        // Check Override Control on Ready
        if (id_out_cfg_drive_ready) begin
            // Count down to zero before enabling Ready
            if (id_out_cfg_stall > 1) begin
                id_out_cfg_stall <= id_out_cfg_stall - 1;
                id_out_cfg_ready <= 1'b0;
            end else begin
                // Wait for handshake before updating stall value
                if ((id_out_cfg_valid == 1'b1) && (id_out_cfg_ready == 1'b1)) begin
                    if (id_out_cfg_stall_queue.size() > 0) begin
                        if (id_out_cfg_stall_queue[0] == 0) begin
                            id_out_cfg_ready <= 1'b1;
                        end else begin
                            id_out_cfg_ready <= 1'b0;
                        end
                        id_out_cfg_stall <= id_out_cfg_stall_queue.pop_front();
                    end
                // Keep Ready Asserted until handshake seen
                end else begin
                    id_out_cfg_ready <= 1'b1;
                end
            end
        end else begin
            id_out_cfg_ready <= 1'b0;
        end
    end
    
    // Handle Output Cfg Data Verification
    always @(posedge clk) begin
        // Check Data on Handshake
        if ((id_out_cfg_valid == 1'b1) && (id_out_cfg_ready == 1'b1)) begin
            assert (id_out == id_out_cfg_check) else begin
                $error("id_out_cfg missmatch! packet %d | recieve: %d != check: %d", packet_num_cfg, id_out, id_out_cfg_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("id_out_cfg match! packet %d | recieve: %d == check: %d", packet_num_cfg, id_out, id_out_cfg_check);
            assert (id_out_last == id_out_cfg_last_check) else begin
                $error("id_out_cfg_last missmatch! packet %d | recieve: %d != check: %d", packet_num_cfg, id_out_last, id_out_cfg_last_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("id_out_cfg_last match! packet %d | recieve: %d != check: %d", packet_num_cfg, id_out_last, id_out_cfg_last_check);
            if ((id_out_cfg_queue.size() > 0) && (id_out_cfg_last_queue.size() > 0)) begin
                id_out_cfg_check      <= id_out_cfg_queue.pop_front();
                id_out_cfg_last_check <= id_out_cfg_last_queue.pop_front();
                if (id_out_cfg_last_check == 1'b1) begin
                    packet_num_cfg <= packet_num_cfg + 1;
                end
            end else begin
                $display("Test Passes");
                $finish;
            end
        end
    end
    
    // Handle buf Output Ready Signal Verification
    always @(posedge clk) begin
        // Check Override Control on Ready
        if (id_out_buf_drive_ready) begin
            // Count down to zero before enabling Ready
            if (id_out_buf_stall > 1) begin // Want to apply ready of the next clock cycle (stall will be 0 when ready is high)
                id_out_buf_stall <= id_out_buf_stall - 1;
                id_out_buf_ready <= 1'b0;
            end else begin
                // Wait for handshake before updating stall value
                if ((id_out_buf_valid == 1'b1) && (id_out_buf_ready == 1'b1)) begin
                    if (id_out_buf_stall_queue.size() > 0) begin
                        if (id_out_buf_stall_queue[0] == 0) begin
                            id_out_buf_ready <= 1'b1;
                        end else begin
                            id_out_buf_ready <= 1'b0;
                        end
                        id_out_buf_stall <= id_out_buf_stall_queue.pop_front();
                    end
                // Keep Ready Asserted until handshake seen
                end else begin
                    id_out_buf_ready <= 1'b1;
                end
            end
        end else begin
            id_out_buf_ready <= 1'b0;
        end
    end
    
    // Handle Output buf Data Verification
    always @(posedge clk) begin
        // Check Data on Handshake
        if ((id_out_buf_valid == 1'b1) && (id_out_buf_ready == 1'b1)) begin
            assert (id_out == id_out_buf_check) else begin
                $error("id_out_buf missmatch! packet %d | recieve: %d != check: %d", packet_num_buf, id_out, id_out_buf_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("id_out_buf match! packet %d | recieve: %d == check: %d", packet_num_buf, id_out, id_out_buf_check);
            assert (id_out_last == id_out_buf_last_check) else begin
                $error("id_out_buf_last missmatch! packet %d | recieve: %d != check: %d", packet_num_buf, id_out_last, id_out_buf_last_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("id_out_buf_last match! packet %d | recieve: %d == check: %d", packet_num_buf, id_out_last, id_out_buf_last_check);
            if ((id_out_buf_queue.size() > 0) && (id_out_buf_last_queue.size() > 0)) begin
                id_out_buf_check      <= id_out_buf_queue.pop_front();
                id_out_buf_last_check <= id_out_buf_last_queue.pop_front();
                if (id_out_buf_last_check == 1'b1) begin
                    packet_num_buf <= packet_num_buf + 1;
                end
            end else begin
                $display("Test Passes");
                $finish;
            end
        end
    end
    
    // File Reading Variables
    int fd; // File descriptor Handle
    
    logic [5:0] id_cfg_data; // Temporary Output Cfg Data Storage
    logic id_cfg_last;    // Temporary Output Cfg Data Last
    int   id_cfg_stall;    // Temporary Output Cfg Stall 
    
    logic [5:0] id_buf_data; // Temporary Output buf Data Storage
    logic id_buf_last;    // Temporary Output buf Data Last
    int   id_buf_stall;    // Temporary Output buf Stall 
    
    initial begin
        $dumpfile("sha256_id_issue.vcd");
        $dumpvars(0, tb_sha256_id_issue);
        id_out_cfg_drive_ready = 0;
        id_out_buf_drive_ready = 0;
        
        // Read output cfg data into Queue
        fd = $fopen("../stimulus/testbench/output_id_ref.csv", "r");
        while ($fscanf (fd, "%d,%b,%d", id_cfg_data, id_cfg_last, id_cfg_stall) == 3) begin
            id_out_cfg_queue.push_back(id_cfg_data);
            id_out_cfg_last_queue.push_back(id_cfg_last);
            id_out_cfg_stall_queue.push_back(id_cfg_stall);
        end
        $fclose(fd);
        
        // Read output buf data into Queue
        fd = $fopen("../stimulus/testbench/output_id_ref.csv", "r");
        while ($fscanf (fd, "%d,%b,%d", id_buf_data, id_buf_last, id_buf_stall) == 3) begin
            id_out_buf_queue.push_back(id_buf_data);
            id_out_buf_last_queue.push_back(id_buf_last);
            id_out_buf_stall_queue.push_back(id_buf_stall);
        end
        $fclose(fd);
        
        // Initialise First Checking Values
        id_out_cfg_check      = id_out_cfg_queue.pop_front();      
        id_out_cfg_last_check = id_out_cfg_last_queue.pop_front();
        id_out_cfg_stall      = id_out_cfg_stall_queue.pop_front();
        id_out_buf_check      = id_out_buf_queue.pop_front();      
        id_out_buf_last_check = id_out_buf_last_queue.pop_front();
        id_out_buf_stall      = id_out_buf_stall_queue.pop_front();
        
        // Defaultly enable Message Builder
        en = 1;
        
        // Defaultly set Sync Reset Low
        sync_rst  = 0;
        
        #20 nrst  = 1;
        #20 nrst  = 0;
        #20 nrst  = 1;
        id_out_cfg_drive_ready = 1;
        id_out_buf_drive_ready = 1;
    end
    
    initial begin
        forever begin
            #10 clk = 0;
            #10 clk = 1;
        end
    end
    
endmodule