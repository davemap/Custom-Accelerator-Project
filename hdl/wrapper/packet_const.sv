module  packet_const #(
  parameter   PACKETWIDTH=512,
  parameter   ADDRWIDTH=11
)(
  input  logic                  hclk,       // clock
  input  logic                  hresetn,    // reset

   //Register interface
  input  logic [ADDRWIDTH-1:0]   addr,
  input  logic                   read_en,
  input  logic                   write_en,
  input  logic [3:0]             byte_strobe,
  input  logic [31:0]            wdata,
  output logic [31:0]            rdata,

  output logic [PACKETWIDTH-1:0] data_out,
  output logic                   data_out_last,
  output logic                   data_out_valid,
  input  logic                   data_out_ready
);

// 4KiB of Address Space for Accelerator (11:0)
// Capture Address to be used for comparision to test for address jumping
logic [ADDRWIDTH-1:0] last_wr_addr;
// Create Construction Buffer
logic [PACKETWIDTH-1:0] const_buffer;
logic const_buffer_last;

logic [ADDRWIDTH-1:0] addr_top_bit;
assign addr_top_bit = (addr[5:2] * 32) - 1;

// Dump data on one of two conditions
// - An address ends [5:0] in 0x3C i.e. [5:2] == 0xF
// - Address Moved to different 512 bit word
// Write Condition
always_ff @(posedge hclk or negedge hresetn) begin
    if (~hresetn) begin
        // Reset Construction Buffer
        const_buffer <= {PACKETWIDTH{1'b0}};
    end else begin
        if (write_en) begin
            // If not (awaiting handshake AND address generates new data payload)
            if (!((data_out_valid && !data_out_ready) && (addr[5:2] == 4'hF))) begin
                // Buffer Address for future Comparison
                last_wr_addr <= addr;

                // If 512 Word Address Changed, Clear Buffer
                if (last_wr_addr[ADDRWIDTH-1:6] != addr [ADDRWIDTH-1:6]) const_buffer <= {PACKETWIDTH{1'b0}};

                // Write Word into Construction Buffer
                const_buffer[addr_top_bit -: 32] <= wdata;
                
                // If last 32 bit word of 512 bit buffer
                if (addr[5:2] == 4'hF) begin
                    // Produce Data Output 
                    data_out <= {wdata,const_buffer[479:0]}; // Top word won't be in const_buffer 
                    // - until next cycle to splice it in to out data combinatorially
                    // Calculate Last Flag
                    data_out_last <= (addr[ADDRWIDTH-1:6] == 5'h1F) ? 1'b1 : 1'b0;
                    // Take Valid High
                    data_out_valid <= 1'b1;
                    // Reset Construction Buffer
                    const_buffer <= 512'd0;
                end
            end else begin
                // TODO: Implement Error Propogation/Waitstates
            end
        end
    end
end

// Read Condition
always_comb begin
    if (read_en) begin
        // Read appropriate 32 bits from buffer
        // 
        rdata = const_buffer[addr_top_bit -: 32];
    end else begin
        rdata = 32'd0;
    end
end


endmodule