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
        xrotr7 = (x << 25) | (x >> 7);
        xrotr18 = (x << 14) | (x >> 18);
        xshr3 = x >> 3;
        ssig0 = xrotr7 ^ xrotr18 ^ xshr3;
    endfunction 
 
    function logic [data_width-1:0] ssig1 (
        logic [data_width-1:0] x);
        logic [data_width-1:0] xrotr17, xrotr19, xshr10;
        xrotr17 = (x << 15) | (x >> 17);
        xrotr17 = (x << 13) | (x >> 19);
        xshr10 = x >> 10;
        ssig1 = xrotr17 ^ xrotr19 ^ xshr10;
    endfunction 
    
    function logic [data_width-1:0] bsig0 (
        logic [data_width-1:0] x);
        logic [data_width-1:0] xrotr2, xrotr13, xrotr22;
        xrotr2  = (x << 30) | (x >> 2);
        xrotr13 = (x << 19) | (x >> 13);
        xrotr22 = (x << 10) | (x >> 22);
        bsig0 = xrotr2 ^ xrotr13 ^ xrotr22;
    endfunction 
    
    function logic [data_width-1:0] bsig1 (
        logic [data_width-1:0] x);
        logic [data_width-1:0] xrotr6, xrotr11, xrotr25;
        xrotr6  = (x << 26) | (x >> 6);
        xrotr11 = (x << 21) | (x >> 11);
        xrotr25 = (x << 7) | (x >> 25);
        bsig1 = xrotr6 ^ xrotr11 ^ xrotr25;
    endfunction 
    
    function logic [data_width-1:0] ch (
        logic [data_width-1:0] x, y, z);
        ch = (x & y) ^ ((~x) & z);
    endfunction 
    
    function logic [data_width-1:0] maj (
        logic [data_width-1:0] x, y, z);
        maj = (x & y) ^ (x & z) ^ (y & z);
    endfunction 
    
    // // // SHA-2 Constants
    // logic [31:0] K [63:0];

    // assign K[0] = 32'h428a2f98; 
    // assign K[1] = 32'h71374491; 
    // assign K[2] = 32'hb5c0fbcf; 
    // assign K[3] = 32'he9b5dba5;
    // assign K[4] = 32'h3956c25b; 
    // assign K[5] = 32'h59f111f1; 
    // assign K[6] = 32'h923f82a4; 
    // assign K[7] = 32'hab1c5ed5;
    // assign K[8] = 32'hd807aa98; 
    // assign K[9] = 32'h12835b01; 
    // assign K[10] = 32'h243185be; 
    // assign K[11] = 32'h550c7dc3;
    // assign K[12] = 32'h72be5d74; 
    // assign K[13] = 32'h80deb1fe; 
    // assign K[14] = 32'h9bdc06a7; 
    // assign K[15] = 32'hc19bf174;
    // assign K[16] = 32'he49b69c1; 
    // assign K[17] = 32'hefbe4786; 
    // assign K[18] = 32'h0fc19dc6; 
    // assign K[19] = 32'h240ca1cc;
    // assign K[20] = 32'h2de92c6f; 
    // assign K[21] = 32'h4a7484aa; 
    // assign K[22] = 32'h5cb0a9dc; 
    // assign K[23] = 32'h76f988da;
    // assign K[24] = 32'h983e5152; 
    // assign K[25] = 32'ha831c66d; 
    // assign K[26] = 32'hb00327c8; 
    // assign K[27] = 32'hbf597fc7;
    // assign K[28] = 32'hc6e00bf3; 
    // assign K[29] = 32'hd5a79147; 
    // assign K[30] = 32'h06ca6351; 
    // assign K[31] = 32'h14292967;
    // assign K[32] = 32'h27b70a85; 
    // assign K[33] = 32'h2e1b2138; 
    // assign K[34] = 32'h4d2c6dfc; 
    // assign K[35] = 32'h53380d13;
    // assign K[36] = 32'h650a7354; 
    // assign K[37] = 32'h766a0abb; 
    // assign K[38] = 32'h81c2c92e; 
    // assign K[39] = 32'h92722c85;
    // assign K[40] = 32'ha2bfe8a1; 
    // assign K[41] = 32'ha81a664b; 
    // assign K[42] = 32'hc24b8b70; 
    // assign K[43] = 32'hc76c51a3;
    // assign K[44] = 32'hd192e819; 
    // assign K[45] = 32'hd6990624; 
    // assign K[46] = 32'hf40e3585; 
    // assign K[47] = 32'h106aa070;
    // assign K[48] = 32'h19a4c116; 
    // assign K[49] = 32'h1e376c08; 
    // assign K[50] = 32'h2748774c; 
    // assign K[51] = 32'h34b0bcb5;
    // assign K[52] = 32'h391c0cb3; 
    // assign K[53] = 32'h4ed8aa4a; 
    // assign K[54] = 32'h5b9cca4f; 
    // assign K[55] = 32'h682e6ff3;
    // assign K[56] = 32'h748f82ee; 
    // assign K[57] = 32'h78a5636f; 
    // assign K[58] = 32'h84c87814; 
    // assign K[59] = 32'h8cc70208;
    // assign K[60] = 32'h90befffa; 
    // assign K[61] = 32'ha4506ceb; 
    // assign K[62] = 32'hbef9a3f7; 
    // assign K[63] = 32'hc67178f2;

    // // H_init Constants
    // const logic [31:0] H0_init = 32'h6a09e667;
    // const logic [31:0] H1_init = 32'hbb67ae85;
    // const logic [31:0] H2_init = 32'h3c6ef372;
    // const logic [31:0] H3_init = 32'ha54ff53a;
    // const logic [31:0] H4_init = 32'h510e527f;
    // const logic [31:0] H5_init = 32'h9b05688c;
    // const logic [31:0] H6_init = 32'h1f83d9ab;
    // const logic [31:0] H7_init = 32'h5be0cd19;
endpackage