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
python3 $ACC_WRAPPER_DIR/flow/stimgen.py
# Create Simulatiom Directory to Run in
mkdir -p $SOC_TOP_DIR/simulate/sim/ 
# Compile Simulation
iverilog \
    -c $SOC_TOP_DIR/flist/wrapper.flist \
    -c $SOC_TOP_DIR/flist/ahb_ip.flist \
    -c $SOC_TOP_DIR/flist/ahb_vip.flist \
    -c $ACC_WRAPPER_DIR/flist/wrapper_ip.flist \
    -c $ACC_ENGINE_DIR/flist/*.flist \
    -g2012 \
    -o $SOC_TOP_DIR/simulate/sim/wrapper_sha256_hashing_stream.vvp \
    $SOC_TOP_DIR/wrapper/verif/tb_wrapper_sha256_hashing_stream.sv
# Run Simulation
cd $SOC_TOP_DIR/simulate/sim/ && vvp wrapper_sha256_hashing_stream.vvp