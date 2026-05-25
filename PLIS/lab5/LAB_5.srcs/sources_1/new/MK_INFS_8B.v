`timescale 1ns / 1ps

module MK_INFS_8B(
    // Target-0
    input T_S_EX_REQ,
    input [23:0] T_S_ADDR,
    input [2:0] T_S_CMD,
    input [7:0] T_S_D_WR,
    output T_S_EX_ACK,
    output [7:0] T_S_D_RD,
    // Initiator-0
    output I0_S_EX_REQ, // запрос
    output I0_S_ADDR, // адрес
    output [2:0] I0_S_CMD, // команда
    output [7:0] I0_S_D_WR, // данные для записи
    input I0_S_EX_ACK, // подтверждение
    input [7:0] I0_S_D_RD, // чтение
    // Initiator-1
    output I1_S_EX_REQ,
    output [5:0] I1_S_ADDR,
    output [2:0] I1_S_CMD,
    output [7:0] I1_S_D_WR,
    input I1_S_EX_ACK,
    input [7:0] I1_S_D_RD
);

reg [1:0] EN;

always @*
    // I/O Space
    if (T_S_CMD == 3'b000 | T_S_CMD == 3'b100) begin
        if (T_S_ADDR[23:1] == 23'b0011_1010_1100_0000_0111_011) begin
            EN <= 2'b01;
        end
        else begin
            EN <= 2'b00;
        end
    end
    // Mem Space
    else if (T_S_CMD == 3'b001 | T_S_CMD == 3'b101) begin
        if (T_S_ADDR[23:6] == 'b1101_1001_1100_0100_10) begin
            EN <= 2'b10;
        end
        else begin
            EN <= 2'b00;
        end
    end
    // No Resources
    else begin
        EN <= 2'b00;
    end
    
// Ix_S_EX_REQ
assign I0_S_EX_REQ = T_S_EX_REQ & EN[0];
assign I1_S_EX_REQ = T_S_EX_REQ & EN[1];

// T_S_EX_ACK
assign T_S_EX_ACK = (I0_S_EX_ACK | ~EN[0]) & (I1_S_EX_ACK | ~EN[1]);

// T_S_D_RD
assign T_S_D_RD = (I0_S_D_RD | ~{8{EN[0]}}) & (I1_S_D_RD | ~{8{EN[1]}});

// Initiator-0
assign I0_S_ADDR = T_S_ADDR[0];
assign I0_S_CMD = T_S_CMD;
assign I0_S_D_WR = T_S_D_WR;

// Initiator-1
assign I1_S_ADDR = T_S_ADDR[5:0];
assign I1_S_CMD = T_S_CMD;
assign I1_S_D_WR = T_S_D_WR;

endmodule