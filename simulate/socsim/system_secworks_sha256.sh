#-----------------------------------------------------------------------------
# SoC Labs Simulation script for system level verification
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright  2023, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------

#!/usr/bin/env bash

# Generate Stimulus from stimulus generation Script
# python3 $SECWORKS_SHA2_TECH_DIR/flow/stimgen.py
# Create Simulatiom Directory to Run in

# Get simulation name from name of script
SIM_NAME=`basename -s .sh "$0"`

# Directory to put simulation files
SIM_DIR=$PROJECT_DIR/simulate/sim/$SIM_NAME

# Create Directory to put simulation files
mkdir -p $SIM_DIR

cd $PROJECT_DIR/simulate/sim/system_secworks_sha256
# Compile Simulation
# Call makefile in NanoSoC Repo with options
make -C $NANOSOC_TECH_DIR/systems/mcu/rtl_sim compile_xm \
    SIM_DIR=$SIM_DIR
