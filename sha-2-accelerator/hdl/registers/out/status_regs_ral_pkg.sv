package status_regs_ral_pkg;
  import uvm_pkg::*;
  import rggen_ral_pkg::*;
  `include "uvm_macros.svh"
  `include "rggen_ral_macros.svh"
  class status_0_reg_model extends rggen_ral_reg;
    rand rggen_ral_field status_id;
    rand rggen_ral_field status_buffered_ids;
    rand rggen_ral_field status_err_buffer;
    rand rggen_ral_field status_err_packet;
    rand rggen_ral_field status_err_clear;
    rand rggen_ral_field status_packet_count;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(status_id, 0, 6, "RO", 1, 6'h00, 1, -1, "")
      `rggen_ral_create_field(status_buffered_ids, 6, 3, "RO", 1, 3'h0, 1, -1, "")
      `rggen_ral_create_field(status_err_buffer, 9, 1, "RO", 1, 1'h0, 1, -1, "")
      `rggen_ral_create_field(status_err_packet, 10, 1, "RO", 1, 1'h0, 1, -1, "")
      `rggen_ral_create_field(status_err_clear, 11, 1, "WO", 0, 1'h0, 1, -1, "")
      `rggen_ral_create_field(status_packet_count, 12, 10, "RO", 1, 10'h000, 1, -1, "")
    endfunction
  endclass
  class status_regs_block_model extends rggen_ral_block;
    rand status_0_reg_model status_0;
    function new(string name);
      super.new(name, 4, 0);
    endfunction
    function void build();
      `rggen_ral_create_reg(status_0, '{}, 4'h0, "RW", "g_status_0.u_register")
    endfunction
  endclass
endpackage
