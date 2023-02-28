# SHA-2 Accelerator

This project is an example accelerator which will be combined with the SoC Labs SoC infrastructure. 
Test


## Repository Structure
The respository is currently broken down into 2 main directories:
- hdl
- simulate

HDL contains all the verilog files. This is seperated into:
- src
- verif

src contains SystemVerilog design files and verif contains the SystemVerilog testbenches and verification resources.

The simulate directory contains the socsim script, along with a directory called "simulators" which contains simulator-specific scripts and a "sim" directory which contains dumps and logs from simulation runs. The files in this directory should not be commited to the Git.

## Setting Up Environment
To be able to simulate in this repository, you will first need to source the sourceme:
```
% source sourceme
```

## Stimulus Generation
Under `model/py`, there is `hash_model.py` which is a python model of the hashing accelerator. This produces numerous `.csv` files which can be fed in testbenches. These files are seperated into two types:
- stimiulus
- reference

Stimulus files are used to stimulate the DUT by feeding into the inputs of the module. Reference files are used to compare to the output of the DUT to check whether it is behaving correctly. 

These files are present in the `simulate/stimulus/unit/` or `simulate/stimulus/system/` directories. Unit contains stimulus and reference files for unit tests - internal wrapper engine verification. System contains stimulus and reference files for System and Wrapper tests.

The `simulate/stimulus/model/` directory contains a hand-written stimulus file which is used to seed and constrain the python model. There are `5` values in this file and are listed as follows:
- Seed - random seed used to seed python model
- Payload Number - Number of payloads to generate
- Payload Size (Bits) - Number of bits a payload is comprised of. If set to 0, this is randomised each payload. If non-zero, each payload will have a size of this value.
- Gap Limit - Maximum number of clock cycles to gap on the input (cycles to wait before asserting valid on the input data)
- Stall Limit - Maximum number of clock cycles to stall on the output (cycles to wait before asseting ready on the output)

To generate the stimulus and reference, ensure the `sourceme` in the root of this repo has been sourced and then run `python3 hash_model.py` within the `model/py` directory. This will populate the directories with the `.csv` files in the `simulate/stimulus` directory.

## Simulation Setup
This will set up the environment variables and will set the simulator used. Defaultly, this is set to ivlog - Icarus Verilog. This can be overloaded from the command line with the following command:
```
% SIMULATOR=yoursimulator
```

Once this is done, a simulation can be ran using the socsim command:
```
% socsim
```
This will generate simulation dumps in the following directory:
```
% $SHA_2_ACC_DIR/simulate/sim
```