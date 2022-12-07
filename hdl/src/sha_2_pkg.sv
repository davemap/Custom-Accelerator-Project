//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-2 Engine function and constants SV Package
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------

package sha_2_pkg;
    parameter data_width = 32;
    
    // SHA-2 Functions
    function logic [data_width-1:0] ssig0 (
        logic [data_width-1:0] x);
        logic [data_width-1:0] xrotr7, xrotr18, xshr3;
        assign xrotr7 = {x[6:0], x[31:7]};
        assign xrotr18 = {x[17:0], x[31:18]};
        assign xshr3 = x >> 3;
        assign ssig0 = xrotr7 ^ xrotr18 ^ xshr3;
    endfunction 
 
    function logic [data_width-1:0] ssig1 (
        logic [data_width-1:0] x);
        logic [data_width-1:0] xrotr17, xrotr19, xshr10;
        assign xrotr17 = {x[16:0], x[31:17]};
        assign xrotr19 = {x[18:0], x[31:19]};
        assign xshr10 = x >> 10;
        assign ssig1 = xrotr17 ^ xrotr19 ^ xshr10;
    endfunction 
    
    function logic [data_width-1:0] bsig0 (
        logic [data_width-1:0] x);
        logic [data_width-1:0] xrotr2, xrotr13, xrotr22;
        assign xrotr2  = {x[1:0], x[31:2]};
        assign xrotr13 = {x[12:0], x[31:13]};
        assign xrotr22 = {x[21:0], x[31:22]};
        assign bsig0 = xrotr2 ^ xrotr13 ^ xrotr22;
    endfunction 
    
    function logic [data_width-1:0] bsig1 (
        logic [data_width-1:0] x);
        logic [data_width-1:0] xrotr6, xrotr11, xrotr25;
        assign xrotr6  = {x[5:0], x[31:6]};
        assign xrotr11 = {x[10:0], x[31:11]};
        assign xrotr25 = {x[24:0], x[31:25]};
        assign bsig1 = xrotr6 ^ xrotr11 ^ xrotr25;
    endfunction 
    
    function logic [data_width-1:0] ch (
        logic [data_width-1:0] x, y, z);
        assign ch = (x & y) ^ ((~x) & z);
    endfunction 
    
    function logic [data_width-1:0] maj (
        logic [data_width-1:0] x, y, z);
        assign maj = (x & y) ^ (x & z) ^ (y & z);
    endfunction 
    
    // SHA-2 Constants
    const logic [31:0] K0  = 32'h428a2f98; 
    const logic [31:0] K1  = 32'h71374491; 
    const logic [31:0] K2  = 32'hb5c0fbcf; 
    const logic [31:0] K3  = 32'he9b5dba5;
    const logic [31:0] K4  = 32'h3956c25b; 
    const logic [31:0] K5  = 32'h59f111f1; 
    const logic [31:0] K6  = 32'h923f82a4; 
    const logic [31:0] K7  = 32'hab1c5ed5;
    const logic [31:0] K8  = 32'hd807aa98; 
    const logic [31:0] K9  = 32'h12835b01; 
    const logic [31:0] K10 = 32'h243185be; 
    const logic [31:0] K11 = 32'h550c7dc3;
    const logic [31:0] K12 = 32'h72be5d74; 
    const logic [31:0] K13 = 32'h80deb1fe; 
    const logic [31:0] K14 = 32'h9bdc06a7; 
    const logic [31:0] K15 = 32'hc19bf174;
    const logic [31:0] K16 = 32'he49b69c1; 
    const logic [31:0] K17 = 32'hefbe4786; 
    const logic [31:0] K18 = 32'h0fc19dc6; 
    const logic [31:0] K19 = 32'h240ca1cc;
    const logic [31:0] K20 = 32'h2de92c6f; 
    const logic [31:0] K21 = 32'h4a7484aa; 
    const logic [31:0] K22 = 32'h5cb0a9dc; 
    const logic [31:0] K23 = 32'h76f988da;
    const logic [31:0] K24 = 32'h983e5152; 
    const logic [31:0] K25 = 32'ha831c66d; 
    const logic [31:0] K26 = 32'hb00327c8; 
    const logic [31:0] K27 = 32'hbf597fc7;
    const logic [31:0] K28 = 32'hc6e00bf3; 
    const logic [31:0] K29 = 32'hd5a79147; 
    const logic [31:0] K30 = 32'h06ca6351; 
    const logic [31:0] K31 = 32'h14292967;
    const logic [31:0] K32 = 32'h27b70a85; 
    const logic [31:0] K33 = 32'h2e1b2138; 
    const logic [31:0] K34 = 32'h4d2c6dfc; 
    const logic [31:0] K35 = 32'h53380d13;
    const logic [31:0] K36 = 32'h650a7354; 
    const logic [31:0] K37 = 32'h766a0abb; 
    const logic [31:0] K38 = 32'h81c2c92e; 
    const logic [31:0] K39 = 32'h92722c85;
    const logic [31:0] K40 = 32'ha2bfe8a1; 
    const logic [31:0] K41 = 32'ha81a664b; 
    const logic [31:0] K42 = 32'hc24b8b70; 
    const logic [31:0] K43 = 32'hc76c51a3;
    const logic [31:0] K44 = 32'hd192e819; 
    const logic [31:0] K45 = 32'hd6990624; 
    const logic [31:0] K46 = 32'hf40e3585; 
    const logic [31:0] K47 = 32'h106aa070;
    const logic [31:0] K48 = 32'h19a4c116; 
    const logic [31:0] K49 = 32'h1e376c08; 
    const logic [31:0] K50 = 32'h2748774c; 
    const logic [31:0] K51 = 32'h34b0bcb5;
    const logic [31:0] K52 = 32'h391c0cb3; 
    const logic [31:0] K53 = 32'h4ed8aa4a; 
    const logic [31:0] K54 = 32'h5b9cca4f; 
    const logic [31:0] K55 = 32'h682e6ff3;
    const logic [31:0] K56 = 32'h748f82ee; 
    const logic [31:0] K57 = 32'h78a5636f; 
    const logic [31:0] K58 = 32'h84c87814; 
    const logic [31:0] K59 = 32'h8cc70208;
    const logic [31:0] K60 = 32'h90befffa; 
    const logic [31:0] K61 = 32'ha4506ceb; 
    const logic [31:0] K62 = 32'hbef9a3f7; 
    const logic [31:0] K63 = 32'hc67178f2;
    
    // H_init Constants
    const logic [31:0] H0_init = 32'h6a09e667;
    const logic [31:0] H1_init = 32'hbb67ae85;
    const logic [31:0] H2_init = 32'h3c6ef372;
    const logic [31:0] H3_init = 32'ha54ff53a;
    const logic [31:0] H4_init = 32'h510e527f;
    const logic [31:0] H5_init = 32'h9b05688c;
    const logic [31:0] H6_init = 32'h1f83d9ab;
    const logic [31:0] H7_init = 32'h5be0cd19;
endpackage