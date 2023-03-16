#-----------------------------------------------------------------------------
# SoC Labs icarus verilog simulation script for engine testbench
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright  2022, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------

#!/usr/bin/env bash

mkdir -p $SOC_TOP_DIR/simulate/sim/ 
iverilog -c $ACC_WRAPPER_DIR/flist/accelerator_wrapper.flist -c $ACC_WRAPPER_DIR/flist/ahb_ip.flist -c $ACC_ENGINE_DIR/flist/*.flist -I $ACC_WRAPPER_DIR/hdl/verif/ -I $ACC_WRAPPER_DIR/hdl/verif/submodules -I $ACC_WRAPPER_DIR/hdl/src/ -I $ACC_ENGINE_DIR/hdl/src/ -g2012 -o $SOC_TOP_DIR/simulate/sim/wrapper_sha256_hashing_stream.vvp $ACC_WRAPPER_DIR/hdl/verif/tb_wrapper_sha256_hashing_stream.sv
cd $SOC_TOP_DIR/simulate/sim/ && vvp wrapper_sha256_hashing_stream.vvp +STIMFILE=$ACC_WRAPPER_DIR/simulate/stimulus/ahb_input_hash_stim.m2d