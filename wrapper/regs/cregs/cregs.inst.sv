// VGEN START: Autogenerated by /Users/davidmapstone/Documents/SoCLabs/RTL/accelerator-system-top/CHIPKIT/tools/vgen/bin/vgen.py on 10:59:11 24/03/2023

// START
logic [31:0] accelerator_en;
logic [31:0] accelerator_channel_en;

cregs u_cregs (

// clocks and resets
.clk(pclk),
.rstn(presetn),

// Synchronous register interface
.regbus           (cregs.sink),

// reg file signals
.accelerator_en(accelerator_en[31:0])	/* idx 0 */,
.accelerator_channel_en(accelerator_channel_en[31:0])	/* idx 1 */

);
// END

// VGEN END: Autogenerated by /Users/davidmapstone/Documents/SoCLabs/RTL/accelerator-system-top/CHIPKIT/tools/vgen/bin/vgen.py on 10:59:11 24/03/2023

