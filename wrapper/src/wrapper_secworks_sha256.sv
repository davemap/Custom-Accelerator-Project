//-----------------------------------------------------------------------------
// SoC Labs Basic Example Accelerator Wrapper
// A joint work commissioned on behalf of SoC Labs; under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright 2023; SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------

module wrapper_secworks_sha256 #(
  parameter AHBADDRWIDTH=12,
  parameter INPACKETWIDTH=512,
  parameter CFGSIZEWIDTH=64,
  parameter CFGSCHEMEWIDTH=2,
  parameter OUTPACKETWIDTH=256
  ) (
    input  logic                  HCLK,       // Clock
    input  logic                  HRESETn,    // Reset

    // AHB connection to Initiator
    input  logic                     HSELS,
    input  logic  [AHBADDRWIDTH-1:0] HADDRS,
    input  logic  [1:0]              HTRANSS,
    input  logic  [2:0]              HSIZES,
    input  logic                     HWRITES,
    input  logic                     HREADYS,
    input  logic  [31:0]             HWDATAS,

    output logic                     HREADYOUTS,
    output logic                     HRESPS,
    output logic  [31:0]             HRDATAS,

    //TODO: Add APB Interface

    // Input Data Request Signal to DMAC
    output logic                  in_data_req,

    // Output Data Request Signal to DMAC
    output logic                  out_data_req
  );
  

  //**********************************************************
  // Internal AHB Parameters
  //**********************************************************

  // Input Port Parameters
  localparam [AHBADDRWIDTH-1:0] INPORTADDR         = 'h000;
  localparam                    INPORTAHBADDRWIDTH = AHBADDRWIDTH - 1;

  // Output Port Parameters
  localparam [AHBADDRWIDTH-1:0] OUTPORTADDR         = 'h800;
  localparam                    OUTPORTAHBADDRWIDTH = AHBADDRWIDTH - 1;

  localparam OUTPACKETBYTEWIDTH  = $clog2(OUTPACKETWIDTH/8);            // Number of Bytes in Packet
  localparam OUTPACKETSPACEWIDTH = OUTPORTAHBADDRWIDTH-OUTPACKETBYTEWIDTH; // Number of Bits to represent all Packets in Address Space
  
  //**********************************************************
  // Wrapper AHB Components
  //**********************************************************

  //----------------------------------------------------------
  // Internal AHB Decode Logic
  //----------------------------------------------------------

  // AHB Target 0 - Engine Input Port
  logic             hsel0;
  logic             hreadyout0;
  logic             hresp0;
  logic [31:0]      hrdata0;

  // AHB Target 1 - Engine Output Port
  logic             hsel1;
  logic             hreadyout1;
  logic             hresp1;
  logic [31:0]      hrdata1;

  // AHB Target 2 - Default Target
  logic             hsel2;
  logic             hreadyout2;
  logic             hresp2;
  logic [31:0]      hrdata2;

  // Internal AHB Address Assignment
  assign hsel0 = ((HADDRS < OUTPORTADDR) && (HADDRS >= INPORTADDR)) ? 1'b1:1'b0; // Input Port Select
  assign hsel1 = (HADDRS >= OUTPORTADDR) ? 1'b1:1'b0;                            // Output Port Select
  assign hsel2 = (hsel0 | hsel1) ? 1'b0:1'b1;                                    // Default Target Select

  // AHB Target Multiplexer
  cmsdk_ahb_slave_mux  #(
    1, //PORT0_ENABLE
    1, //PORT1_ENABLE
    1, //PORT2_ENABLE
    0, //PORT3_ENABLE
    0, //PORT4_ENABLE
    0, //PORT5_ENABLE
    0, //PORT6_ENABLE
    0, //PORT7_ENABLE
    0, //PORT8_ENABLE
    0  //PORT9_ENABLE  
  ) u_ahb_slave_mux (
    .HCLK        (HCLK),
    .HRESETn     (HRESETn),
    .HREADY      (HREADYS),
    .HSEL0       (hsel0),     // Input Port 0
    .HREADYOUT0  (hreadyout0),
    .HRESP0      (hresp0),
    .HRDATA0     (hrdata0),
    .HSEL1       (hsel1),     // Input Port 1
    .HREADYOUT1  (hreadyout1),
    .HRESP1      (hresp1),
    .HRDATA1     (hrdata1),
    .HSEL2       (hsel2),     // Input Port 2
    .HREADYOUT2  (hreadyout2),
    .HRESP2      (hresp2),
    .HRDATA2     (hrdata2),
    .HSEL3       (1'b0),      // Input Port 3
    .HREADYOUT3  (),
    .HRESP3      (),
    .HRDATA3     (),
    .HSEL4       (1'b0),      // Input Port 4
    .HREADYOUT4  (),
    .HRESP4      (),
    .HRDATA4     (),
    .HSEL5       (1'b0),      // Input Port 5
    .HREADYOUT5  (),
    .HRESP5      (),
    .HRDATA5     (),
    .HSEL6       (1'b0),      // Input Port 6
    .HREADYOUT6  (),
    .HRESP6      (),
    .HRDATA6     (),
    .HSEL7       (1'b0),      // Input Port 7
    .HREADYOUT7  (),
    .HRESP7      (),
    .HRDATA7     (),
    .HSEL8       (1'b0),      // Input Port 8
    .HREADYOUT8  (),
    .HRESP8      (),
    .HRDATA8     (),
    .HSEL9       (1'b0),      // Input Port 9
    .HREADYOUT9  (),
    .HRESP9      (),
    .HRDATA9     (),
  
    .HREADYOUT   (HREADYOUTS),     // Outputs
    .HRESP       (HRESPS),
    .HRDATA      (HRDATAS)
  );

  //----------------------------------------------------------
  // Input Port Logic
  //----------------------------------------------------------

  // Engine Input Port Wire declarations
  logic [INPACKETWIDTH-1:0]       in_packet;    
  logic                           in_packet_last; 
  logic                           in_packet_valid;
  logic                           in_packet_ready;

  // Packet Constructor Instantiation
  wrapper_ahb_packet_constructor #(
    INPORTAHBADDRWIDTH,
    INPACKETWIDTH
  ) u_wrapper_data_input_port (
    .hclk         (HCLK),
    .hresetn      (HRESETn),

    // Input slave port: 32 bit data bus interface
    .hsels        (hsel0),
    .haddrs       (HADDRS[AHBADDRWIDTH-2:0]),
    .htranss      (HTRANSS),
    .hsizes       (HSIZES),
    .hwrites      (HWRITES),
    .hreadys      (HREADYS),
    .hwdatas      (HWDATAS),

    .hreadyouts   (hreadyout0),
    .hresps       (hresp0),
    .hrdatas      (hrdata0),

    // Valid/Ready Interface
    .packet_data       (in_packet),
    .packet_data_last  (in_packet_last),
    .packet_data_valid (in_packet_valid),
    .packet_data_ready (in_packet_ready),

    // Input Data Request
    .data_req          (in_data_req)
  );

  //----------------------------------------------------------
  // Configuration Port Logic
  //----------------------------------------------------------

  // Engine Configuration Port Wire declarations
  logic [CFGSIZEWIDTH-1:0]        cfg_size;
  logic [CFGSCHEMEWIDTH-1:0]      cfg_scheme;
  logic                           cfg_last;
  logic                           cfg_valid;
  logic                           cfg_ready;

  // Engine Configuration Port Tied-off to fixed values
  assign cfg_size   = 64'd512;
  assign cfg_scheme = 2'd0;
  assign cfg_last   = 1'b1;
  assign cfg_valid  = 1'b1;

  //----------------------------------------------------------
  // Output Port Logic
  //----------------------------------------------------------

  // Engine Output Port Wire declarations
  logic [OUTPACKETWIDTH-1:0]      out_hash;    
  logic                           out_hash_last; 
  logic [OUTPACKETSPACEWIDTH-1:0] out_hash_remain;    
  logic                           out_hash_valid;
  logic                           out_hash_ready;
  

  // Relative Read Address for Start of Current Block  
  logic [OUTPORTAHBADDRWIDTH-1:0]    block_read_addr;



  // Packet Deconstructor Instantiation
  wrapper_ahb_packet_deconstructor #(
    OUTPORTAHBADDRWIDTH,
    OUTPACKETWIDTH
  ) u_wrapper_data_output_port (
    .hclk         (HCLK),
    .hresetn      (HRESETn),

    // Input slave port: 32 bit data bus interface
    .hsels        (hsel1),
    .haddrs       (HADDRS[AHBADDRWIDTH-2:0]),
    .htranss      (HTRANSS),
    .hsizes       (HSIZES),
    .hwrites      (HWRITES),
    .hreadys      (HREADYS),
    .hwdatas      (HWDATAS),

    .hreadyouts   (hreadyout1),
    .hresps       (hresp1),
    .hrdatas      (hrdata1),

    // Valid/Ready Interface
    .packet_data        (out_hash),
    .packet_data_last   (out_hash_last),
    .packet_data_remain (out_hash_remain),
    .packet_data_valid  (out_hash_valid),
    .packet_data_ready  (out_hash_ready),

    // Input Data Request
    .data_req          (out_data_req),

    // Read Address Interface
   .block_read_addr           (block_read_addr)
  );

  //----------------------------------------------------------
  // Default AHB Target Logic
  //----------------------------------------------------------

  // AHB Default Target Instantiation
  cmsdk_ahb_default_slave  u_ahb_default_slave(
    .HCLK         (HCLK),
    .HRESETn      (HRESETn),
    .HSEL         (hsel2),
    .HTRANS       (HTRANSS),
    .HREADY       (HREADYS),
    .HREADYOUT    (hreadyout2),
    .HRESP        (hresp2)
  );

  // Default Targets Data is tied off
  assign hrdata2 = {32{1'b0}};

  //**********************************************************
  // Wrapper APB Components
  //**********************************************************

  // TODO: Instantiate APB Mux

  // TODO: Instantiate APB Default Target

  // TODO: Wrapper Register Blocks

  //**********************************************************
  // Wrapper Interrupt Generation
  //**********************************************************

  // TODO: Instantiate IRQ Generator

  //**********************************************************
  // Wrapper DMA Data Request Generation
  //**********************************************************

  // TODO: Write up data request logic through registers

  //**********************************************************
  // Accelerator Engine
  //**********************************************************

  //----------------------------------------------------------
  // Accelerator Engine Logic
  //----------------------------------------------------------

  logic out_digest_valid;

  // Engine Output Port Wire declarations
  logic [OUTPACKETWIDTH-1:0]      out_packet;    
  logic                           out_packet_last; 
  logic [OUTPACKETSPACEWIDTH-1:0] out_packet_remain;    
  logic                           out_packet_valid;
  logic                           out_packet_ready;

    // Block Packets Remaining Tie-off (only ever one packet per block)
  assign out_packet_remain = {OUTPACKETSPACEWIDTH{1'b0}};

  // Hashing Accelerator Instatiation
  wrapper_digest_filter u_digest_filter (
        .clk            (HCLK),
        .rst            (~HRESETn),

        // Data in Channel
        .s_tvalid_i     (in_packet_valid),
        .s_tready_o     (in_packet_ready),
        .s_tlast_i      (in_packet_last),

        // Data Out Channel
        .digest_valid_o (out_digest_valid),
        .hash_valid_o   (out_packet_valid)
    );


  // Hashing Accelerator Instatiation
  sha256_stream u_sha256_stream (
        .clk            (HCLK),
        .rst            (~HRESETn),
        .mode           (1'b1),

        // Data in Channel
        .s_tdata_i      (in_packet),
        .s_tvalid_i     (in_packet_valid),
        .s_tready_o     (in_packet_ready),
        .s_tlast_i      (in_packet_last),

        // Data Out Channel
        .digest_o       (out_packet),
        .digest_valid_o (out_digest_valid)
    );
  
  assign out_packet_last  = 1'b1;

  // Output FIFO (Output has no handshaking)
  fifo_vr #(
    4,
    256
  ) u_output_fifo (
    .clk  (HCLK),
    .nrst (HRESETn),
    .en   (1'b1),
    .sync_rst (1'b0),
    .data_in       (out_packet),
    .data_in_last  (out_packet_last),
    .data_in_valid  (out_packet_valid),
    .data_in_ready  (),
    .data_out       (out_hash),
    .data_out_valid (out_hash_valid),
    .data_out_ready (out_hash_ready),
    .data_out_last  (out_hash_last),
    .status_ptr_dif ()
  );
endmodule