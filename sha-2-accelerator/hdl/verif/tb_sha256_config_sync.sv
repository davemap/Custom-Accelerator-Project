//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-2 Config Synchroniser Testbench
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
`timescale 1ns/1ns
`include "sha256_config_sync.sv"

module tb_sha256_config_sync;
    
    logic clk;
    logic nrst;
    logic en;
    logic sync_rst;
    // Data In data and Handshaking
    logic [5:0] id_in;
    logic       id_in_last;
    logic       id_in_valid;
    logic       id_in_ready;
    
    // Config data and Handshaking
    logic [63:0] cfg_in_size;
    logic [1:0]  cfg_in_scheme;
    logic        cfg_in_last;
    logic        cfg_in_valid;
    logic        cfg_in_ready;
    
    // Data Out data and Handshaking
    logic [63:0] cfg_out_size;
    logic [1:0]  cfg_out_scheme;
    logic [5:0]  cfg_out_id;
    logic        cfg_out_last;
    logic        cfg_out_valid;
    logic        cfg_out_ready;

        
    sha256_config_sync uut (
                  .clk             (clk),
                  .nrst            (nrst),
                  .en              (en),
                  .sync_rst        (sync_rst),
                  .id_in           (id_in),
                  .id_in_last      (id_in_last),
                  .id_in_valid     (id_in_valid),
                  .id_in_ready     (id_in_ready),
                  .cfg_in_size     (cfg_in_size),
                  .cfg_in_scheme   (cfg_in_scheme),
                  .cfg_in_last     (cfg_in_last),
                  .cfg_in_valid    (cfg_in_valid),
                  .cfg_in_ready    (cfg_in_ready),
                  .cfg_out_size    (cfg_out_size),
                  .cfg_out_scheme  (cfg_out_scheme),
                  .cfg_out_id      (cfg_out_id),
                  .cfg_out_last    (cfg_out_last),
                  .cfg_out_valid   (cfg_out_valid),
                  .cfg_out_ready   (cfg_out_ready));
    
    logic id_in_drive_en;
    logic cfg_in_drive_en;
    logic cfg_out_drive_ready;
    
    logic [5:0]  id_in_queue      [$];
    logic        id_in_last_queue [$];
    int          id_in_gap_queue  [$];
    logic        id_in_wait_queue;
    
    logic [63:0] cfg_in_size_queue   [$];
    logic [1:0]  cfg_in_scheme_queue [$];
    logic        cfg_in_last_queue   [$];
    int          cfg_in_gap_queue    [$];
    logic        cfg_in_wait_queue;

    logic [63:0] cfg_out_size_queue   [$];
    logic [1:0]  cfg_out_scheme_queue [$];
    logic [5:0]  cfg_out_id_queue     [$];
    logic        cfg_out_last_queue   [$];
    int          cfg_out_stall_queue  [$];
    logic        cfg_out_wait_queue;
    
    // Handle Valid and Data for id_in
    always_ff @(posedge clk, negedge nrst) begin: id_in_valid_drive
        if (!nrst) begin
            id_in                 <= 512'd0;
            id_in_valid           <=   1'b0;
            id_in_last            <=   1'b0;
            id_in_gap             <=   0;
            id_in_wait_queue      <=   1'b1;
        end else if (id_in_drive_en) begin
            if (id_in_gap > 1) begin
                id_in_gap <= id_in_gap -1;
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

    // Handle Valid and Data for cfg_in
    always_ff @(posedge clk, negedge nrst) begin: cfg_in_valid_drive
        if (!nrst) begin
            cfg_in_size            <=  64'd0;
            cfg_in_scheme          <=   2'd0;
            cfg_in_valid           <=   1'b0;
            cfg_in_last            <=   1'b0;
            cfg_in_gap              <=   0;
            cfg_in_wait_queue      <=   1'b1;
        end else if (cfg_in_drive_en) begin
            if (cfg_in_gap > 1) begin
                cfg_in_gap <= cfg_in_gap -1;
                cfg_in_valid <= 1'b0;
            end else begin
                cfg_in_valid <= 1'b1;
            end
            if (((cfg_in_valid == 1'b1) && (cfg_in_ready == 1'b1)) ||
                 (cfg_in_wait_queue == 1'b1)) begin
                // cfg_in transfer just completed or transfers already up to date
                if ((cfg_in_size_queue.size() > 0) && (cfg_in_scheme_queue.size() > 0 ) && (cfg_in_last_queue.size() > 0) && (cfg_in_gap_queue.size() > 0)) begin
                    cfg_in_size       <= cfg_in_size_queue.pop_front();
                    cfg_in_scheme     <= cfg_in_scheme_queue.pop_front();
                    cfg_in_last       <= cfg_in_last_queue.pop_front();
                    if (cfg_in_gap_queue[0] == 0) begin
                        cfg_in_valid  <= 1'b1;
                    end else begin
                        cfg_in_valid  <= 1'b0;
                    end
                    cfg_in_gap        <= cfg_in_gap_queue.pop_front();
                    cfg_in_wait_queue <= 1'b0;
                end else begin
                    // No data currently avaiable in queue to write but transfers up to date
                    cfg_in_wait_queue <= 1'b1;
                    cfg_in_valid      <= 1'b0;
                end
            end
        end
    end
    
    logic [63:0] cfg_out_size_check;
    logic [1:0]  cfg_out_scheme_check;
    logic [5:0]  cfg_out_id_check;  
    logic        cfg_out_last_check;

    int          id_in_gap;
    int          cfg_in_gap;
    int          cfg_out_stall;
    
    int   packet_num;
    
    // Handle Output Ready Signal Verification
    always @(posedge clk) begin
        // Check Override Control on Ready
        if (cfg_out_drive_ready) begin
            // Count down to zero before enabling Ready
            if (cfg_out_stall > 1) begin
                cfg_out_stall <= cfg_out_stall - 1;
                cfg_out_ready <= 1'b0;
            end else begin
                // Wait for handshake before updating stall value
                if ((cfg_out_valid == 1'b1) && (cfg_out_ready == 1'b1)) begin
                    if (cfg_out_stall_queue.size() > 0) begin
                        if (cfg_out_stall_queue[0] == 0) begin
                            cfg_out_ready <= 1'b1;
                        end else begin
                            cfg_out_ready <= 1'b0;
                        end
                        cfg_out_stall <= cfg_out_stall_queue.pop_front();
                    end
                // Keep Ready Asserted until handshake seen
                end else begin
                    cfg_out_ready <= 1'b1;
                end
            end
        end else begin
            cfg_out_ready <= 1'b0;
        end
    end
    
    // Handle Output Data Verification
    always @(posedge clk) begin
        // Check Data on Handshake
        if ((cfg_out_valid == 1'b1) && (cfg_out_ready == 1'b1)) begin
            // Check Size
            assert (cfg_out_size == cfg_out_size_check) else begin
                $error("cfg_out_size missmatch! packet %d | recieve: %x != check: %x", packet_num, cfg_out_size, cfg_out_size_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("cfg_out_size match! packet %d | recieve: %x == check: %x", packet_num, cfg_out_size, cfg_out_size_check);

            // Check Scheme
            assert (cfg_out_scheme == cfg_out_scheme_check) else begin
                $error("cfg_out_scheme missmatch! packet %d | recieve: %x != check: %x", packet_num, cfg_out_scheme, cfg_out_scheme_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("cfg_out_scheme match! packet %d | recieve: %x == check: %x", packet_num, cfg_out_scheme, cfg_out_scheme_check);

            // Check ID
            assert (cfg_out_id == cfg_out_id_check) else begin
                $error("cfg_out_id missmatch! packet %d | recieve: %x != check: %x", packet_num, cfg_out_id, cfg_out_id_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("cfg_out_id match! packet %d | recieve: %x == check: %x", packet_num, cfg_out_id, cfg_out_id_check);

            // Check Last Flag
            assert (cfg_out_last == cfg_out_last_check) else begin
                $error("cfg_out_last missmatch! packet %d | recieve: %x != check: %x", packet_num, cfg_out_last, cfg_out_last_check);
                $finish;
            end
            if ($test$plusargs ("DEBUG")) $display("cfg_out_last match! packet %d | recieve: %x == check: %x", packet_num, cfg_out_last, cfg_out_last_check);

            // Pop new values
            if ((cfg_out_size_queue.size() > 0) && (cfg_out_scheme_queue.size() > 0) && (cfg_out_id_queue.size() > 0) && (cfg_out_last_queue.size() > 0)) begin
                cfg_out_size_check     <= cfg_out_size_queue.pop_front();
                cfg_out_scheme_check   <= cfg_out_scheme_queue.pop_front();
                cfg_out_id_check       <= cfg_out_id_queue.pop_front();
                cfg_out_last_check     <= cfg_out_last_queue.pop_front();
                if (cfg_out_last_check == 1'b1) begin
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
    
    logic [5:0] temp_id_in;         // Temporary Input Data Storage
    logic       temp_id_in_last;    // Temporary Input Data Last
    int         temp_id_in_gap;     // Temporary Input Gap
    
    logic [63:0] temp_cfg_in_size;   // Temporary cfg size 
    logic [1:0]  temp_cfg_in_scheme; // Temporary cfg scheme
    logic        temp_cfg_in_last;   // Temporary cfg last;
    int          temp_cfg_in_gap;    // Temporary cfg gap;

    logic [63:0] temp_cfg_out_size;   // Temporary cfg size 
    logic [1:0]  temp_cfg_out_scheme; // Temporary cfg scheme
    logic [5:0]  temp_cfg_out_id;     // Temporary cfg id
    logic        temp_cfg_out_last;   // Temporary cfg last;
    int          temp_cfg_out_stall;    // Temporary cfg stall;
    
    initial begin
        $dumpfile("sha256_config_sync.vcd");
        $dumpvars(0, tb_sha256_config_sync);
        id_in_drive_en = 0;
        cfg_in_drive_en = 0;
        cfg_out_drive_ready = 0;
        
        // Read input data into Queue
        fd = $fopen("../stimulus/unit/input_id_stim.csv", "r");
        while ($fscanf (fd, "%d,%b,%d", temp_id_in, temp_id_in_last, temp_id_in_gap) == 3) begin
            id_in_queue.push_back(temp_id_in);
            id_in_last_queue.push_back(temp_id_in_last);
            id_in_gap_queue.push_back(temp_id_in_gap);
        end
        $fclose(fd);
        
        // Read input cfg into Queue
        fd = $fopen("../stimulus/unit/input_cfg_stim.csv", "r");
        while ($fscanf (fd, "%x,%x,%b,%d", temp_cfg_in_size, temp_cfg_in_scheme, temp_cfg_in_last, temp_cfg_in_gap) == 4) begin
            cfg_in_size_queue.push_back(temp_cfg_in_size);
            cfg_in_scheme_queue.push_back(temp_cfg_in_scheme);
            cfg_in_last_queue.push_back(temp_cfg_in_last);
            cfg_in_gap_queue.push_back(temp_cfg_in_gap);
        end
        $fclose(fd);
        
        // Read output data into Queue
        fd = $fopen("../stimulus/unit/output_cfg_sync_ref.csv", "r");
        while ($fscanf (fd, "%x,%x,%d,%b,%d", temp_cfg_out_size, temp_cfg_out_scheme, temp_cfg_out_id, temp_cfg_out_last, temp_cfg_out_stall) == 5) begin
            cfg_out_size_queue.push_back(temp_cfg_out_size);
            cfg_out_scheme_queue.push_back(temp_cfg_out_scheme);
            cfg_out_id_queue.push_back(temp_cfg_out_id);
            cfg_out_last_queue.push_back(temp_cfg_out_last);
            cfg_out_stall_queue.push_back(temp_cfg_out_stall);
        end
        $fclose(fd);
        
        // Initialise First Checking Values
        cfg_out_size_check    = cfg_out_size_queue.pop_front();      
        cfg_out_scheme_check  = cfg_out_scheme_queue.pop_front();      
        cfg_out_id_check      = cfg_out_id_queue.pop_front();      
        cfg_out_last_check    = cfg_out_last_queue.pop_front();      
        cfg_out_stall         = cfg_out_stall_queue.pop_front();      
        
        // Defaultly enable Message Builder
        en = 1;
        
        // Defaultly set Sync Reset Low
        sync_rst  = 0;
        
        #20 nrst  = 1;
        #20 nrst  = 0;
        #20 nrst  = 1;
        #20 cfg_in_drive_en = 1;
       
        // Write some data into the config register
        # 30 id_in_drive_en = 1;
        
        # 30 cfg_out_drive_ready = 1;
    end
    
    initial begin
        forever begin
            #10 clk = 0;
            #10 clk = 1;
        end
    end
    
endmodule