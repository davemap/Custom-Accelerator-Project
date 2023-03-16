//-----------------------------------------------------------------------------
// SoC Labs Basic Wrapper Source
// - Valid-Ready Loopback example connecting packet constructor to deconstructor
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
`timescale 1ns/1ns
// `include "wrapper_packet_construct.sv"
// `include "wrapper_packet_deconstruct.sv"
// `include "wrapper_ahb_vr_interface.sv"

module wrapper_vr_loopback #(
    parameter    ADDRWIDTH=12,   // Peripheral Address Width
    parameter    PACKETWIDTH=512 // VR Packet Width
  )(
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
  logic [PACKETWIDTH-1:0] packet;    
  logic         packet_last; 
  logic         packet_valid;
  logic         packet_ready;

  //-----------------------------------------------------------
  // Module logic start
  //----------------------------------------------------------

  // Interface block to convert AHB transfers to Register transfers to engine input/output channels
  // engine Input/Output Channels
  wrapper_ahb_vr_interface #(
    ADDRWIDTH
   ) u_wrapper_ahb_interface (
    .hclk         (HCLK),
    .hresetn      (HRESETn),

    // Input slave port: 32 bit data bus interface
    .hsels        (HSELS),
    .haddrs       (HADDRS),
    .htranss      (HTRANSS),
    .hsizes       (HSIZES),
    .hwrites      (HWRITES),
    .hreadys      (HREADYS),
    .hwdatas      (HWDATAS),

    .hreadyouts   (HREADYOUTS),
    .hresps       (HRESPS),
    .hrdatas      (HRDATAS),

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

  wrapper_packet_construct #(
    (ADDRWIDTH - 1),  // Only half address map allocated to this device
    PACKETWIDTH       // Packet Width
  ) u_wrapper_packet_construct (
    .hclk         (HCLK),
    .hresetn      (HRESETn),

    // Register interface
    .addr        (input_addr),
    .read_en     (input_read_en),
    .write_en    (input_write_en),
    .byte_strobe (input_byte_strobe),
    .wdata       (input_wdata),
    .rdata       (input_rdata),
    .wready      (input_wready),
    .rready      (input_rready),

    // Valid/Ready Interface
    .packet_data       (packet),
    .packet_data_last  (packet_last),
    .packet_data_valid (packet_valid),
    .packet_data_ready (packet_ready)
  );

  wrapper_packet_deconstruct #(
    (ADDRWIDTH - 1),  // Only half address map allocated to this device
    PACKETWIDTH       // Ouptut Packet Width
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
    .packet_data       (packet),
    .packet_data_last  (packet_last),
    .packet_data_valid (packet_valid),
    .packet_data_ready (packet_ready)
  );

  //-----------------------------------------------------------
  //Module logic end
  //----------------------------------------------------------

`ifdef ARM_AHB_ASSERT_ON

 `include "std_ovl_defines.h"
  // ------------------------------------------------------------
  // Assertions
  // ------------------------------------------------------------

  logic     ovl_trans_req = HREADYS & HSELS & HTRANSS[1];

   // Check the reg_write_en signal generated
   assert_next
    #(`OVL_ERROR, 1,1,0,
      `OVL_ASSERT,
      "Error! register write signal was not generated! "
      )
    u_ovl_ahb_eg_slave_reg_write
    (.clk         ( HCLK ),
     .reset_n     (HRESETn),
     .start_event ((ovl_trans_req & HWRITES)),
     .test_expr   (reg_write_en == 1'b1)
     );


  // Check the reg_read_en signal generated
  assert_next
    #(`OVL_ERROR, 1,1,0,
      `OVL_ASSERT,
      "Error! register read signal was not generated! "
      )
    u_ovl_ahb_eg_slave_reg_read
    (.clk         ( HCLK ),
     .reset_n     (HRESETn),
     .start_event ((ovl_trans_req & (~HWRITES))),
     .test_expr   (reg_read_en == 1'b1)
     );



  // Check register read and write operation won't assert at the same cycle
    assert_never
     #(`OVL_ERROR,
       `OVL_ASSERT,
       "Error! register read and write active at the same cycle!")
    u_ovl_ahb_eg_slave_rd_wr_illegal
     (.clk(HCLK),
      .reset_n(HRESETn),
      .test_expr((reg_write_en & reg_read_en))
      );

`endif

endmodule