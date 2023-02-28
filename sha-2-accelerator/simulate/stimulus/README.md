The csv files in this directory are used for verifcation of systemverilog modules.

The model directory contains a hand written stimulus to be used by python models to generate the testbench stimulus. 
The first value is the random seed followed by the number of packets:
    seed,packets
    
The testbench directory contains stimulus for the SV testbenches. Input stimulus is fed into the testbench to drive the design and the output is used to verify the outputs of the design.