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

mkdir -p $SOC_TOP/simulate/sim/ 
iverilog -I $SOC_TOP/hdl/verif/ -I $SOC_TOP/hdl/src/ -g2012 -o $SOC_TOP/simulate/sim/$1.vvp $SOC_TOP/hdl/verif/tb_$1.sv
cd $SOC_TOP/simulate/sim/ && vvp $1.vvp $2