#-----------------------------------------------------------------------------
# SoC Labs Dependency Repository Environment Setup Script
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright  2023, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------
#!/bin/bash

#-----------------------------------------------------------------------------
# Technologies
#-----------------------------------------------------------------------------

# Accelerator Engine -- Add Your Accelerator Environment Variable HERE!
# export YOUR_ACCELERATOR_DIR="$PROJECT_DIR/your_accelerator"

# Accelerator Wrapper
export WRAPPER_TECH_DIR="$PROJECT_DIR/accelerator_wrapper_tech"

# NanoSoC
export NANOSOC_TECH_DIR="$PROJECT_DIR/nanosoc_tech"

# Primtives
export PRIMITIVES_TECH_DIR="$PROJECT_DIR/rtl_primitives_tech"

# FPGA Libraries
export FPGA_LIB_TECH_DIR="$PROJECT_DIR/fpga_lib_tech"

# Generic Libraries
export GENERIC_LIB_TECH_DIR="$PROJECT_DIR/generic_lib_tech"

#-----------------------------------------------------------------------------
# Flows
#-----------------------------------------------------------------------------

# CHIPKIT - Register Generation
export CHIPKIT_FLOW_DIR="$PROJECT_DIR/chipkit_flow"

# SoCSim - Basic Simulation Flow Wrapper
export SOCSIM_FLOW_DIR="$PROJECT_DIR/socsim_flow"