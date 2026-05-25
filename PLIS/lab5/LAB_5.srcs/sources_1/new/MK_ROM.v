`timescale 1ns / 1ps

module MK_ROM(
    input [6:0] ADDR,
    output [7:0] DATA
);

reg [7:0] ROM0 [0:127];

initial $readmemh("mem.mem", ROM0);

assign DATA = ROM0[ADDR];
    
endmodule
