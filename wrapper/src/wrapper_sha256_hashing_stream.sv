//-----------------------------------------------------------------------------
// SoC Labs Basic Accelerator Wrapper for Hashing Stream
// A joint work commissioned on behalf of SoC Labs; under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright 2023; SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from Arm Limited or its affiliates.
//
//            (C) COPYRIGHT 2010-2011 Arm Limited or its affiliates.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from Arm Limited or its affiliates.
//
//      SVN Information
//
//      Checked In          : $Date: 2017-10-10 15:55:38 +0100 (Tue, 10 Oct 2017) $
//
//      Revision            : $Revision: 371321 $
//
//      Release Information : Cortex-M System Design Kit-r1p1-00rel0
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Abstract : AHB-lite example slave, support 4 32-bit register read and write,
//            each register can be accessed by byte, half word or word.
//            The example slave always output ready and OKAY response to the master
//-----------------------------------------------------------------------------

module wrapper_sha256_hashing_stream #(
  parameter ADDRWIDTH=12,
  parameter INPACKETWIDTH=512,
  parameter OUTPACKETWIDTH=256
  ) (
    input  logic                  HCLK,       // Clock
    input  logic                  HRESETn,    // Reset

  // AHB connection to Initiator
    input  logic                  HSELS,
    input  logic  [ADDRWIDTH-1:0] HADDRS,
    input  logic  [1:0]           HTRANSS,
    input  logic  [2:0]           HSIZES,
    input  logic                  HWRITES,
    input  logic                  HREADYS,
    input  logic  [31:0]          HWDATAS,

    output logic                  HREADYOUTS,
    output logic                  HRESPS,
    output logic  [31:0]          HRDATAS
  );
  
  // ----------------------------------------
  // Internal wires declarations

  // Register module interface signals
  logic  [ADDRWIDTH-1:0]  in_buf_addr;
  logic                   in_buf_read_en;
  logic                   in_buf_write_en;
  logic  [3:0]            in_buf_byte_strobe;
  logic  [31:0]           in_buf_wdata;
  logic  [31:0]           in_buf_rdata;

  // Input Port Wire Declarations
  logic [ADDRWIDTH-2:0] input_addr;
  logic                 input_read_en;
  logic                 input_write_en;
  logic [3:0]           input_byte_strobe;
  logic [31:0]          input_wdata;
  logic [31:0]          input_rdata;
  logic                 input_wready;
  logic                 input_rready;

  // Output Port Wire Declarations    
  logic [ADDRWIDTH-2:0] output_addr;       
  logic                 output_read_en;    
  logic                 output_write_en;   
  logic [3:0]           output_byte_strobe;
  logic [31:0]          output_wdata;      
  logic [31:0]          output_rdata;      
  logic                 output_wready;     
  logic                 output_rready;     

  // Internal Wiring
  // Input Packet Wires
  logic [511:0] in_packet;    
  logic         in_packet_last; 
  logic         in_packet_valid;
  logic         in_packet_ready;

  // Input Data Request
  logic         in_data_req;

  // Output Packet Wires
  logic [255:0] out_packet;    
  logic         out_packet_last; 
  logic         out_packet_valid;
  logic         out_packet_ready;

  // Configuration Tie Off
  logic [63:0] cfg_size;
  logic [1:0]  cfg_scheme;
  logic cfg_last;
  logic cfg_valid;
  logic cfg_ready;

  assign cfg_size   = 64'd512;
  assign cfg_scheme = 2'd0;
  assign cfg_last   = 1'b1;
  assign cfg_valid  = 1'b1;

  // Engine Input AHB Signals
  logic             hsel0;
  logic             hreadyout0;
  logic             hresp0;
  logic [31:0]      hrdata0;

  // Engine Output AHB Signals
  logic             hsel1;
  logic             hreadyout1;
  logic             hresp1;
  logic [31:0]      hrdata1;

  // Default Target AHB Signals
  logic             hsel2;
  logic             hreadyout2;
  logic             hresp2;
  logic [31:0]      hrdata2;

  // Address Decoder
  assign hsel0 = (~HADDRS[ADDRWIDTH-1]) ? 1'b1:1'b0; // Input Port Select
  assign hsel1 = (HADDRS[ADDRWIDTH-1])  ? 1'b1:1'b0; // Output Port Select
  assign hsel2 = (hsel0 | hsel1)        ? 1'b0:1'b1; // Default Target Select

  //-----------------------------------------------------------
  // Module logic start
  //----------------------------------------------------------
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

  //----------------------------
  // Input Port
  //----------------------------
  wrapper_ahb_packet_constructor #(
    ADDRWIDTH-1,
    INPACKETWIDTH
  ) u_wrapper_data_input_port (
    .hclk         (HCLK),
    .hresetn      (HRESETn),

    // Input slave port: 32 bit data bus interface
    .hsels        (hsel0),
    .haddrs       (HADDRS[ADDRWIDTH-2:0]),
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



  //----------------------------
  // Output Port
  //----------------------------
  // Interface block to convert AHB transfers to Register transfers to engine input/output channels
  // engine Input/Output Channels
  wrapper_ahb_vr_interface #(
    ADDRWIDTH
   ) u_wrapper_ahb_interface (
    .hclk         (HCLK),
    .hresetn      (HRESETn),

    // Input slave port: 32 bit data bus interface
    .hsels        (hsel1),
    .haddrs       (HADDRS),
    .htranss      (HTRANSS),
    .hsizes       (HSIZES),
    .hwrites      (HWRITES),
    .hreadys      (HREADYS),
    .hwdatas      (HWDATAS),

    .hreadyouts   (hreadyout1),
    .hresps       (hresp1),
    .hrdatas      (hrdata1),

    // Register interface - Accelerator Engine Input
    .input_addr        (input_addr),
    .input_read_en     (input_read_en),
    .input_write_en    (input_write_en),
    .input_byte_strobe (input_byte_strobe),
    .input_wdata       (input_wdata),
    .input_rdata       (input_rdata),
    .input_wready      (input_wready),
    .input_rready      (input_rready),

    // Register interface - Accelerator Engine Output
    .output_addr        (output_addr),
    .output_read_en     (output_read_en),
    .output_write_en    (output_write_en),
    .output_byte_strobe (output_byte_strobe),
    .output_wdata       (output_wdata),
    .output_rdata       (output_rdata),
    .output_wready      (output_wready),
    .output_rready      (output_rready)
  );

  wrapper_packet_deconstruct #(
    (ADDRWIDTH - 1),  // Only half address map allocated to this device
    256               // Ouptut Packet WIdth
  ) u_wrapper_packet_deconstruct (
    .hclk         (HCLK),
    .hresetn      (HRESETn),

    // Register interface
    .addr        (output_addr),
    .read_en     (output_read_en),
    .write_en    (output_write_en),
    .byte_strobe (output_byte_strobe),
    .wdata       (output_wdata),
    .rdata       (output_rdata),
    .wready      (output_wready),
    .rready      (output_rready),

    // Valid/Ready Interface
    .packet_data       (out_packet),
    .packet_data_last  (out_packet_last),
    .packet_data_valid (out_packet_valid),
    .packet_data_ready (out_packet_ready)
  );

  // wrapper_packet_construct #(
  //   (ADDRWIDTH - 1),  // Only half address map allocated to this device
  //   512               // Packet Width
  // ) u_wrapper_packet_construct (
  //   .hclk         (HCLK),
  //   .hresetn      (HRESETn),

  //   // Register interface
  //   .addr        (input_addr),
  //   .read_en     (input_read_en),
  //   .write_en    (input_write_en),
  //   .byte_strobe (input_byte_strobe),
  //   .wdata       (input_wdata),
  //   .rdata       (input_rdata),
  //   .wready      (input_wready),
  //   .rready      (input_rready),

  //   // Valid/Ready Interface
  //   .packet_data       (in_packet),
  //   .packet_data_last  (in_packet_last),
  //   .packet_data_valid (in_packet_valid),
  //   .packet_data_ready (in_packet_ready),

  //   .engine_ready()
  // );

  //------------------------
  // Accelerator Engine
  //------------------------
  sha256_hashing_stream u_sha256_hashing_stream (
        .clk            (HCLK),
        .nrst           (HRESETn),
        .en             (1'b1),
        .sync_rst       (1'b0),

        // Data in Channel
        .data_in        (in_packet),
        .data_in_valid  (in_packet_valid),
        .data_in_ready  (in_packet_ready),
        .data_in_last   (in_packet_last),

        // Config In Channel
        .cfg_size       (cfg_size),
        .cfg_scheme     (cfg_scheme),
        .cfg_last       (cfg_last),
        .cfg_valid      (cfg_valid),
        .cfg_ready      (cfg_ready),

        // Data Out Channel
        .data_out       (out_packet),
        .data_out_last  (out_packet_last),
        .data_out_valid (out_packet_valid),
        .data_out_ready (out_packet_ready)
    );

  // Default Target
  cmsdk_ahb_default_slave  u_ahb_default_slave(
    .HCLK         (HCLK),
    .HRESETn      (HRESETn),
    .HSEL         (hsel2),
    .HTRANS       (HTRANSS),
    .HREADY       (HREADYS),
    .HREADYOUT    (hreadyout2),
    .HRESP        (hresp2)
  );

  assign hrdata2 = {32{1'b0}}; // Default target doesn't have data

endmodule