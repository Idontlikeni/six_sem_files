`timescale 1ns / 1ps


module MK_ROM(
    input [6:0] ADDR,
    output [7:0] DATA
    );
    
    reg [7:0] ROM0 [0:127];
    
    initial $readmemh("D:\Vivado\VivadoProjects3\MK_PLIS_PR1\MK_PLIS_PR1.srcs\sources_1\new\mem.mem", ROM0);
    
    assign DATA = ROM0[DATA];
    
endmodule
