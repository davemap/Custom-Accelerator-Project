#-----------------------------------------------------------------------------
# SoC Labs Cadence Xcelium simulation script for engine testbench
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
make run_xm \
    TESTNAME=hello \
    ACCELERATOR_VC="-sv -f $ACC_ENGINE_DIR/flist/sha-2-accelerator_src.flist -f $ACC_WRAPPER_DIR/flist/wrapper_ip.flist" \
    ADP_FILE="$SOC_TOP_DIR/system/stimulus/adp_hash_stim.cmd" \
    -C $NANOSOC_DIR/Cortex-M0/nanosoc/systems/mcu/rtl_sim