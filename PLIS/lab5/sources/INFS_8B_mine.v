`timescale 1ns / 1ps
module DMI_INFS_IVBO_11_23(
    // Target-0:
    input T_S_EX_REQ,
    input [39:0] T_S_ADDR,
    input [2:0] T_S_CMD,
    input [7:0] T_S_D_WR,
    
    output T_S_EX_ACK,
    output [7:0] T_S_D_RD,
    // Initiator-0:
    output I0_S_EX_REQ,
    output I0_S_ADDR,
    output [2:0] I0_S_CMD,
    output [7:0] I0_S_D_WR,
    
    input I0_S_EX_ACK,
    input [7:0] I0_S_D_RD,
    //Initiator-1:
    output I1_S_EX_REQ,
    output [4:0] I1_S_ADDR,
    output [2:0] I1_S_CMD,
    output [7:0] I1_S_D_WR,
    
    input I1_S_EX_ACK,
    input [7:0] I1_S_D_RD
);
reg [1:0] EN;

always@*
    // I/O space
    if(T_S_CMD == 3'b000 | T_S_CMD == 3'b100) begin
        //Address range: C229A4h - C229A5h => 2 B CHANGE
        if(T_S_ADDR[39:1] == 39'b0001_0111_1011_1110_0000_0010_0001_1101_0000_111)begin
            EN <= 2'b01;
        end else EN <= 2'b00;
    end
    // Memory space
    else if(T_S_CMD == 3'b001 | T_S_CMD == 3'b101)begin
        // Address range: F5BAD0h - F5BADFh => 4b CHANGE
        if(T_S_ADDR[39:5] == 35'b1101_1001_1110_1011_1110_1111_1110_1011_011)begin
            EN <= 2'b10;
        end else EN <= 2'b00;
    end
    // No resources
    else begin
        EN <= 2'b00;
    end

// Ix_S_EX_REQ
assign I0_S_EX_REQ = T_S_EX_REQ & EN[0];
assign I1_S_EX_REQ = T_S_EX_REQ & EN[1];
// T_S_EX_ACK
assign T_S_EX_ACK = (I0_S_EX_ACK | ~EN[0]) & (I1_S_EX_ACK | ~EN[1]);
assign T_S_D_RD = (I0_S_D_RD | ~{8{EN[0]}}) & (I1_S_D_RD | ~{8{EN[1]}});

//initiator 0
assign I0_S_ADDR = T_S_ADDR[0];
assign I0_S_CMD = T_S_CMD;
assign I0_S_D_WR = T_S_D_WR;
//initiator 1
assign I1_S_ADDR = T_S_ADDR[4:0];
assign I1_S_CMD = T_S_CMD;
assign I1_S_D_WR = T_S_D_WR;

endmodule
