#-----------------------------------------------------------------------------
# SoC Labs Simulation script for wrapper level verification testbench
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
# python3 $SECWORKS_SHA2_TECH_DIR/flow/stimgen.py
# Create Simulatiom Directory to Run in
mkdir -p $PROJECT_DIR/simulate/sim/ 
mkdir -p $PROJECT_DIR/simulate/sim/wrapper_secworks_sha256

cd $PROJECT_DIR/simulate/sim/wrapper_secworks_sha256
# Compile Simulation
xrun \
    -64bit \
    -sv \
    -timescale 1ps/1ps \
    +access+r \
    -f $PROJECT_DIR/flist/primatives.flist \
    -f $PROJECT_DIR/flist/wrapper_ip.flist \
    -f $PROJECT_DIR/flist/ahb_ip.flist \
    -f $PROJECT_DIR/flist/apb_ip.flist \
    -f $PROJECT_DIR/flist/wrapper.flist \
    -f $PROJECT_DIR/flist/ahb_vip.flist \
    -f $PROJECT_DIR/flist/secworks_sha25_stream.flist \
    -xmlibdirname $PROJECT_DIR/simulate/sim/wrapper_secworks_sha256 \
    $PROJECT_DIR/wrapper/verif/tb_wrapper_secworks_sha256.sv \
    -gui \
    -top tb_wrapper_secworks_sha256