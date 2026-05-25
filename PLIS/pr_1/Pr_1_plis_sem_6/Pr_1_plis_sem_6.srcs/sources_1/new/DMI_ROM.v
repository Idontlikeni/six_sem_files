`timescale 1ns / 1ps

module DMI_ROM(
    input [6:0] ADDR,
    output [7:0] DATA
);
    
reg [7:0] ROM0 [127:0];
initial $readmemh("ROM_file.mem", ROM0);
assign DATA = ROM0[ADDR];
    
endmodule
