//-----------------------------------------------------------------------------
// Nanosoc Expansion Region AHB Address Region
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright 2021-3, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------
`include "cmsdk_ahb_default_slave.v"
`include "cmsdk_ahb_slave_mux.v"

module nanosoc_exp #(
    parameter    ADDRWIDTH=29, // Region Address Width
    parameter    ACCEL_ADDRWIDTH=12 // Region Address Width
  )(
    input  wire                  HCLK,       // Clock
    input  wire                  HRESETn,    // Reset

  // AHB connection to Initiator
    input  wire                  HSELS,
    input  wire  [ADDRWIDTH-1:0] HADDRS,
    input  wire  [1:0]           HTRANSS,
    input  wire  [2:0]           HSIZES,
    input  wire                  HWRITES,
    input  wire                  HREADYS,
    input  wire  [31:0]          HWDATAS,

    output wire                  HREADYOUTS,
    output wire                  HRESPS,
    output wire  [31:0]          HRDATAS
  );

//********************************************************************************
// Internal Wires
//********************************************************************************

// Accelerator AHB Signals
wire             HSEL0;
wire             HREADYOUT0;
wire             HRESP0;
wire [31:0]      HRDATA0;

// Default Slave AHB Signals
wire             HSEL1;
wire             HREADYOUT1;
wire             HRESP1;
wire [31:0]      HRDATA1;

//********************************************************************************
// Address decoder, need to be changed for other configuration
//********************************************************************************
// 0x00010000 - 0x00010FFF : HSEL #0 - Hash Accelerator
// Other addresses         : HSEL #1 - Default target

  assign HSEL0 = (HADDRS[ADDRWIDTH-1:12] == 'h00010) ? 1'b1:1'b0;
  assign HSEL1 = HSEL0 ? 1'b0:1'b1;

//********************************************************************************
// Slave multiplexer module:
//  multiplex the target signals to master, three ports are enabled
//********************************************************************************

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
  .HSEL0       (HSEL0),      // Input Port 0
  .HREADYOUT0  (HREADYOUT0),
  .HRESP0      (HRESP0),
  .HRDATA0     (HRDATA0),
  .HSEL1       (HSEL1),      // Input Port 1
  .HREADYOUT1  (HREADYOUT1),
  .HRESP1      (HRESP1),
  .HRDATA1     (HRDATA1),
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

  .HREADYOUT   (HREADYOUTS),     // Outputs
  .HRESP       (HRESPS),
  .HRDATA      (HRDATAS)
  );


//********************************************************************************
// Slave module 1: Accelerator AHB target module
//********************************************************************************
  wrapper_sha256_hashing_stream #(ACCEL_ADDRWIDTH
  ) accelerator (
  .HCLK        (HCLK),
  .HRESETn     (HRESETn),

  //  Input target port: 32 bit data bus interface
  .HSELS       (HSEL0),
  .HADDRS      (HADDRS[ACCEL_ADDRWIDTH-1:0]),
  .HTRANSS     (HTRANSS),
  .HSIZES      (HSIZES),
  .HWRITES     (HWRITES),
  .HREADYS     (HREADYS),
  .HWDATAS     (HWDATAS),

  .HREADYOUTS  (HREADYOUT0),
  .HRESPS      (HRESP0),
  .HRDATAS     (HRDATA0)

  );


//********************************************************************************
// Slave module 2: AHB default target module
//********************************************************************************
 cmsdk_ahb_default_slave  u_ahb_default_slave(
  .HCLK         (HCLK),
  .HRESETn      (HRESETn),
  .HSEL         (HSEL1),
  .HTRANS       (HTRANSS),
  .HREADY       (HREADYS),
  .HREADYOUT    (HREADYOUT1),
  .HRESP        (HRESPS)
  );

 assign HRDATA1 = {32{1'b0}}; // Default target don't have data

endmodule
