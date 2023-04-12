//-----------------------------------------------------------------------------
// SoC Labs Basic Testbench for Top-level AHB Wrapper
// Modified from tb_frbm_example.v
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
//            (C) COPYRIGHT 2010-2011,2017 Arm Limited or its affiliates.
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
//-------------------------------------------------------------------------
//  Abstract            : Example for File Reader Bus Master
//                         Testbench for the example AHB Lite slave.
//=========================================================================--
// `include "wrapper_secworks_sha256.sv"

`timescale 1ns/1ps

import "DPI-C" function string getenv(input string env_name);

module tb_wrapper_secworks_sha256;

parameter CLK_PERIOD = 10;
parameter ADDRWIDTH = 12;

parameter InputFileName = ("/home/dam1n19/Design/secworks-sha256-project/wrapper/stimulus/ahb_input_hash_stim.m2d");
parameter MessageTag = "FileReader:";
parameter StimArraySize = 10000;


//********************************************************************************
// Internal Wires
//********************************************************************************

// AHB Lite BUS SIGNALS
wire             hready;
wire             hresp;
wire [31:0]      hrdata;

wire [1:0]       htrans;
wire [2:0]       hburst;
wire [3:0]       hprot;
wire [2:0]       hsize;
wire             hwrite;
wire             hmastlock;
wire [31:0]      haddr;
wire [31:0]      hwdata;

// Accelerator AHB Signals
wire             hsel0;
wire             hreadyout0;
wire             hresp0;
wire [31:0]      hrdata0;

// Default Slave AHB Signals
wire             hsel1;
wire             hreadyout1;
wire             hresp1;
wire [31:0]      hrdata1;

reg              HCLK;
reg              HRESETn;

//********************************************************************************
// Clock and reset generation
//********************************************************************************

  initial begin
    $write("env = %s\n", getenv("PWD"));
  end

initial
  begin
    $dumpfile("wrapper_secworks_sha256.vcd");
    $dumpvars(0, tb_wrapper_secworks_sha256);
    HRESETn = 1'b0;
    HCLK    = 1'b0;
    # (10*CLK_PERIOD);
    HRESETn = 1'b1;
  end

always
  begin
    HCLK = #(CLK_PERIOD/2) ~HCLK;
  end


//********************************************************************************
// Address decoder, need to be changed for other configuration
//********************************************************************************
// 0x60010000 - 0x60010FFF : HSEL #0 - Hash Accelerator
// Other addresses         : HSEL #1 - Default slave

  assign hsel0 = (haddr[31:12] == 20'h60010)? 1'b1:1'b0;
  assign hsel1 = hsel0 ? 1'b0:1'b1;

//********************************************************************************
// File read bus master:
// generate AHB Master signal by reading a file which store the AHB Operations
//********************************************************************************

cmsdk_ahb_fileread_master32 #(InputFileName, 
                              MessageTag,
                              StimArraySize
) u_ahb_fileread_master32 (
  .HCLK            (HCLK),
  .HRESETn         (HRESETn),

  .HREADY          (hready),
  .HRESP           ({hresp}),  //AHB Lite response to AHB response
  .HRDATA          (hrdata),
  .EXRESP          (1'b0),     //  Exclusive response (tie low if not used)


  .HTRANS          (htrans),
  .HBURST          (hburst),
  .HPROT           (hprot),
  .EXREQ           (),        //  Exclusive access request (not used)
  .MEMATTR         (),        //  Memory attribute (not used)
  .HSIZE           (hsize),
  .HWRITE          (hwrite),
  .HMASTLOCK       (hmastlock),
  .HADDR           (haddr),
  .HWDATA          (hwdata),

  .LINENUM         ()

  );


//********************************************************************************
// Slave multiplexer module:
//  multiplex the slave signals to master, two ports are enabled
//********************************************************************************

 cmsdk_ahb_slave_mux  #(
   1, //PORT0_ENABLE
   1, //PORT1_ENABLE
   0, //PORT2_ENABLE
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
  .HREADY      (hready),
  .HSEL0       (hsel0),      // Input Port 0
  .HREADYOUT0  (hreadyout0),
  .HRESP0      (hresp0),
  .HRDATA0     (hrdata0),
  .HSEL1       (hsel1),      // Input Port 1
  .HREADYOUT1  (hreadyout1),
  .HRESP1      (hresp1),
  .HRDATA1     (hrdata1),
  .HSEL2       (1'b0),      // Input Port 2
  .HREADYOUT2  (),
  .HRESP2      (),
  .HRDATA2     (),
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

  .HREADYOUT   (hready),     // Outputs
  .HRESP       (hresp),
  .HRDATA      (hrdata)
  );


//********************************************************************************
// Slave module 1: example AHB slave module
//********************************************************************************
  wrapper_secworks_sha256 #(ADDRWIDTH
  ) accelerator (
  .HCLK        (HCLK),
  .HRESETn     (HRESETn),

  //  Input slave port: 32 bit data bus interface
  .HSELS       (hsel0),
  .HADDRS      (haddr[ADDRWIDTH-1:0]),
  .HTRANSS     (htrans),
  .HSIZES      (hsize),
  .HWRITES     (hwrite),
  .HREADYS     (hready),
  .HWDATAS     (hwdata),

  .HREADYOUTS  (hreadyout0),
  .HRESPS      (hresp0),
  .HRDATAS     (hrdata0),

  // Input Data Request to DMAC
  .in_data_req (),
  .out_data_req ()
  );


//********************************************************************************
// Slave module 2: AHB default slave module
//********************************************************************************
 cmsdk_ahb_default_slave  u_ahb_default_slave(
  .HCLK         (HCLK),
  .HRESETn      (HRESETn),
  .HSEL         (hsel1),
  .HTRANS       (htrans),
  .HREADY       (hready),
  .HREADYOUT    (hreadyout1),
  .HRESP        (hresp1)
  );

 assign hrdata1 = {32{1'b0}}; // Default slave don't have data

 endmodule