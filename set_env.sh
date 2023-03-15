#-----------------------------------------------------------------------------
# SoC Labs Environment Setup Script
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright  2023, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------
#!/bin/bash

# Get Root Location of Design Structure
if [ -z $DESIGN_ROOT ]; then
    # If $DESIGN_ROOT hasn't been set yet
    DESIGN_ROOT=`git rev-parse --show-superproject-working-tree`

    if [ -z $DESIGN_ROOT ]; then
        # If not in a submodule - at root
        DESIGN_ROOT=`git rev-parse --show-toplevel`
    fi

    # Source Top-Level Sourceme
    source $DESIGN_ROOT/set_env.sh
else
    # Set Environment Variable for this Repository
    export SOC_TOP_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

    # If this Repo is root of workspace
    if [ $SOC_TOP_DIR = $DESIGN_ROOT ]; then
        echo "Design Workspace: $DESIGN_ROOT" 
        export DESIGN_ROOT
        # Set Default Simulator
        export SIMULATOR="ivlog"
    fi

    # Source environment variables for all submodules
    for d in $SOC_TOP_DIR/* ; do
        if [ -f "$d/.git" ]; then
            if [ -f "$d/set_env.sh" ]; then
            # If .git file exists - submodule
                source $d/set_env.sh
            fi
        fi
    done

    # Add Scripts to Path
    export PATH="$PATH:/$SOC_TOP_DIR/flow"
fi