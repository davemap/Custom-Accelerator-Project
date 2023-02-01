//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-2 ID Buffer Testbench
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
`timescale 1ns/1ns
`include "sha256_id_buf.sv"

module tb_sha256_id_buf;
    
    logic clk;
    logic nrst;
    logic en;
    logic sync_rst;
    
    // ID Buffer IN
    logic [5:0] id_in;
    logic id_in_last;
    logic id_in_valid;
    logic id_in_ready;

    // ID Out
    logic [5:0] id_out;
    logic id_out_last;
    logic id_out_valid;
    logic id_out_ready;

    // Status Out - Gets updated after every hash
    logic [5:0] status_id;

        
    sha256_id_buf uut (
            .clk               (clk),
            .nrst              (nrst),
            .en                (en),
            .sync_rst          (sync_rst),
            
            // ID IN
            .id_in         (id_in),
            .id_in_last    (id_in_last),
            .id_in_valid   (id_in_valid),
            .id_in_ready   (id_in_ready),

            // ID Out
            .id_out          (id_out),
            .id_out_last     (id_out_last),
            .id_out_valid    (id_out_valid),
            .id_out_ready    (id_out_ready),

            // Status Out - Gets updated on every output Handshake
            .status_id       (status_id)
        );
    
    logic id_in_drive_en;

    logic id_out_drive_ready;
    
    logic [5:0]  id_in_queue      [$];
    logic        id_in_last_queue [$];
    int          id_in_gap_queue  [$];
    logic        id_in_wait_queue;

    logic [5:0] id_out_queue        [$];
    logic [5:0] status_id_out_queue [$];
    logic       id_out_last_queue   [$];
    int         id_out_stall_queue  [$];
    logic       id_out_wait_queue;

    // TODO: Handle Status Checking
     
    // Handle Valid and Data for id_in
    always_ff @(posedge clk, negedge nrst) begin: id_in_valid_drive
        if (!nrst) begin
            id_in                 <=   6'd0;
            id_in_valid           <=   1'b0;
            id_in_last            <=   1'b0;
            id_in_gap             <=   0;
            id_in_wait_queue      <=   1'b1;
        end else if (id_in_drive_en) begin
            if (id_in_gap > 1) begin
                id_in_gap <= id_in_gap - 1;
                id_in_valid <= 1'b0;
            end else begin
                id_in_valid <= 1'b1;
            end
            if (((id_in_valid == 1'b1) && (id_in_ready == 1'b1)) ||
                 (id_in_wait_queue == 1'b1)) begin
                // Data transfer just completed or transfers already up to date
                if ((id_in_queue.size() > 0) && (id_in_last_queue.size() > 0) && (id_in_gap_queue.size() > 0)) begin
                    id_in            <= id_in_queue.pop_front();
                    id_in_last       <= id_in_last_queue.pop_front();
                    if (id_in_gap_queue[0] == 0) begin
                        id_in_valid  <= 1'b1;
                    end else begin
                        id_in_valid  <= 1'b0;
                    end
                    id_in_gap        <= id_in_gap_queue.pop_front();
                    id_in_wait_queue <= 1'b0;
                end else begin
                    // No data currently avaiable in queue to write but transfers up to date
                    id_in_wait_queue <= 1'b1;
                    id_in_valid      <= 1'b0;
                end
            end
        end
    end
    
    logic [5:0] id_out_check;
    logic [5:0] status_id_out_check;
    logic       id_out_last_check;

    int id_in_gap;
    int id_out_stall;
    
    int packet_num;
    
    // Handle Output Ready Signal Verification
    always @(posedge clk) begin
        // Check Override Control on Ready
        if (id_out_drive_ready) begin
            // Count down to zero before enabling Ready
            if (id_out_stall > 1) begin
                id_out_stall <= id_out_stall - 1;
                id_out_ready <= 1'b0;
            end else begin
                // Wait for handshake before updating stall value
                if ((id_out_valid == 1'b1) && (id_out_ready == 1'b1)) begin
                    if (id_out_stall_queue.size() > 0) begin
                        if (id_out_stall_queue[0] == 0) begin
                            id_out_ready <= 1'b1;
                        end else begin
                            id_out_ready <= 1'b0;
                        end
                        id_out_stall <= id_out_stall_queue.pop_front();
                    end
                // Keep Ready Asserted until handshake seen
                end else begin
                    id_out_ready <= 1'b1;
                end
            end
        end else begin
            id_out_ready <= 1'b0;
        end
    end
    
    // Handle Output Data Verification
    always @(posedge clk) begin
        // Check Data on Handshake
        if ((id_out_valid == 1'b1) && (id_out_ready == 1'b1)) begin
            // Check Size
            assert (id_out == id_out_check) else begin
                $error("id_out missmatch! packet %d | recieve: %x != check: %x", packet_num, id_out, id_out_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("id_out match! packet %d | recieve: %x == check: %x", packet_num, id_out, id_out_check);

            // Check Last Flag
            assert (id_out_last == id_out_last_check) else begin
                $error("id_out_last missmatch! packet %d | recieve: %x != check: %x", packet_num, id_out_last, id_out_last_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("id_out_last match! packet %d | recieve: %x == check: %x", packet_num, id_out_last, id_out_last_check);

            // Check Status Value
            assert (status_id == status_id_out_check) else begin
                $error("id_out_last missmatch! packet %d | recieve: %x != check: %x", packet_num, status_id, status_id_out_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("status_id match! packet %d | recieve: %x == check: %x", packet_num, status_id, status_id_out_check);

            // Pop new values
            if ((id_out_queue.size() > 0) && (status_id_out_queue.size() > 0) && (id_out_last_queue.size() > 0)) begin
                id_out_check          <= id_out_queue.pop_front();
                status_id_out_check   <= status_id_out_queue.pop_front();
                id_out_last_check     <= id_out_last_queue.pop_front();
                if (id_out_last_check == 1'b1) begin
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
    
    logic [5:0]   temp_id_in;       // Temporary Input Data Storage
    logic         temp_id_in_last;  // Temporary Input Data Last
    int           temp_id_in_gap;   // Temporary Input Gap

    logic [5:0]   temp_id_out;        // Temporary ID Value 
    logic [5:0]   temp_status_id_out; // Temporary Status ID Value 
    logic         temp_id_out_last;   // Temporary ID last;
    int           temp_id_out_stall;  // Temporary ID stall;
    
    initial begin
        $dumpfile("sha256_id_buf.vcd");
        $dumpvars(0, tb_sha256_id_buf);
        id_in_drive_en = 0;
        id_out_drive_ready = 0;
        
        // Read input data into Queue in
        fd = $fopen("../stimulus/testbench/input_buf_id_stim.csv", "r");
        while ($fscanf (fd, "%d,%b,%d", temp_id_in, temp_id_in_last, temp_id_in_gap) == 3) begin
            id_in_queue.push_back(temp_id_in);
            id_in_last_queue.push_back(temp_id_in_last);
            id_in_gap_queue.push_back(temp_id_in_gap);
        end
        $fclose(fd);
        
        // Read output data into Queue
        fd = $fopen("../stimulus/testbench/output_buf_id_ref.csv", "r");
        while ($fscanf (fd, "%x,%b,%b,%d", temp_id_out, temp_id_out_last, temp_status_id_out, temp_id_out_stall) == 4) begin
            id_out_queue.push_back(temp_id_out);
            id_out_last_queue.push_back(temp_id_out_last);
            status_id_out_queue.push_back(temp_status_id_out);
            id_out_stall_queue.push_back(temp_id_out_stall);
        end
        $fclose(fd);
        
        // Initialise First Checking Values
        id_out_check         = id_out_queue.pop_front();      
        status_id_out_check  = status_id_out_queue.pop_front();      
        id_out_last_check    = id_out_last_queue.pop_front();      
        id_out_stall         = id_out_stall_queue.pop_front();      
        
        // Defaultly enable Message Builder
        en = 1;
        
        // Defaultly set Sync Reset Low
        sync_rst  = 0;
        
        #20 nrst  = 1;
        #20 nrst  = 0;
        #20 nrst  = 1;
       
        // Write some data into the config register
        # 30 id_in_drive_en = 1;
        
        # 30 id_out_drive_ready = 1;
    end
    
    initial begin
        forever begin
            #10 clk = 0;
            #10 clk = 1;
        end
    end
    
endmodule