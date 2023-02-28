package status_regs_rtl_pkg;
  localparam int STATUS_0_BYTE_WIDTH = 4;
  localparam int STATUS_0_BYTE_SIZE = 4;
  localparam bit [3:0] STATUS_0_BYTE_OFFSET = 4'h0;
  localparam int STATUS_0_STATUS_ID_BIT_WIDTH = 6;
  localparam bit [5:0] STATUS_0_STATUS_ID_BIT_MASK = 6'h3f;
  localparam int STATUS_0_STATUS_ID_BIT_OFFSET = 0;
  localparam int STATUS_0_STATUS_BUFFERED_IDS_BIT_WIDTH = 3;
  localparam bit [2:0] STATUS_0_STATUS_BUFFERED_IDS_BIT_MASK = 3'h7;
  localparam int STATUS_0_STATUS_BUFFERED_IDS_BIT_OFFSET = 6;
  localparam int STATUS_0_STATUS_ERR_BUFFER_BIT_WIDTH = 1;
  localparam bit STATUS_0_STATUS_ERR_BUFFER_BIT_MASK = 1'h1;
  localparam int STATUS_0_STATUS_ERR_BUFFER_BIT_OFFSET = 9;
  localparam int STATUS_0_STATUS_ERR_PACKET_BIT_WIDTH = 1;
  localparam bit STATUS_0_STATUS_ERR_PACKET_BIT_MASK = 1'h1;
  localparam int STATUS_0_STATUS_ERR_PACKET_BIT_OFFSET = 10;
  localparam int STATUS_0_STATUS_ERR_CLEAR_BIT_WIDTH = 1;
  localparam bit STATUS_0_STATUS_ERR_CLEAR_BIT_MASK = 1'h1;
  localparam int STATUS_0_STATUS_ERR_CLEAR_BIT_OFFSET = 11;
  localparam int STATUS_0_STATUS_PACKET_COUNT_BIT_WIDTH = 10;
  localparam bit [9:0] STATUS_0_STATUS_PACKET_COUNT_BIT_MASK = 10'h3ff;
  localparam int STATUS_0_STATUS_PACKET_COUNT_BIT_OFFSET = 12;
endpackage
