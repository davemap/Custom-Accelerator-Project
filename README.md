# SHA-2 Accelerator

This project is an example accelerator which can be combined with the SoC Labs SoC infrastructure. 

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