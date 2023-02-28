#-----------------------------------------------------------------------------
# SoC Labs socsim script to run required simulation
# A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
#
# Contributors
#
# David Mapstone (d.a.mapstone@soton.ac.uk)
#
# Copyright  2022, SoC Labs (www.soclabs.org)
#-----------------------------------------------------------------------------

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-m", "--model", type=str, help="Python Model used to generate Sitmulus and Reference for design")
parser.add_argument("-s", "--stimulus", type=str, help="Stimulus to pass to Python Model to generate Testbench Stimulus and Reference")
parser.parse_args()