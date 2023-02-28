//-----------------------------------------------------------------------------
// SoC Labs Basic SHA-256 Engine function and constants SV Package
// A joint work commissioned on behalf of SoC Labs, under Arm Academic Access license.
//
// Contributors
//
// David Mapstone (d.a.mapstone@soton.ac.uk)
//
// Copyright  2022, SoC Labs (www.soclabs.org)
//-----------------------------------------------------------------------------

package sha256_hashing_functions;
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
endpackage