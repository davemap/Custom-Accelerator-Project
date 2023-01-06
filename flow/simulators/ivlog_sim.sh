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

mkdir -p $SHA_2_ACC_DIR/simulate/sim/ 
iverilog -I $SHA_2_ACC_DIR/hdl/verif/ -I $SHA_2_ACC_DIR/hdl/src/ -g2012 -o $SHA_2_ACC_DIR/simulate/sim/$1.vvp $SHA_2_ACC_DIR/hdl/verif/tb_$1.sv
cd $SHA_2_ACC_DIR/simulate/sim/ && vvp $1.vvp