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

# Generate Stimulus from stimulus generation Script
# python3 $ACC_SEC_SHA2_DIR/flow/stimgen.py
# Create Simulatiom Directory to Run in
mkdir -p $SOC_TOP_DIR/simulate/sim/ 
mkdir -p $SOC_TOP_DIR/simulate/sim/wrapper_secworks_sha256

cd $SOC_TOP_DIR/simulate/sim/wrapper_secworks_sha256
# Compile Simulation
xrun \
    -64bit \
    -sv \
    -timescale 1ps/1ps \
    +access+r \
    -f $SOC_TOP_DIR/flist/wrapper.flist \
    -f $SOC_TOP_DIR/flist/primatives.flist \
    -f $SOC_TOP_DIR/flist/ahb_ip.flist \
    -f $SOC_TOP_DIR/flist/ahb_vip.flist \
    -f $ACC_SEC_SHA2_DIR/flist/*.flist \
    -f $ACC_WRAPPER_DIR/flist/wrapper_ip.flist \
    -xmlibdirname $SOC_TOP_DIR/simulate/sim/wrapper_secworks_sha256 \
    $SOC_TOP_DIR/wrapper/verif/tb_wrapper_secworks_sha256.sv \
    -gui \
    -top tb_wrapper_secworks_sha256

# Run Simulation
# cd $SOC_TOP_DIR/simulate/sim/ && vvp wrapper_sha256_hashing_stream.vvp