//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-2 Hash Compression AHB Wrapper
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
`include "reg_to_512_vr.sv"
`include "fifo_vr.sv"

module wrap_sha256_hash_compression #(
  // Parameter for address width
  parameter    ADDRWIDTH=12) // Peripheral Address Width
 (
  input  wire                  HCLK,       // Clock
  input  wire                  HRESETn,    // Reset

  // AHB connection to master
  input  wire                  HSELS,
  input  wire  [ADDRWIDTH-1:0] HADDRS,
  input  wire  [1:0]           HTRANSS,
  input  wire  [2:0]           HSIZES,
  input  wire                  HWRITES,
  input  wire                  HREADYS,
  input  wire  [31:0]          HWDATAS,

  output wire                  HREADYOUTS,
  output wire                  HRESPS,
  output wire  [31:0]          HRDATAS);


  // ----------------------------------------
  // Internal wires declarations

  // Register module interface signals
  wire  [ADDRWIDTH-1:0]  in_buf_addr;
  wire                   in_buf_read_en;
  wire                   in_buf_write_en;
  wire  [3:0]            in_buf_byte_strobe;
  wire  [31:0]           in_buf_wdata;
  wire  [31:0]           in_buf_rdata;

  //-----------------------------------------------------------
  // Module logic start
  //----------------------------------------------------------

  // Interface block to convert AHB transfers to simple read/write
  // controls.
  cmsdk_ahb_eg_slave_interface
   #(.ADDRWIDTH (ADDRWIDTH))
    u_ahb_eg_slave_interface (
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

  // Register interface
  .addr         (in_buf_addr),
  .read_en      (in_buf_read_en),
  .write_en     (in_buf_write_en),
  .byte_strobe  (in_buf_byte_strobe),
  .wdata        (in_buf_wdata),
  .rdata        (in_buf_rdata)
  );

  reg_to_512_vr
   #(.ADDRWIDTH (ADDRWIDTH))
    u_reg_to_512_vr (
  .hclk         (HCLK),
  .hresetn      (HRESETn),

   // Register interface
  .addr         (in_buf_addr),
  .read_en      (in_buf_read_en),
  .write_en     (in_buf_write_en),
  .byte_strobe  (in_buf_byte_strobe),
  .wdata        (in_buf_wdata),
  .rdata        (in_buf_rdata)
  );
  cmsdk_ahb_eg_slave_interface
   #(.ADDRWIDTH (ADDRWIDTH))
    u_ahb_eg_slave_interface (
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

  // Register interface
  .addr         (reg_addr),
  .read_en      (reg_read_en),
  .write_en     (reg_write_en),
  .byte_strobe  (reg_byte_strobe),
  .wdata        (reg_wdata),
  .rdata        (reg_rdata)
  );

  // Simple data register block with four 32-bit registers
  cmsdk_ahb_eg_slave_reg
   #(.ADDRWIDTH (ADDRWIDTH))
    u_ahb_eg_slave_reg (

  .hclk         (HCLK),
  .hresetn      (HRESETn),

   // Register interface
  .addr         (reg_addr),
  .read_en      (reg_read_en),
  .write_en     (reg_write_en),
  .byte_strobe  (reg_byte_strobe),
  .wdata        (reg_wdata),
  .ecorevnum    (ECOREVNUM),
  .rdata        (reg_rdata)

  );

  //-----------------------------------------------------------
  //Module logic end
  //----------------------------------------------------------
`ifdef ARM_AHB_ASSERT_ON

 `include "std_ovl_defines.h"
  // ------------------------------------------------------------
  // Assertions
  // ------------------------------------------------------------

  wire     ovl_trans_req = HREADYS & HSELS & HTRANSS[1];

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



    // Data In data and Handshaking
    logic [511:0] engine_data_in;
    logic [5:0]   engine_data_in_id;
    logic engine_data_in_last;
    logic enigne_data_in_valid;
    logic enigne_data_in_ready;
    
    // Data Out data and Handshaking
    logic [255:0] engine_data_out;
    logic [5:0]   engine_data_out_id;
    logic engine_data_out_last;
    logic engine_data_out_valid;
    logic engine_data_out_ready;

    // Input Buffer
    fifo_vr #(16, // Depth
              512 // Data Width 
    ) data_in_buffer (
        .clk            (clk),
        .nrst           (nrst),
        .en             (en),
        .sync_rst       (sync_rst),
        .data_in        (data_in),
        .data_in_valid  (data_in_valid),
        .data_in_ready  (data_in_ready),
        .data_in_last   (data_in_last),
        .data_out       (data_in_buffered),
        .data_out_last  (data_in_last_buffered),
        .data_out_valid (data_in_valid_buffered),
        .data_out_ready (data_in_ready_buffered)
    );

    // Input Word Combiner

endmodule