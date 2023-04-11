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

mkdir -p $PROJECT_DIR/simulate/sim/ 
iverilog -g2012 -o $PROJECT_DIR/simulate/sim/$1.vvp $WRAPPER_TECH_DIR/hdl/verif/tb_$1.sv
cd $PROJECT_DIR/simulate/sim/ && vvp $1.vvp $2