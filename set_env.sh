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
    export PROJECT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # If this Repo is root of workspace
    if [ $PROJECT_DIR = $DESIGN_ROOT ]; then
        echo "Design Workspace: $DESIGN_ROOT" 
        export DESIGN_ROOT
        # Set Default Simulator
        export SIMULATOR="ivlog"
    fi

    # Source dependency environment variable script
    source $PROJECT_DIR/env/dependency_env.sh

    # Add Scripts to Path
    # "TECH_DIR"
    while read line; do 
        eval PATH="$PATH:\$${line}/flow"
    done <<< "$(awk 'BEGIN{for(v in ENVIRON) print v}' | grep TECH_DIR)"

    # "FLOW_DIR"
    while read line; do 
        eval PATH="$PATH:\$${line}/flow"
    done <<< "$(awk 'BEGIN{for(v in ENVIRON) print v}' | grep FLOW_DIR)"

    # "PROJECT_DIR"
    while read line; do 
        eval PATH="$PATH:\$${line}/flow"
    done <<< "$(awk 'BEGIN{for(v in ENVIRON) print v}' | grep PROJECT_DIR)"

    export PATH
fi

# Check cloned repository has been initialised
if [ ! -f $PROJECT_DIR/.socinit ]; then
    echo "Running First Time Repository Initialisation"
    # Source environment variables for all submodules
    cd $DESIGN_ROOT
    for d in $PROJECT_DIR/* ; do
        if [ -e "$d/.git" ]; then
            if [ -f "$d/set_env.sh" ]; then
            # If .git file exists - submodule
                # git config -f .gitmodules submodule.$d.branch main
                git submodule set-branch --branch main $d
            fi
        fi
    done
    git submodule update --remote --recursive --init
    # git submodule foreach --recursive git checkout main
    git restore $DESIGN_ROOT/.gitmodules
    touch $PROJECT_DIR/.socinit
fi