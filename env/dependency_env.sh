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

# Accelerator Engine
export SECWORKS_SHA2_TECH_DIR="$PROJECT_DIR/secworks-sha256"

# Accelerator Wrapper
export WRAPPER_TECH_DIR="$PROJECT_DIR/accelerator_wrapper_tech"

# NanoSoC
export NANOSOC_TECH_DIR="$PROJECT_DIR/nanosoc_tech"

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